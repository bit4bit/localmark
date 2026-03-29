use strict;
use warnings;
use Test2::V0;
use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Plack::Test;
use HTTP::Request::Common qw(GET POST);
use Localmark::App;
use Localmark::Storage::Localmark;
use Digest::MD5 qw(md5_hex);

When qr/I request the site "([^"]+)" "([^"]+)" resource "([^"]+)"/, sub {
    my ($context) = @_;
    my ($package, $site, $path) = @{$context->matches};
    
    # Get the hashed site name
    my $site_id = $context->stash->{scenario}->{site_ids}->{$site} // md5_hex($site);
    
    $ENV{STORAGE_DIRECTORY} = $context->stash->{scenario}->{storage_dir};
    my $app = Localmark::App->to_app;
    my $test = Plack::Test->create($app);
    $context->stash->{scenario}->{response} = $test->request(GET "/view/$package/$site_id$path");
};

Then qr/the response is successful/, sub {
    my ($context) = @_;
    ok($context->stash->{scenario}->{response}->is_success, 'response successful');
};

Then qr/the response status is (\d+)/, sub {
    my ($context) = @_;
    my $status = $context->matches->[0];
    is($context->stash->{scenario}->{response}->code, $status, "response status is $status");
};

Then qr/the response contains "([^"]+)"/, sub {
    my ($context) = @_;
    my $text = $context->matches->[0];
    like($context->stash->{scenario}->{response}->content, qr/\Q$text\E/, "response contains '$text'");
};

1;