use strict;
use warnings;

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

$download->single_page( 'http://bit4bit.github.io' ,
                        package => 'testbit4bit',
                        site => 'bit4bit.github.io' );

my %site_of = $store->sites();
my @sites = @{ $site_of{'testbit4bit'} };
cmp_ok(scalar(@sites), '==', 1, 'length of array');
cmp_ok($sites[0]->name, 'eq', 'bit4bit.github.io', 'found site');


done_testing;
