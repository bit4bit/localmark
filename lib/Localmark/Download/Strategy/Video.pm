package Localmark::Download::Strategy::Video;

=head DESCRIPTION

codigo fuente

=cut

use strict;
use warnings;
use Carp;

use Moose;

extends 'Localmark::Download::Strategy::Base';

sub execute {
    my ($self, $url, %args) = @_;

    my $package = $args{package} || croak "requires 'package'";
    my $description = $args{description} || '';
    my $title = $args{title};

    $self->download->video(
        $url,
        package => $package,
        site => $url,
        site_description => $description,
        site_title => $title
        );
}

no Moose;
__PACKAGE__->meta->make_immutable;
