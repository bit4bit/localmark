use strict;
use warnings;
use Test2::V0;
use Test::BDD::Cucumber::StepFile qw(Given When Then);
use File::Temp qw(tempdir);
use Localmark::Storage;
use Localmark::Storage::Localmark;
use Localmark::Download;
use Localmark::Download::Localmark;
use Localmark::Download::Manager;

Given qr/a download manager is created/, sub {
    my ($context) = @_;
    
    my $dir = $context->stash->{scenario}->{storage_dir};
    my $storer = Localmark::Storage::Localmark->new(path => $dir);
    my $storage = Localmark::Storage->new(storage => $storer);
    my $downloader = Localmark::Download::Localmark->new();
    
    # Use unique temp file for each scenario to isolate state
    my $session_file = File::Temp::mktemp('/tmp/session-XXXXX');
    my $manager = Localmark::Download::Manager->new(storage_path => $session_file);
    
    my $download = Localmark::Download->new(
        storage => $storage,
        downloader => $downloader,
        manager => $manager
    );
    
    $context->stash->{scenario}->{download} = $download;
};

When qr/I download "([^"]+)" using mock strategy "([^"]+)"/, sub {
    my ($context) = @_;
    my ($url, $strategy) = @{$context->matches};
    
    my $download = $context->stash->{scenario}->{download};
    
    $download->using_strategy(
        $strategy,
        $url,
        package => 'test_download',
        site => 'test_download',
        title => 'test'
    );
};

Then qr/the download history shows (\d+) entries?/, sub {
    my ($context) = @_;
    my $expected_count = $context->matches->[0];
    
    my $download = $context->stash->{scenario}->{download};
    my @downloads = $download->downloads();
    
    is(scalar(@downloads), $expected_count, "download history has $expected_count entries");
};

Then qr/the download state is "([^"]+)"/, sub {
    my ($context) = @_;
    my $expected_state = $context->matches->[0];
    
    my $download = $context->stash->{scenario}->{download};
    my @downloads = $download->downloads();
    
    ok(scalar(@downloads) > 0, 'has downloads');
    is($downloads[0]->state, $expected_state, "first download state is '$expected_state'");
};

Then qr/each download state is "([^"]+)"/, sub {
    my ($context) = @_;
    my $expected_state = $context->matches->[0];
    
    my $download = $context->stash->{scenario}->{download};
    my @downloads = $download->downloads();
    
    for my $d (@downloads) {
        is($d->state, $expected_state, "download state is '$expected_state'");
    }
};

1;