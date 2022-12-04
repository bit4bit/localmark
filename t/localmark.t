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


$storer->import_content(
    "hola mundo",
    package => 'mipackagesearch',
    site => 'misite1',
    uri => '/index.html',
    site_url => 'misite',
    site_root => '/index1.html',
    mime_type => 'text/html'
    ) or fail( 'import content' );

$storer->import_content(
    "hola mundo",
    package => 'mipackagesearch',
    site => 'misite2',
    uri => '/index.html',
    site_url => 'misite',
    site_root => '/index1.html',
    mime_type => 'text/html'
    ) or fail( 'import content' );

$storer->import_content(
    "hola mando",
    package => 'mipackagesearch',
    site => 'misite3',
    uri => '/index.html',
    site_url => 'misite',
    site_root => '/index1.html',
    mime_type => 'text/html'
    ) or fail( 'import content' );

%site_of = $store->sites(
    filter => {
        content => '%mando%'
    });
cmp_ok(scalar(@{ $site_of{mipackagesearch} }), '==', 1, 'length of array');
 %site_of = $store->sites(
    filter => {
        content => '%mundo%'
    });
cmp_ok(scalar(@{ $site_of{mipackagesearch} }), '==', 2, 'length of array');


# content readable

$storer->import_content(
    "hola mundo",
    package => 'mipackagereadable',
    site => 'misite1',
    uri => '/index.html',
    site_url => 'misite',
    site_root => '/index1.html',
    mime_type => 'image/png'
    ) or fail( 'import content' );

$storer->import_content(
    "hola mundo",
    package => 'mipackagereadable2',
    site => 'misite1',
    uri => '/index.html',
    site_url => 'misite',
    site_root => '/index1.html',
    mime_type => 'text/plain'
    ) or fail( 'import content' );

%site_of = $store->sites(
    filter => {
        content => "hola mundo"
    });
cmp_ok(scalar(@{ $site_of{mipackagereadable} }), '==', 0, 'not search by type of content');

%site_of = $store->sites(
    filter => {
        content => "hola mundo"
    });
cmp_ok(scalar(@{ $site_of{mipackagereadable2} }), '==', 1, 'search by type of content');

subtest 'comments' => sub {
    my $package = 'comments';

    $storer->import_content(
        "hola mundo",
        package => $package,
        site => 'misite1',
        uri => '/index.html',
        site_url => 'misite',
        site_root => '/index.html',
        mime_type => 'text/plain'
        ) or fail( 'import content' );

    my $resource = $storer->resource(
        package => $package,
        site => $storer->site_as_id('misite1'),
        path => '/index.html'
        ) or fail( 'read resource');

    $storer->insert_comment(
        $package, $resource->id,
        'excelente'
        );

    $storer->insert_comment(
        $package, $resource->id,
        'excelente last'
        );

    my $resource_with_comment = $storer->resource(
        package => $package,
        site => $storer->site_as_id('misite1'),
        path => '/index.html'
        ) or fail( 'read resource');
    ok $resource_with_comment->id, $resource->id;
    ok $resource_with_comment->comment, 'excelente last', 'resource comment ';
};

done_testing;
