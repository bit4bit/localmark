package Localmark::Util::MIME::Type;

use utf8;
use strict;
use warnings;

use Localmark::Constant;

use LWP::Simple qw( head );
use LWP::UserAgent ();
use Data::Dumper;
use File::Basename;
use Carp;
use namespace::autoclean;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( mime_type_from_path mime_type_from_url is_mime_type_readable );

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
    '.ico' => 'image/vnd.microsoft.icon',
    '.php' => 'application/x-httpd-php'
    );

my %mime_readable = (
    'text/xml' => 1,
    'application/xhtml+xml' => 1,
    'image/svg+xml' => 1,
    'text/javascript' => 1,
    'application/json' => 1,
    'text/html'  => 1,
    'text/plain' => 1,
    'text/csv' => 1,
    'text/css' => 1,
    'application/x-httpd-php'  => 1
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

    my $ua = LWP::UserAgent->new(timeout => 10);
    $ua->agent(Localmark::Constant::WebAgent);
    my $response = $ua->head($url);
    my $content_type = $response->header('content-type');

    if ($content_type) {
        $content_type =~ s/;.+//;
        return $content_type;
    }

    return;
}

sub is_mime_type_readable {
    my ($type) = @_;

    return 1 if (defined $mime_readable{$type});
    return 0
}

1;
