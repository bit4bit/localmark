use strict;
use warnings;
use Test2::V0;
use Test::BDD::Cucumber::StepFile qw(Given When Then);
use File::Temp qw(tempdir);
use Localmark::Storage;
use Localmark::Storage::Localmark;
use Test::Factory;

Given qr/a storage directory exists/, sub {
    my ($context) = @_;
    my ($storage, $dir) = Test::Factory::create_storage();
    $context->stash->{storage} = $storage;
    $context->stash->{storage_dir} = $dir;
};

Given qr/the application is running/, sub {
    my ($context) = @_;
    $context->stash->{storage_dir} //= tempdir(CLEANUP => 1);
    my ($storage) = Test::Factory::create_storage(dir => $context->stash->{storage_dir});
    $context->stash->{storage} = $storage;
};

1;