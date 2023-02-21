package Localmark::Download::State;

=head DESCRIPTION

Estado de la descarga en curso

=cut

use strict;
use utf8;
use warnings;

use Moose;

has 'name' => (
    is => 'ro',
    required => 1
    );

has 'state' => (
    is => 'rw',
    required => 1
    );

no Moose;
__PACKAGE__->meta->make_immutable;
