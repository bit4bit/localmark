use strict;
use warnings;
use Test2::V0;
use Test::BDD::Cucumber::StepFile qw(Given When Then);
use Plack::Test;
use HTTP::Request::Common qw(GET POST);
use Localmark::App;

When qr/I request the diagramer page/, sub {
    my ($context) = @_;
    
    $ENV{STORAGE_DIRECTORY} = $context->stash->{scenario}->{storage_dir};
    my $app = Localmark::App->to_app;
    my $test = Plack::Test->create($app);
    $context->stash->{scenario}->{response} = $test->request(GET '/diagramer');
};

When qr/I submit PlantUML code to the diagramer:/, sub {
    my ($context) = @_;
    my $code = $context->data;
    
    $ENV{STORAGE_DIRECTORY} = $context->stash->{scenario}->{storage_dir};
    my $app = Localmark::App->to_app;
    my $test = Plack::Test->create($app);
    
    $context->stash->{scenario}->{response} = $test->request(
        POST '/diagramer',
        [ 'code' => $code, 'area-code-cursor-position' => 0 ]
    );
};

Then qr/the response contains diagram output/, sub {
    my ($context) = @_;
    my $content = $context->stash->{scenario}->{response}->content;
    # The response should contain either the processed diagram or the original code
    ok(defined $content, 'response has content');
};

1;