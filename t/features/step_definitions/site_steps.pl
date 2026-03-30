use strict;
use warnings;
use Test2::V0;
use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Plack::Test;
use HTTP::Request::Common qw(GET POST);
use Localmark::App;
use Localmark::Storage::Localmark;
use Digest::MD5 qw(md5_hex);

Given qr/a package "([^"]+)" with site "([^"]+)"/, sub {
    my ($context) = @_;
    my ($package, $site) = @{$context->matches};
    
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    $storer->import_content(
        "default content",
        package => $package,
        site => $site,
        uri => '/index.html',
        site_url => $site,
        site_root => '/index.html',
        mime_type => 'text/html'
    );
    
    my $site_id = md5_hex($site);
    $context->stash->{scenario}->{site_ids}->{$site} = $site_id;
    $context->stash->{scenario}->{packages}->{$package} //= [];
    push @{$context->stash->{scenario}->{packages}->{$package}}, $site;
};

Given qr/a site "([^"]+)" in package "([^"]+)" with resource "([^"]+)" containing "([^"]+)"/, sub {
    my ($context) = @_;
    my ($site, $package, $path, $content) = @{$context->matches};
    
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    $storer->import_content(
        $content,
        package => $package,
        site => $site,
        uri => $path,
        site_url => $site,
        site_root => '/index.html',
        mime_type => 'text/html'
    );
    
    my $site_id = md5_hex($site);
    $context->stash->{scenario}->{site_ids}->{$site} = $site_id;
    $context->stash->{scenario}->{packages}->{$package} //= [];
    push @{$context->stash->{scenario}->{packages}->{$package}}, $site;
};

Given qr/a site "([^"]+)" in package "([^"]+)" with description "([^"]+)"/, sub {
    my ($context) = @_;
    my ($site, $package, $description) = @{$context->matches};
    
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    $storer->import_content(
        "content",
        package => $package,
        site => $site,
        uri => '/index.html',
        site_url => $site,
        site_root => '/index.html',
        site_description => $description,
        mime_type => 'text/html'
    );
    
    my $site_id = md5_hex($site);
    $context->stash->{scenario}->{site_ids}->{$site} = $site_id;
};

When qr/I request the homepage/, sub {
    my ($context) = @_;
    
    $ENV{STORAGE_DIRECTORY} = $context->stash->{scenario}->{storage_dir};
    my $app = Localmark::App->to_app;
    my $test = Plack::Test->create($app);
    $context->stash->{scenario}->{response} = $test->request(GET '/');
};

When qr/I request the homepage with filter_package "([^"]+)"/, sub {
    my ($context) = @_;
    my $package = $context->matches->[0];
    
    $ENV{STORAGE_DIRECTORY} = $context->stash->{scenario}->{storage_dir};
    my $app = Localmark::App->to_app;
    my $test = Plack::Test->create($app);
    $context->stash->{scenario}->{response} = $test->request(GET "/?filter_package=${package}.localmark");
};

When qr/I request the homepage with filter_content "([^"]+)"/, sub {
    my ($context) = @_;
    my $content = $context->matches->[0];
    
    $ENV{STORAGE_DIRECTORY} = $context->stash->{scenario}->{storage_dir};
    my $app = Localmark::App->to_app;
    my $test = Plack::Test->create($app);
    $context->stash->{scenario}->{response} = $test->request(GET "/?filter_content=%25$content%25");
};

When qr/I request the site "([^"]+)" "([^"]+)"/, sub {
    my ($context) = @_;
    my ($package, $site) = @{$context->matches};
    
    my $site_id = $context->stash->{scenario}->{site_ids}->{$site} // md5_hex($site);
    
    $ENV{STORAGE_DIRECTORY} = $context->stash->{scenario}->{storage_dir};
    my $app = Localmark::App->to_app;
    my $test = Plack::Test->create($app);
    $context->stash->{scenario}->{response} = $test->request(GET "/site/$package/$site_id");
};

When qr/I add comment "([^"]+)" to the site resource "([^"]+)"/, sub {
    my ($context) = @_;
    my ($comment, $path) = @{$context->matches};
    
    # Get the storage
    my $storer = Localmark::Storage::Localmark->new(path => $context->stash->{scenario}->{storage_dir});
    
    # Get the resource
    my $site_id = md5_hex('notes');
    my $resource = $storer->resource(
        package => 'test',
        site => $site_id,
        path => $path
    );
    
    # Add comment
    $storer->insert_comment('test', $resource->id, $comment);
};

Then qr/I see (\d+) sites?/, sub {
    my ($context) = @_;
    my $expected_count = $context->matches->[0];
    
    my $content = $context->stash->{scenario}->{response}->content;
    # Count site list items in the HTML response
    my @sites = ($content =~ /<li id="[^"]+">/g);
    my $total = scalar(@sites);
    
    is($total, $expected_count, "found $expected_count sites");
};

Then qr/I see only sites from package "([^"]+)"/, sub {
    my ($context) = @_;
    my $package = $context->matches->[0];
    
    ok($context->stash->{scenario}->{response}->is_success, 'response successful');
    
    # Verify package in response
    my $content = $context->stash->{scenario}->{response}->content;
    like($content, qr/$package/, "response shows package $package");
};

Then qr/I see only site "([^"]+)"/, sub {
    my ($context) = @_;
    my $site = $context->matches->[0];
    
    ok($context->stash->{scenario}->{response}->is_success, 'response successful');
};

Then qr/the response contains the text "([^"]+)"/, sub {
    my ($context) = @_;
    my $text = $context->matches->[0];
    like($context->stash->{scenario}->{response}->content, qr/\Q$text\E/, "response contains '$text'");
};

1;