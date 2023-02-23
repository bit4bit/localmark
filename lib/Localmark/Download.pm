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

use Localmark::Download::Manager;
use Localmark::Download::StrategyFactory;

use Moose;
use namespace::autoclean;

use Localmark::Util::MIME::Type qw(mime_type_from_path mime_type_from_url);


has 'download_debug' => (
    is => 'rw',
    isa => 'Str',
    default => sub { '' }
    );

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

    $self->download_debug;
}

sub strategies {
    my $self = shift;

    $self->strategy_factory->selectors();
}

sub using_strategy {
    my ($self, $strategy, $url, %args) = @_;

    my $download_state = $self->manager->new_download($url);
    $download_state->start_download();
    $self->strategy_factory
        ->of(strategy => $strategy,
             download => $self,
             download_state => $download_state)
        ->execute($url, %args);
    $download_state->stop_download();
}

sub import_site {
    my ($self, $url, $directory, $files, %args) = @_;

    my $package = $args{package} or croak "requires 'package'";
    my $site = $args{site} or croak "requires 'site'";
    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $self->guess_site_title($url) || $site;
    my $site_root = $args{site_root} || $self->guess_site_root($url) || '/index.html';

    $self->storage->import_files(
        $directory, $files,
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
