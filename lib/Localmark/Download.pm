package Localmark::Download;

use utf8;
use strict;
use warnings;

use Carp;

use Localmark::Util::File::Slurp qw( read_text );
use Localmark::Util::MIME::Type qw(mime_type_from_path);

use Moose;

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

# descargar una unica pagina
sub single_page {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    
    my ($directory, @files) = $self->downloader->single_page($url);

    for my $file (@files) {
        my $uri = $file =~ s/^$directory//r;
        my $mime_type = mime_type_from_path($file);

        $self->storage->import_page(
            $file,
            package => $package,
            site => $site,
            uri => $uri,
            mime_type => $mime_type
            );
    }

    # TODO(bit4bit) intentamos obtener el titulo del sitio
    if ( my ($file) = grep { /index.html$/ } @files ) {
        my $text = read_text( $file );
        my $uri = $file =~ s/^$directory//r;
        my $mime_type = mime_type_from_path($file);

        if ($text =~ m{<title>([^<]+)}) {
            my $title = $1;
            $title =~ s/^ *//;
            $title =~ s/ *//;
            chomp $title;

            $self->storage->import_page(
                $file,
                package => $package,
                site => $site,
                site_title => $title,
                uri => $uri,
                mime_type => $mime_type
                );
        }
    }
}

sub single_website {
    my ($self, $url, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    
    my ($directory, @files) = $self->downloader->single_website($url);
    
    for my $file (@files) {
        my $uri = $file =~ s/^$directory//r;
        my $mime_type = mime_type_from_path($file);
        
        $self->storage->import_page(
            $file,
            package => $package,
            site => $site,
            uri => $uri,
            mime_type => $mime_type
            );
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
