#!/bin/env perl

use utf8;
use strict;
use warnings;
use v5.32;

use File::Find qw(find);
use File::Spec;
use Cwd qw(abs_path);

use Localmark::Util::File::Slurp qw(read_binary);
use Localmark::Util::MIME::Type qw(mime_type_from_path);
use Localmark::Storage::Localmark;

my ($package, $website) = @ARGV;

my $storage_directory = $ENV{'STORAGE_DIRECTORY'}
|| die 'requires environment STORAGE_DIRECTORY';

usage("requires 'package'") if not $package;
usage("requires website to be a directory") if ! -d $website;


my $storage = Localmark::Storage::Localmark->new( path => abs_path($storage_directory) );

find(\&wanted, $website);
sub wanted {
    my $filename = $File::Find::name;
    my $fullpath = $filename;

    # omitimos directorio raiz
    return if File::Spec->canonpath($filename) eq File::Spec->canonpath($website);

    $filename =~ s/$website\/?//;

    # omitimos directorio si el nombre no es un dominio
    return if $filename !~ /^(.+\..+\..+)/;
    return if !-f $fullpath;

    my ($site, $uri) = split /\//, $filename, 2;
    my $mime_type = mime_type_from_path($filename);
    my $content = read_binary($fullpath);

    chomp $site;
    $uri = '/'.$uri;

    print "file $fullpath imported with mime $mime_type \n" if $storage->import_content(
        $content,
        package => $package,
        site => $site,
        uri => $uri,
        mime_type => $mime_type
        );
}

sub usage {
    my ($alert) = @_;

    print STDERR qq{usage: import_httrack.pl <package> <website path>

        $alert
};
    exit 1;
}
