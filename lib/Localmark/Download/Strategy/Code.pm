package Localmark::Download::Strategy::Code;

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

    $self->download->code(
        $url,
        package => $package,
        site => $url,
        site_description => $description,
        site_title => $title,
        filter => $args{filter}
        );
}

no Moose;
__PACKAGE__->meta->make_immutable;
