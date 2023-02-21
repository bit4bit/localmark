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

use Localmark::Download::Manager;
use Localmark::Download::StrategyFactory;

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
    isa => 'Localmark::Download::Localmark',
    required => 1
    );

has 'manager' => (
    is => 'ro',
    isa => 'Localmark::Download::Manager',
    default => sub {
        Localmark::Download::Manager->new();
    }
    );

has 'strategy_factory' => (
    is => 'ro',
    default => sub {
        Localmark::Download::StrategyFactory->new();
    }
    );

sub downloads {
    my $self = shift;

    return @{$self->manager->downloads()};
}

sub output {
    my $self = shift;

    $self->downloader->output;
}

sub strategies {
    # TODO: mover a strategyFactory
    [
     {'name' => 'single_page', 'title' => 'Single Page'},
     {'name' => 'link', 'title' => 'Link'},
     {'name' => 'downward_website', 'title' => 'Downward Website'},
     {'name' => 'upward_website', 'title' => 'Upward Website'},
     {'name' => 'mirror_website', 'title' => 'Mirror Website'},
     {'name' => 'code', 'title' => 'Code'},
     {'name' => 'video', 'title' => 'Video'},
     {'name' => 'ipfs_site', 'title' => 'IPFS Site'}
    ]
}

sub using_strategy {
    my ($self, $strategy, $url, %args) = @_;

    my $package = $args{package} || croak "requires 'package'";
    my $description = $args{description} || '';
    my $title = $args{title};

    $self->manager->start_download($url);
    $self->strategy_factory
        ->of($strategy, $self, $self->downloader)
        ->execute($url, %args);
    $self->manager->stop_download($url);
}

sub video {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    my $site_description = $args{site_description} || '';
    my $site_title =  $args{site_title} || $self->guess_site_title($url) || $site;

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

sub ipfs_site {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    my $site_description = $args{site_description} || '';
    my $site_title =  $args{site_title} || $self->guess_site_title($url) || $site;

    my ($directory, @files) = $self->downloader->ipget($url);
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
    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = $self->guess_site_root($url) || '/index.html';

    my ($directory, @files) = $self->downloader->single_page($url);

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
    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = $self->guess_site_root($url) || '/index.html';

    my $filter_files = $args{filter}->{files} || '';
    my ($directory, @files) = $self->downloader->single_website(
        $url,
        allow_parent => $args{allow_parent} || 0,
        filter => $filter_files);

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
    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = $self->guess_site_root($url) || '/index.html';

    my ($directory, @files) = $self->downloader->mirror_website( $url );

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
    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = '/index.html';

    my $filter_files = $args{filter}->{files} || '';
    my ($directory, @files) = $self->downloader->code($url, filter => $filter_files);

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

    # hack libgen.rs
    my $uri = URI->new($url);
    my %query = $uri->query_form;
    my $libgen_filename = $query{'filename'};
    if (defined $libgen_filename) {
        return $libgen_filename;
    }

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
