package Localmark::Site;

use strict;
use warnings;

use Moose;

has 'name' => (is => 'ro');

has 'title' => (is => 'ro');

has 'package' => (is => 'ro');


no Moose;
__PACKAGE__->meta->make_immutable;
