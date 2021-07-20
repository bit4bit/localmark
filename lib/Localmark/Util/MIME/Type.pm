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
    '.gif' => 'image/gif',
    '.jpeg' => 'image/jpeg',
    '.jpg' => 'image/jpg',
    '.png' => 'image/png',
    '.css' => 'text/css',
    '.js' => 'text/javascript',
    ".json" => "application/json",
    '.xml' => 'text/xml',
    '.html' => 'text/html',
    '.html' => 'text/html',
    '.txt' => 'text/plain',
    '.csv' => 'text/plain',
    '.epub' => 'application/epub+zip',
    '.pdf' => 'application/pdf',
    '.svg' => 'image/svg+xml',
    '.ttf' => 'font/ttf',
    '.woff' => 'font/woff',
    '.woff2' => 'font/woff2',
    '.xhtml' => 'application/xhtml+xml',
    '.eot' => 'application/vnd.ms-fontobject',
    '.ico' => 'image/vnd.microsoft.icon'
    );

sub mime_type_from_path {
    my ($filename, $default) = @_;

    my ($name, $path, $suffix) = fileparse( $filename, keys %mime );

    my $type = $mime{$suffix};

    return $type if $type;
    return $default if $default;
    
    croak "can't find mime type $suffix for $filename";
}

1;
