package Localmark::Quote;

=head DESCRIPTION

Fragmento de texto encontrado

=cut

use strict;
use warnings;

use Moose;
use namespace::autoclean;

has 'title' => (
    is => 'ro',
    isa => 'Str'
    );

has 'url' => (
    is => 'ro',
    isa => 'Str'
    );

has 'content' => (
    is => 'ro',
    isa => 'Str'
    );

has 'resource_id' => (
    is => 'ro',
    isa => 'Str'
    );

no Moose;
__PACKAGE__->meta->make_immutable;
