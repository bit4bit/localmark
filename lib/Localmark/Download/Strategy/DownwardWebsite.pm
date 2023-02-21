package Localmark::Download::Strategy::DownwardWebsite;

=head DESCRIPTION

descarga una sola pagina

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

    $self->download->single_website(
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
