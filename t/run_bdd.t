use strict;
use warnings;

use FindBin qw($Bin);
use Test::BDD::Cucumber::Harness::TAP;
use Test2::V0;

my $features_dir = "$Bin/features";
my @features = glob("$features_dir/*.feature");

plan(scalar @features);

my $harness = Test::BDD::Cucumber::Harness::TAP->new();

for my $feature (sort @features) {
    my $name = (split('/', $feature))[-1];
    subtest $name => sub {
        $harness->features_path($feature);
        $harness->execute({
            definitions_path => ["$features_dir/step_definitions/*.pl"]
        });
    };
}

done_testing();