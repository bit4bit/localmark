package Localmark::Quote;

=head DESCRIPTION

Fragmento de texto encontrado

=cut

use strict;
use warnings;

use Moose;
use namespace::autoclean;

has 'title' => (is => 'ro');
has 'url' => (is => 'ro');
has 'content' => (is => 'ro');
has 'resource_id' => (is => 'ro');

no Moose;
__PACKAGE__->meta->make_immutable;
