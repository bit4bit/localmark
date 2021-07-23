package Localmark::Storage;

use strict;
use warnings;
use v5.16;

use Carp;
use File::Glob ':bsd_glob';
use File::Spec;
use File::Basename qw(basename);
use Data::Dumper;

use Localmark::Resource;
use Localmark::Exception;

use Moose;

has 'storage' => (
    is => 'rw',
    required => 1
    );

sub delete {
    my ($self, $package, $name) = @_;

    $self->storage->delete_site($package, $name);
}

sub site {
    my ($self, $package, $name) = @_;

    $self->storage->site($package, $name);
}

# returns %{ 'package name' => Localmark::Site }
sub sites {
    my ($self, %opts) = @_;

    my $directory_packages = $self->storage->path;

    my $package_glob = $opts{filter}->{package} || '*';
    my @package_fullpaths = bsd_glob( "$directory_packages/$package_glob.localmark"  );

    my %site_of;
    for my $package_path (@package_fullpaths) {
        my $package = basename( $package_path ) =~ s/(.+)\..+/$1/r;

        my $sites = $self->storage->sites(
            $package,
            filter => {
                content => $opts{filter}->{content}
            });

        for my $site ( @{ $sites }) {
            push @{ $site_of{$package} }, $site;
        }
    }

    return %site_of;
}

sub import_page {
    my ($self, @args) = @_;

    $self->storage->import_page(@args);
}

sub resource {
    my ($self, %args) = @_;

    croak "argument 'path'" if not defined $args{path};
    croak "argument 'package'" if not defined $args{package};
    croak "argument 'path'" if not defined $args{path};

    my $resource = $self->storage->resource(
        package => $args{package},
        site => $args{site},
        path => $args{path}
        );
    
    return $resource;
}
1;
