use strict;
use warnings;
use Test2::V0;
use File::Temp qw(tempdir mktemp);
use Localmark::Storage;
use Localmark::Storage::Localmark;
use Localmark::Download;
use Localmark::Download::Manager;
use Localmark::Download::Localmark;
use LWP::UserAgent;

# Real network calls - smoke tests
# Run with: CI_REAL_TESTS=1 carton exec prove -l t/integration/smoke.t

my $downloader = Localmark::Download::Localmark->new();
isa_ok($downloader, 'Localmark::Download::Localmark');

my $dir = tempdir(CLEANUP => 1);
my $storer = Localmark::Storage::Localmark->new(path => $dir);
my $store = Localmark::Storage->new(storage => $storer);
isa_ok($store, 'Localmark::Storage');

my $session_file = File::Temp::mktemp('/tmp/session-smoke-XXXXX');
my $manager = Localmark::Download::Manager->new(storage_path => $session_file);

my $download = Localmark::Download->new(
    storage => $store,
    downloader => $downloader,
    manager => $manager
);

# Test guess_site_root
# Note: guess_site_root adds .html to paths that don't end in .html
# This matches the original test behavior in download.t

subtest 'guess_site_root' => sub {
    # Paths ending in .html are preserved
    cmp_ok(
        $download->guess_site_root('http://example.org/page.html', mime_type => 'text/html'),
        'eq',
        '/page.html',
        'preserves path ending in .html'
    );
    
    # Paths without extension get .html added
    cmp_ok(
        $download->guess_site_root('http://example.org/hola', mime_type => 'text/html'),
        'eq',
        '/hola.html',
        'adds .html to path without extension'
    );
    
    # Any path without .html extension gets .html added
    cmp_ok(
        $download->guess_site_root('http://example.org/hola.pod', mime_type => 'text/html'),
        'eq',
        '/hola.pod.html',
        'adds .html to non-html extensions'
    );
};

# Smoke test - link strategy
SKIP: {
    skip "Set CI_REAL_TESTS=1 to run network tests", 6 unless $ENV{CI_REAL_TESTS};
    
    # Test link strategy
    $download->using_strategy(
        'link',
        'http://example.com',
        package => 'smoke_link',
        title => 'Example'
    );
    
    my %site_of = $store->sites();
    ok(exists $site_of{'smoke_link'}, 'link strategy created site');
    
    my @sites = @{$site_of{'smoke_link'} // []};
    ok(scalar(@sites) >= 1, 'at least one site created');
    is($sites[0]->url, 'http://example.com', 'site URL matches');
    
    # Test download history
    my @downloads = $download->downloads();
    is(scalar(@downloads), 1, 'one download recorded');
    is($downloads[0]->state, 'done', 'download state is done');
}

done_testing();