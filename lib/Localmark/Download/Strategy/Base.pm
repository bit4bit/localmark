package Localmark::Download::Strategy::Base;

=head DESCRIPTION

comportamiento general de descarga

=cut

use strict;
use warnings;
use feature 'switch';

use Carp;

use Moose;

has 'strategy' => (
    is => 'ro',
    required => 1
    );

has 'download' => (
    is => 'ro'
    );

has 'downloader' => (
    is => 'ro'
    );

sub execute {
    my ($self, $url, %args) = @_;

    croak 'not implemented';
}

no Moose;
__PACKAGE__->meta->make_immutable;
