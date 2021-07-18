#!/bin/env perl
# importa un unico recurso
use utf8;
use strict;
use warnings;
use v5.32;

use Cwd qw(abs_path);

use Localmark::Storage::Localmark;

my ($package, $pagepath, $site, $uri) = @ARGV;

my $storage_directory = $ENV{'STORAGE_DIRECTORY'}
|| die 'requires environment STORAGE_DIRECTORY';

die "need package" if not defined $package;
die "need pagepath" if not defined $pagepath;
die "need site" if not defined $site;
 
my $storage = Localmark::Storage::Localmark->new( path => $storage_directory );

$storage->import_page(
    $pagepath,
    site => $site,
    package => $package,
    uri => $uri
    );
                       
