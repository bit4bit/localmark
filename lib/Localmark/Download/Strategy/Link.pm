package Localmark::Download::Strategy::Link;

=head DESCRIPTION

descarga una sola pagina

=cut

use strict;
use warnings;
use Carp;
use File::Temp qw( mkdtemp );

use Moose;

extends 'Localmark::Download::Strategy::Base';

sub execute {
    my ($self, $url, %args) = @_;

    my $dirwebsite = mkdtemp( '/tmp/download-link-XXXX' );
    my $empty_page = File::Spec->catfile( $dirwebsite, 'index.html' );
    open( my $fh, '>', $empty_page ) or croak "couldn't open file: $!";
    print $fh qq{<!DOCTYPE><html><head><meta http-equiv="refresh" content="1; url = $url"/></head><body><h1>localmark link to $url</h1></body></html> };
    close( $fh );

    $args{site} = $url;
    $self->download->import_site($url, $dirwebsite, [$empty_page], %args);
}

no Moose;
__PACKAGE__->meta->make_immutable;
