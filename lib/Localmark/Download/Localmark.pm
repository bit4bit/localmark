package Localmark::Download::Localmark;

=head DESCRIPTION

Descargar sitios usando comando *wget*.

=cut

use utf8;
use strict;
use warnings;

use URI;
use File::Temp qw( mkdtemp mktemp );
use File::Spec;
use File::Find qw(find);
use File::Copy qw( move );
use Data::Dumper;
use Carp;

use Moose;
use namespace::autoclean;

use Localmark::Util::File::Slurp qw(read_text);
use Localmark::Constant;
use Localmark::SourceCode ();

# obtiene una pagina
sub get {
    my ($self, $url) = @_;

    #https://perlmaven.com/simple-way-to-fetch-many-web-pages
    my $html = qx{wget --quiet --output-document=- $url};
    return $html;
}

no Moose;
__PACKAGE__->meta->make_immutable;
