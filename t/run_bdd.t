use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/lib";

use Path::Class qw(file dir);
use Test2::V0;
use Test::BDD::Cucumber::Loader;
use Test::BDD::Cucumber::Harness::TAP;

my $features_dir = "$Bin/features";
my @features = glob("$features_dir/*.feature");

plan(scalar @features);

for my $feature_file (sort @features) {
    my $name = (split('/', $feature_file))[-1];
    subtest $name => sub {
        my ($executor, @feature_objects) = Test::BDD::Cucumber::Loader->load($feature_file);
        
        my $harness = Test::BDD::Cucumber::Harness::TAP->new();
        
        for my $feature (@feature_objects) {
            $executor->execute($feature, $harness);
        }
    };
}

done_testing();