package Localmark::Download;

=head DESCRIPTION

Descarga y empaqueta sitio web.

=cut

use utf8;
use strict;
use warnings;
use feature 'switch';

use Carp;
use Localmark::Util::File::Slurp qw( read_text );
use Localmark::Util::MIME::Type qw(mime_type_from_path mime_type_from_url);
use URI ();

use Moose;
use namespace::autoclean;

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

    given ($strategy) {
        when ( 'single_page' ) {
            my $site = $url;

            $self->single_page(
                $url,
                package => $package,
                site => $site
                );
        }
        when ( 'single_website' ) {
            my $site = $url;
            
            $self->single_website(
                $url,
                package => $package,
                site => $url
                );
        }
        default {
            croak "unknown strategy";
        }
    }
    
}

# descargar una unica pagina
sub single_page {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    
    my ($directory, @files) = $self->downloader->single_page($url);
    my $site_title = $self->guess_site_title($url, $directory, @files) || $site;
    my $site_root = $self->guess_site_root($url, $directory, @files) || '/index.html';
    my $site_url = $url;

    my $main_uri = URI->new($url);
    my $base_url = $main_uri->scheme . '://' . $main_uri->host_port;
    
    for my $file (@files) {
        my $filename = $file =~ s/^$directory//r;
        my $file_url = $file =~ s/^$directory/$base_url/r;
            
        # intentamos sanear las rutas con /mi.svg?data=1
        my $uri = URI->new("http://localhost$filename")->path;

        # cual seria el mime type de sitios sin index.html
        # ejemplo: https://metacpan.org/pod/Moose
        my $mime_type = guess_mime_type( $file, $file_url );
        
        $self->storage->import_page(
            $file,
            package => $package,
            site => $site,
            site_title => $site_title,
            site_root => $site_root,
            site_url => $site_url,
            uri => $uri,
            mime_type => $mime_type
            );
    }
}

sub single_website {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    
    my ($directory, @files) = $self->downloader->single_website($url);

    my $site_title = $self->guess_site_title($url, $directory, @files);
    my $site_root = $self->guess_site_root($url, $directory, @files) || '/index.html';
    my $main_uri = URI->new($url);
    my $base_url = $main_uri->scheme . '://' . $main_uri->host_port;
    
    for my $file (@files) {
        my $uri = $file =~ s/^$directory//r;
        my $file_url = $file =~ s/^$directory/$base_url/r;

        my $mime_type = guess_mime_type( $file, $file_url );
        
        $self->storage->import_page(
            $file,
            package => $package,
            site => $site,
            site_title => $site_title,
            site_root => $site_root,
            uri => $uri,
            mime_type => $mime_type
            );
    }
}

sub guess_site_title {
    my ($self, $url, %args) = @_;

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

    my $uri = URI->new($url);
    return $uri->path;
}

sub guess_mime_type {
    my ($path, $file_url) = @_;

    mime_type_from_path($path) || mime_type_from_url($file_url) || croak "could't detect mime type for $path or $file_url";
}

no Moose;
__PACKAGE__->meta->make_immutable;
