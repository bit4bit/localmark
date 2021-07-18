package Localmark::Util::MIME::Type;

use utf8;
use strict;
use warnings;

use File::Basename;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(mime_type_from_path);

my %mime = (
    '.jpg' => 'image/jpg',
    '.png' => 'image/png',
    '.css' => 'text/css',
    '.js' => 'text/javascript',
    '.xml' => 'text/xml',
    '.html' => 'text/html'
    );

sub mime_type_from_path {
    my $filename = shift;

    my ($name, $path, $suffix) = fileparse( $filename, keys %mime );

    my $type = $mime{$suffix};

    return $type if $type;
        
    croak "can't find mime type $suffix for $filename";
}

1;
