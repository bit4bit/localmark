#!perl
use strict;
use warnings;

use Localmark::App;
use Dancer2;

use Dotenv -load => 'prod.env';

dance;
