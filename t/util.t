use strict;
use warnings;

use Test2::V0;

use Localmark::Util::MIME::Type;

cmp_ok(mime_type_from_url('https://metacpan.org:443/dist/Moose/activity.svg?res=month'), 'eq', 'image/svg+xml', 'mime type from url with query params');

done_testing;
