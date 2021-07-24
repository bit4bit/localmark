package Localmark::Site;

use strict;
use warnings;

use Moose;

has 'id' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        return $self->package . '.' . $self->name;
    }
    );

has 'name' => (
    is => 'ro',
    isa => 'Str'
    );

has 'title' => (
    is => 'ro',
    isa => 'Str'
    );

has 'package' => (
    is => 'ro',
    isa => 'Str'
    );

has 'url' => (
    is => 'ro',
    isa => 'Str'
    );

# path principal /indexh.tml
has 'root' => (
    is => 'ro',
    isa => 'Str'
    );

has 'description' => (
    is => 'ro',
    isa => 'Maybe[Str]',
);

has 'quotes' => (
    is => 'ro',
    isa => 'ArrayRef[Localmark::Quote]'
    );

no Moose;
__PACKAGE__->meta->make_immutable;
