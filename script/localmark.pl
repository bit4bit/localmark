#!perl
use strict;
use warnings;

use Localmark::App;

use Dotenv -load => 'prod.env';

Localmark::App->to_app;

