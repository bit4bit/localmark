use strict;
use warnings "all";

use Test2::V0;
use Test2::Tools::PerlCritic;

perl_critic_ok ['lib'];
done_testing;
