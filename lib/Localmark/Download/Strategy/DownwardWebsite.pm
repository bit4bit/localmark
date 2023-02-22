package Localmark::Download::Strategy::DownwardWebsite;

=head DESCRIPTION

descarga una sola pagina

=cut

use strict;
use warnings;
use Carp;

use Moose;

extends 'Localmark::Download::Strategy::Base';
with 'Localmark::Download::Strategy::Websiteable';

sub execute {
    my ($self, $url, %args) = @_;

    my $filter_files = $args{filter}->{files} || '';
    my ($directory, @files) = $self->single_website(
        $url,
        allow_parent => $args{allow_parent} || 0,
        filter => $filter_files);

    $self->download->import_site($url, $directory, \@files, %args);
}

no Moose;
__PACKAGE__->meta->make_immutable;
