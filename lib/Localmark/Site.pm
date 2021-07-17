package Localmark::Site;

use strict;
use warnings;

use Moose;

has 'name' => (is => 'rw');

has 'title' => (is => 'rw');

no Moose;
__PACKAGE__->meta->make_immutable;
