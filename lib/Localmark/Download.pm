package Localmark::Download;

=head DESCRIPTION

Descarga y empaqueta sitio web.

=cut

use utf8;
use strict;
use warnings;
use feature 'switch';

use File::Temp qw( mkdtemp mktemp );
use File::Copy qw( move );
use File::Spec;
use Carp;
use URI ();
use Data::Dumper;
use List::Util qw(first);

use Moose;
use namespace::autoclean;

use Localmark::Util::File::Slurp qw( read_text );
use Localmark::Util::MIME::Type qw(mime_type_from_path mime_type_from_url);



has 'storage' => (
    is => 'ro',
    required => 1
    );

has 'downloader' => (
    is => 'ro',
    required => 1
    );

sub output {
    my $self = shift;

    $self->downloader->output;
}

sub using_strategy {
    my ($self, $strategy, $url, %args) = @_;

    my $package = $args{package} || croak "requires 'package'";
    my $description = $args{description} || '';
    my $title = $args{title};

    given ($strategy) {
        when ( 'single_page' ) {
            my $site = $url;

            $self->single_page(
                $url,
                package => $package,
                site => $site,
                site_description => $description,
                site_title => $title
                );
        }
        when ( 'link' ) {
            $self->link(
                $url,
                package => $package,
                site => $url,
                site_description => $description,
                site_title => $title
                );
        }
        when ( 'downward_website' ) {
            my $site = $url;

            $self->single_website(
                $url,
                package => $package,
                site => $url,
                site_descriptio => $description,
                site_title => $title,
                filter => $args{filter}
                );
        }
        when ( 'upward_website' ) {
            my $site = $url;

            $self->single_website(
                $url,
                package => $package,
                site => $url,
                site_description => $description,
                site_title => $title,
                allow_parent => 1,
                filter => $args{filter}
                );
        }
        when ( 'mirror_website' ) {
            my $site = $url;

            $self->mirror_website(
                $url,
                package => $package,
                site => $url,
                site_description => $description,
                site_title => $title
                );
        }
        when( 'code' ) {
            my $site = $url;

            $self->code(
                $url,
                package => $package,
                site => $url,
                site_description => $description,
                site_title => $title,
                filter => $args{filter}
                );
        }
        when( 'video' ) {
            $self->video(
                $url,
                package => $package,
                site => $url,
                site_description => $description,
                site_title => $title
                );
        }
        default {
            croak "unknown strategy";
        }
    }

}

sub video {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";

    my $site_description = $args{site_description} || '';
    my $site_title =  $args{site_title} || $self->guess_site_title($url) || $site;

    my $directory_for_download = mkdtemp( '/tmp/download-video-XXXX' );
    my ($directory, @files) = $self->downloader->video($url);

    my $index_file = first { defined($_) } @files;
    my $index = File::Basename::basename($index_file);

    $self->storage->import_files(
        $directory, \@files,
        package => $package,
        site => $site,
        site_title => $site_title,
        site_root => "/" . $index,
        site_description => $site_description,
        site_url => $url
        );
}

sub link {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = $self->guess_site_root($url) || '/index.html';

    my $dirwebsite = mkdtemp( '/tmp/download-link-XXXX' );
    my $empty_page = File::Spec->catfile( $dirwebsite, 'index.html' );
    open( my $fh, '>', $empty_page ) or croak "couldn't open file: $!";
    print $fh qq{<!DOCTYPE><html><head><meta http-equiv="refresh" content="1; url = $url"/></head><body><h1>localmark link to $url</h1></body></html> };
    close( $fh );

    $self->storage->import_files(
        $dirwebsite, [$empty_page],
        package => $package,
        site => $site,
        site_title => $site_title,
        site_root => '/index.html',
        site_description => $site_description,
        site_url => $url
        );
};

# descargar una unica pagina
sub single_page {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    my ($directory, @files) = $self->downloader->single_page($url);
    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = $self->guess_site_root($url) || '/index.html';

    $self->storage->import_files(
        $directory, \@files,
        package => $package,
        site => $site,
        site_title => $site_title,
        site_root => $site_root,
        site_description => $site_description,
        site_url => $url
        );
}

sub single_website {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";

    my $filter_files = $args{filter}->{files} || '';
    my ($directory, @files) = $self->downloader->single_website(
        $url,
        allow_parent => $args{allow_parent} || 0,
        filter => $filter_files);

    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = $self->guess_site_root($url) || '/index.html';

    $self->storage->import_files(
        $directory, \@files,
        package => $package,
        site => $site,
        site_title => $site_title,
        site_root => $site_root,
        site_description => $site_description,
        site_url => $url
        );
}

sub mirror_website {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";

    my ($directory, @files) = $self->downloader->mirror_website( $url );

    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = $self->guess_site_root($url) || '/index.html';

    $self->storage->import_files(
        $directory, \@files,
        package => $package,
        site => $site,
        site_title => $site_title,
        site_root => $site_root,
        site_description => $site_description,
        site_url => $url
        );
}

sub code {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";

    my $filter_files = $args{filter}->{files} || '';
    my ($directory, @files) = $self->downloader->code($url, filter => $filter_files);

    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = '/index.html';


    $self->storage->import_files(
        $directory, \@files,
        package => $package,
        site => $site,
        site_title => $site_title,
        site_root => $site_root,
        site_description => $site_description,
        site_url => $url
        );
}
sub guess_site_title {
    my ($self, $url) = @_;

    my $html = $self->downloader->get($url);

    if ($html =~ m{<title>([^<]+)}) {
        my $title = $1;
        $title =~ s/^ *//;
        $title =~ s/ *//;
        chomp $title;
        return $title;
    }

    return;
};

sub guess_site_root {
    my ($self, $url, %args) = @_;

    my $mime_type = $args{mime_type} || mime_type_from_url($url);
    my $path = URI->new($url)->path;
    my $rest = $url =~ s/.+$path//r || '';

    # al activar la opcion -E de wget
    # este adiciona el sufijo a los archivo
    # segun el contenido, se asume esta idea
    # como parte de la funcionalidad
    # asumimos que todo recurso tiene una extension
    if (defined $mime_type && $mime_type eq 'text/html') {
        if ($path =~ m{/$}) {
            $path .= 'index.html';
        }
        elsif ($path !~ m{\.[hH][tT][mM][lL]?(\?.+)?$}) {
            $path .= '.html';
        }

    }

    return $path . $rest;
}

no Moose;
__PACKAGE__->meta->make_immutable;
