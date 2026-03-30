use strict;
use warnings;
use Test2::V0;
use Test::BDD::Cucumber::StepFile qw(Given When Then);
use File::Temp qw(tempdir);
use Localmark::Storage;
use Localmark::Storage::Localmark;
use Digest::MD5 qw(md5_hex);

my $TEST_CONTENT = "<html><h1>hello</h1></html>\n";

Given qr/a storage directory exists/, sub {
    my ($context) = @_;
    my $dir = tempdir(CLEANUP => 1);
    my $storer = Localmark::Storage::Localmark->new(path => $dir);
    my $storage = Localmark::Storage->new(storage => $storer);
    $context->stash->{scenario}->{storage} = $storage;
    $context->stash->{scenario}->{storage_dir} = $dir;
};

Given qr/the application is running/, sub {
    my ($context) = @_;
    $context->stash->{scenario}->{storage_dir} //= tempdir(CLEANUP => 1);
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    my $storage = Localmark::Storage->new(storage => $storer);
    $context->stash->{scenario}->{storage} = $storage;
};

Given qr/a site "([^"\/]+)\/([^"]+)" with resource "([^"]+)" containing html content/, sub {
    my ($context) = @_;
    my ($package, $site, $path) = @{$context->matches};
    
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    $storer->import_content(
        $TEST_CONTENT,
        package => $package,
        site => $site,
        uri => $path,
        site_url => $site,
        site_root => $path,
        mime_type => 'text/html'
    );
    
    # Site names are hashed, store the actual hashed name
    my $site_id = md5_hex($site);
    $context->stash->{scenario}->{site_ids}->{$site} = $site_id;
};

Then qr/the response contains html content/, sub {
    my ($context) = @_;
    is($context->stash->{scenario}->{response}->content, $TEST_CONTENT, 'response content matches');
};

1;