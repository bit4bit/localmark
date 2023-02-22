package Localmark::Download::Strategy::MirrorWebsite;

=head DESCRIPTION

espejo del sitio

=cut

use strict;
use warnings;
use Carp;

use Moose;

extends 'Localmark::Download::Strategy::Base';
with 'Localmark::Download::Strategy::Websiteable';

sub execute {
    my ($self, $url, %args) = @_;

    my ($directory, @files) = $self->mirror_website( $url );
    $self->download->import_site($url, $directory, \@files, %args);
}

no Moose;
__PACKAGE__->meta->make_immutable;
