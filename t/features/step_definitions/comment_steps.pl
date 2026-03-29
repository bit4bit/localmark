use strict;
use warnings;
use Test2::V0;
use Test::BDD::Cucumber::StepFile qw(Given When Then);
use File::Temp qw(tempdir);
use Localmark::Storage;
use Localmark::Storage::Localmark;
use Digest::MD5 qw(md5_hex);

Given qr/the resource "([^"]+)" in site "([^"]+)" package "([^"]+)" has comment "([^"]+)"/, sub {
    my ($context) = @_;
    my ($path, $site, $package, $comment) = @{$context->matches};
    
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    my $site_id = md5_hex($site);
    
    my $resource = $storer->resource(
        package => $package,
        site => $site_id,
        path => $path
    );
    
    ok($resource, 'resource exists');
    $storer->insert_comment($package, $resource->id, $comment);
};

When qr/I add comment "([^"]+)" to resource "([^"]+)" in site "([^"]+)" package "([^"]+)"/, sub {
    my ($context) = @_;
    my ($comment, $path, $site, $package) = @{$context->matches};
    
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    my $site_id = md5_hex($site);
    
    my $resource = $storer->resource(
        package => $package,
        site => $site_id,
        path => $path
    );
    
    ok($resource, 'resource exists');
    $storer->insert_comment($package, $resource->id, $comment);
};

Then qr/the resource "([^"]+)" in site "([^"]+)" package "([^"]+)" has comment "([^"]+)"/, sub {
    my ($context) = @_;
    my ($path, $site, $package, $expected_comment) = @{$context->matches};
    
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    my $site_id = md5_hex($site);
    
    my $resource = $storer->resource(
        package => $package,
        site => $site_id,
        path => $path
    );
    
    ok($resource, 'resource exists');
    ok($resource->comment, 'resource has a comment');
    is($resource->comment->comment, $expected_comment, "comment is '$expected_comment'");
};

Then qr/the resource "([^"]+)" in site "([^"]+)" package "([^"]+)" shows comment "([^"]+)"/, sub {
    my ($context) = @_;
    my ($path, $site, $package, $expected_comment) = @{$context->matches};
    
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    my $site_id = md5_hex($site);
    
    my $resource = $storer->resource(
        package => $package,
        site => $site_id,
        path => $path
    );
    
    ok($resource, 'resource exists');
    ok($resource->comment, 'resource has a comment');
    is($resource->comment->comment, $expected_comment, "comment is '$expected_comment'");
};

1;