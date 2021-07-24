package Localmark::Site;

use strict;
use warnings;

use Moose;

use Text::Markdown qw( markdown );

use namespace::autoclean;

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


sub description_as_markdown {
    my $self = shift;

    if (defined $self->description) {
        return markdown($self->description);
    }

    return '';
}

no Moose;
__PACKAGE__->meta->make_immutable;
