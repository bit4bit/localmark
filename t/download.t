use strict;
use warnings "all";

use Test2::V0;

use Data::Dumper;
use File::Temp qw( tempdir );
use Carp;

use Localmark::Storage;
use Localmark::Download::Localmark;
use Localmark::Download;
use Localmark::Storage::Localmark;


my $downloader = Localmark::Download::Localmark->new();
isa_ok( $downloader, 'Localmark::Download::Localmark' );


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

# link
$download->using_strategy(
    'link',
    'http://bit4bit.github.io',
    package => 'testlocalmarklink',
    title => 'bit4bit.github.io'
    );

done_testing;

=begin
my %site_of = $store->sites();
my @sites = @{ $site_of{'testlocalmarklink'} };
cmp_ok($sites[0]->url, 'eq', 'http://bit4bit.github.io', 'found site');

# single page

$download->using_strategy(
    'single_page',
    'http://www.gnu.org',
    package => 'testlocalmark_single_page',
    title => 'www.gnu.org'
    );

%site_of = $store->sites();
@sites = @{ $site_of{'testlocalmark_single_page'} };
cmp_ok($sites[0]->url, 'eq', 'http://www.gnu.org', 'found site');


# downward website
$download->using_strategy(
    'downward_website',
    'http://www.bit4bit.in',
    package => 'testlocalmark_downward_website',
    title => 'www.bit4bit.io'
    );

%site_of = $store->sites();
@sites = @{ $site_of{'testlocalmark_downward_website'} };
cmp_ok($sites[0]->url, 'eq', 'http://www.bit4bit.in', 'found site');

# upward website
$download->using_strategy(
    'upward_website',
    'http://www.bit4bit.in',
    package => 'testlocalmark_upward_website',
    title => 'www.bit4bit.io'
    );

%site_of = $store->sites();
@sites = @{ $site_of{'testlocalmark_upward_website'} };
cmp_ok($sites[0]->url, 'eq', 'http://www.bit4bit.in', 'found site');

# mirror website
$download->using_strategy(
    'mirror_website',
    'http://www.bit4bit.in',
    package => 'testlocalmark_mirror_website',
    title => 'www.bit4bit.io'
    );

%site_of = $store->sites();
@sites = @{ $site_of{'testlocalmark_mirror_website'} };
cmp_ok($sites[0]->url, 'eq', 'http://www.bit4bit.in', 'found site');

# code fossil
$download->using_strategy(
    'code',
    'http://chiselapp.com/user/bit4bit/repository/localmark/index',
    package => 'testlocalmark_code_fossil',
    title => 'www.bit4bit.io'
    );

%site_of = $store->sites();
@sites = @{ $site_of{'testlocalmark_code_fossil'} };
cmp_ok($sites[0]->url, 'eq', 'http://chiselapp.com/user/bit4bit/repository/localmark/index', 'found site');

# code git
$download->using_strategy(
    'code',
    'https://github.com/bit4bit/localmark',
    package => 'testlocalmark_code_git',
    title => 'www.bit4bit.io'
    );

%site_of = $store->sites();
@sites = @{ $site_of{'testlocalmark_code_git'} };
cmp_ok($sites[0]->url, 'eq', 'https://github.com/bit4bit/localmark', 'found site');

# video

$download->using_strategy(
    'video',
    'https://vimeo.com/358950440',
    package => 'testlocalmark_video',
    title => 'vimeo'
    );

%site_of = $store->sites();
@sites = @{ $site_of{'testlocalmark_video'} };
cmp_ok(scalar(@sites), '==', 1, 'length of array');
cmp_ok($sites[0]->title, 'eq', 'vimeo');
cmp_ok($sites[0]->url, 'eq', "https://vimeo.com/358950440");
cmp_ok($sites[0]->root, 'eq', "/Amazon Music  - Rap Rotation _ Director's Cut-358950440.mp4");

# ipfs site

$download->using_strategy(
    'ipfs_site',
    '/ipfs/QmNhFJjGcMPqpuYfxL62VVB9528NXqDNMFXiqN5bgFYiZ1/its-time-for-the-permanent-web.html',
    package => 'testlocalmark_ipfs_site',
    );


%site_of = $store->sites();
@sites = @{ $site_of{'testlocalmark_ipfs_site'} };
cmp_ok(scalar(@sites), '==', 1, 'length of array');
cmp_ok($sites[0]->url, 'eq', "/ipfs/QmNhFJjGcMPqpuYfxL62VVB9528NXqDNMFXiqN5bgFYiZ1/its-time-for-the-permanent-web.html");
cmp_ok($sites[0]->root, 'eq', "/its-time-for-the-permanent-web.html");

done_testing;
