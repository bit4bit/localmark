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
my $dir = tempdir( CLEANUP => 1 );
my $storer = Localmark::Storage::Localmark->new( path => $dir );
my $store = Localmark::Storage->new( storage => $storer );
isa_ok($store, 'Localmark::Storage');

my $download = Localmark::Download->new(
    storage => $store,
    downloader => $downloader
    );

$download->using_strategy(
    'single_page',
    'http://bit4bit.github.io',
    package => 'testbit4bit',
    site => 'testbit4bit',
    title => 'bit4bit.github.io'
    );

$download->using_strategy(
    'single_page',
    'http://www.gnu.org',
    package => 'testgnu',
    site => 'testgnu',
    title => 'gnu'
    );

# history of downloads
my @downloads = $download->downloads();
cmp_ok(scalar(@downloads), '==', 2, 'has downloads');
cmp_ok($downloads[0]->name, 'eq', 'http://bit4bit.github.io');
cmp_ok($downloads[0]->state, 'eq', 'done');
cmp_ok($downloads[0]->debug, 'ne', '');
cmp_ok($downloads[1]->name, 'eq', 'http://www.gnu.org');
cmp_ok($downloads[1]->state, 'eq', 'done');
cmp_ok($downloads[1]->debug, 'ne', '');

done_testing;
