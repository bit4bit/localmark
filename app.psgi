#!perl
use strict;
use warnings;

use Localmark::App;
use Dancer2;
use Dotenv;

my $env_file = $ENV{APP_ENV} ? "$ENV{APP_ENV}.env" : 'dev.env';
Dotenv->load($env_file);

dance;
