use strict;
use warnings;

use Data::Dumper;

use Test2::V0;

use Plack::Test;
use HTTP::Request::Common;
use File::Temp qw(tempdir);

use Localmark::App;

use Dotenv -load => 'test.env';

my $app = Localmark::App->to_app;
my $test = Plack::Test->create($app);

$ENV{'STORAGE_DIRECTORY'} = tempdir( CLEANUP => 1 );
my $storage_directory = $ENV{'STORAGE_DIRECTORY'};

my $storer = Localmark::Storage::Localmark->new( path => $storage_directory );
$storer->import_content(
    "<html><h1>hello</h1></html>\n",
    package => 'test-package',
    site => 'hello',
    uri => '/index.html',
    mime_type => 'text/html') or fail ( 'import content' );

my $sites = $storer->sites( 'test-package' );
my $site = @{ $sites }[0];
my $site_name = $site->name;

my $response;
$response = $test->request(GET "/view/test-package/$site_name/baduri");
ok(not $response->is_success);

$response = $test->request(GET "/view/test-package/$site_name/index.html");
ok($response->is_success, Dumper($response));
is($response->content, "<html><h1>hello</h1></html>\n", 'response content');

done_testing;
