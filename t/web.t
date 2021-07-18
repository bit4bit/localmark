use strict;
use warnings;

use Data::Dumper;

use Test2::V0;

use Plack::Test;
use HTTP::Request::Common;

use Localmark::App;

use Dotenv -load => 'test.env';

my $app = Localmark::App->to_app;

my $test = Plack::Test->create($app);


my $response;
$response = $test->request(GET '/view/test-package/hello/baduri');
ok(not $response->is_success);

$response = $test->request(GET '/view/test-package/hello/index.html');
ok($response->is_success, Dumper($response));
is($response->content, '<html><h1>hello</h1></html>', 'response content');

done_testing;
