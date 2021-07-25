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
use Localmark::Util::MIME::Type qw ( mime_type_from_path mime_type_from_url );
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
    croak "argument 'site'" if not defined $args{site};
    
    my $resource = $self->storage->resource(
        package => $args{package},
        site => $args{site},
        path => $args{path}
        );
    
    return $resource;
}

sub resources {
    my ($self, $package, $name) = @_;

    croak "argument 'package'" if not defined $package;
    croak "argument 'name'" if not defined $name;

    my @resources = $self->storage->resources(
        package => $package,
        site => $name
        );

    return @resources;
}


sub import_files {
    my ($self, $directory, $files, %args) = @_;

    $self->storage->import_files($directory, $files, %args);
}

sub insert_comment {
    my ($self, $package, $resource_id, $comment) = @_;

    croak "argument 'package'" if not defined $package;
    croak "argument 'resource_id'" if not defined $resource_id;
    croak "argument 'comment'" if not defined $comment;

    $self->storage->insert_comment($package, $resource_id, $comment);
}
1;
