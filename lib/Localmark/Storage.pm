package Localmark::Storage;

use strict;
use warnings;

use Localmark::Resource;
use Localmark::Exception;

use Moose;

has 'storage' => (
    is => 'rw',
    required => 1
    );

sub resource {
    my ($self, %args) = @_;

    die "argument 'path'" if not defined $args{path};
    die "argument 'package'" if not defined $args{package};
    die "argument 'path'" if not defined $args{path};

    my $resource = $self->storage->resource(
        package => $args{package},
        site => $args{site},
        path => $args{path}
        );
    
    return $resource;
}
1;
