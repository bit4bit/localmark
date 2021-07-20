use strict;
use warnings;

use Test2::V0;

use Data::Dumper;
use File::Temp qw(tempdir);

use Localmark::Storage;
use Localmark::Storage::Localmark;

my $dir = tempdir( CLEANUP => 1 );
my $storer = Localmark::Storage::Localmark->new( path => $dir );
my $store = Localmark::Storage->new(storage => $storer);
isa_ok($store, 'Localmark::Storage');

$storer->import_content(
    "hola mundo",
    package => 'mipackage',
    site => 'misite',
    uri => '/index.html',
    site_url => 'misite',
    site_root => '/index1.html',
    mime_type => 'text/html'
    ) or fail( 'import content' );

$storer->import_content(
    "hola mundo",
    package => 'mipackage2',
    site => 'misite2',
    site_url => 'misite2',
    site_root => '/index2.html',
    uri => '/index.html',
    mime_type => 'text/html'
    ) or fail( 'import content' );

my %site_of = $store->sites();
my @sites = @{ $site_of{'mipackage'} };
cmp_ok(scalar(@sites), '==', 1, 'length of array');
cmp_ok($sites[0]->root, 'eq', '/index1.html', 'site root');
cmp_ok($sites[0]->url, 'eq', 'misite', 'found site');

my @sites2 = @{ $site_of{'mipackage2'} };
cmp_ok(scalar(@sites2), '==', 1, 'length of array');
cmp_ok($sites2[0]->root, 'eq', '/index2.html', 'site root');
cmp_ok($sites2[0]->url, 'eq', 'misite2', 'found site');

done_testing;
