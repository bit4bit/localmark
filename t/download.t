use strict;
use warnings "all";

use Test2::V0;

use Data::Dumper;
use File::Temp qw( tempdir );

use Localmark::Storage;
use Localmark::Download::Localmark;
use Localmark::Download;
use Localmark::Storage::Localmark;

my $downloader = Localmark::Download::Localmark->new();
isa_ok( $downloader, 'Localmark::Download::Localmark' );
my  ($directory, @files) = $downloader->single_page( 'http://bit4bit.github.io/index.html' );
ok( grep( /\/index.html$/, @files ), 'download index.html' );


my $dir = tempdir( CLEANUP => 1 );
my $storer = Localmark::Storage::Localmark->new( path => $dir );
my $store = Localmark::Storage->new( storage => $storer );
isa_ok($store, 'Localmark::Storage');

my $download = Localmark::Download->new(
    storage => $store,
    downloader => $downloader
    );

cmp_ok($download->guess_site_root('http://example.org/hola.pod', mime_type => 'text/html'), 'cmp', 'http://example.org/hola.pod');

cmp_ok($download->guess_site_root('http://example.org/hola', mime_type => 'text/html'), 'cmp', 'http://example.org/hola.html');

$download->single_page( 'http://bit4bit.github.io' ,
                        package => 'testbit4bit',
                        site => 'bit4bit.github.io',
                        site_url => 'bit4bit.github.io');

my %site_of = $store->sites();
my @sites = @{ $site_of{'testbit4bit'} };
cmp_ok(scalar(@sites), '==', 1, 'length of array');
cmp_ok($sites[0]->url, 'eq', 'http://bit4bit.github.io', 'found site');


# download a video

$download->video( 'https://www.youtube.com/watch?v=Z2d4OkX8GBg',
                  package => 'videotest',
                  site => 'videotest',
                  site_url => 'videotest' );
%site_of = $store->sites();
@sites = @{ $site_of{'videotest'} };
cmp_ok(scalar(@sites), '==', 1, 'length of array');
cmp_ok($sites[0]->title, 'eq', 'GNU MediaLab logo animation - YouTube', 'video download');
cmp_ok($sites[0]->url, 'eq', "https://www.youtube.com/watch?v=Z2d4OkX8GBg");
cmp_ok($sites[0]->root, 'eq', "/GNU MediaLab logo animation-Z2d4OkX8GBg.mp4");


# download a ipfs file
$download->ipfs_site( '/ipfs/QmNhFJjGcMPqpuYfxL62VVB9528NXqDNMFXiqN5bgFYiZ1/its-time-for-the-permanent-web.html',
                      package => 'ipfstest',
                      site => 'ipfstest',
                      site_url => 'ipfstest' );
%site_of = $store->sites();
@sites = @{ $site_of{'ipfstest'} };
cmp_ok(scalar(@sites), '==', 1, 'length of array');
cmp_ok($sites[0]->url, 'eq', "/ipfs/QmNhFJjGcMPqpuYfxL62VVB9528NXqDNMFXiqN5bgFYiZ1/its-time-for-the-permanent-web.html");
cmp_ok($sites[0]->root, 'eq', "/its-time-for-the-permanent-web.html");

done_testing;
