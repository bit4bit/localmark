package Localmark::Util::MIME::Type;

use utf8;
use strict;
use warnings;


use LWP::Simple qw( head );

use File::Basename;
use Carp;
use namespace::autoclean;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( mime_type_from_path mime_type_from_url );

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
    return;
}

sub mime_type_from_url {
    my ($url, $default) = @_;

    my ($content_type) = head($url);

    if ($content_type) {
        $content_type =~ s/;.+//;
        return $content_type;
    }

    return;
}
1;
