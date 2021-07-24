package Localmark::Download;

=head DESCRIPTION

Descarga y empaqueta sitio web.

=cut

use utf8;
use strict;
use warnings;
use feature 'switch';

use Carp;
use URI ();
use Data::Dumper;

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
        when ( 'downward_website' ) {
            my $site = $url;
            
            $self->single_website(
                $url,
                package => $package,
                site => $url,
                site_descriptio => $description,
                site_title => $title
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
                allow_parent => 1
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
    my $site_description = $args{site_description} || '';
    
    my ($directory, @files) = $self->downloader->single_page($url);
    my $site_title = $args{site_title} || $self->guess_site_title($url, $directory, @files) || $site;
    my $site_root = $self->guess_site_root($url, $directory, @files) || '/index.html';
    my $site_url = $url;

    my $main_uri = URI->new($url);
    my $base_url = $main_uri->scheme . '://' . $main_uri->host_port;
    
    for my $file (@files) {
        # se almacena talcual ya que wget
        # espera la misma ruta exacta
        my $uri = $file =~ s/^$directory//r;
        my $file_url = $file =~ s/^$directory/$base_url/r;
            
        # cual seria el mime type de sitios sin index.html
        # ejemplo: https://metacpan.org/pod/Moose
        my $mime_type = guess_mime_type( $file, $file_url );
        if (not $mime_type) {
            carp "OMIT: could't detect mime type for $file or $file_url";
            next;
        }
        
        $self->storage->import_page(
            $file,
            package => $package,
            site => $site,
            site_title => $site_title,
            site_root => $site_root,
            site_url => $site_url,
            site_description => $site_description,
            uri => $uri,
            mime_type => $mime_type
            );
    }
}

sub single_website {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    my $site_description = $args{site_description} || '';
    
    my ($directory, @files) = $self->downloader->single_website($url,  allow_parent => $args{allow_parent} || 0 );

    my $site_title = $args{site_title} || $self->guess_site_title($url, $directory, @files) || $site;
    my $site_root = $self->guess_site_root($url, $directory, @files) || '/index.html';
    my $site_url = $url;

    my $main_uri = URI->new($url);
    my $base_url = $main_uri->scheme . '://' . $main_uri->host_port;
    
    for my $file (@files) {
        my $uri = $file =~ s/^$directory//r;
        my $file_url = $file =~ s/^$directory/$base_url/r;

        my $mime_type = guess_mime_type( $file, $file_url );
        if (not $mime_type) {
            carp "OMIT: could't detect mime type for $file or $file_url";
            next;
        }

        $self->storage->import_page(
            $file,
            package => $package,
            site => $site,
            site_title => $site_title,
            site_root => $site_root,
            site_url => $site_url,
            site_description => $site_description,
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

    my $mime_type = $args{mime_type} || guess_mime_type('none', $url);
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

sub guess_mime_type {
    my ($path, $file_url) = @_;

    mime_type_from_path($path) || mime_type_from_url($file_url);
}

no Moose;
__PACKAGE__->meta->make_immutable;
