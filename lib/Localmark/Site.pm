package Localmark::Site;

use strict;
use warnings;

use Moose;

has 'name' => (is => 'ro');

has 'title' => (is => 'ro');

has 'package' => (is => 'ro');

# path principal /indexh.tml
has 'root' => (is => 'ro');

no Moose;
__PACKAGE__->meta->make_immutable;
