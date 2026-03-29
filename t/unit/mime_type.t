use strict;
use warnings;

use Test2::V0;

use Localmark::Util::MIME::Type;

cmp_ok(mime_type_from_url('https://metacpan.org:443/dist/Moose/activity.svg?res=month'), 'eq', 'image/svg+xml', 'mime type from url with query params');

subtest 'mime_type_from_url' => sub {
    cmp_ok(mime_type_from_url('https://example.com/image.png'), 'eq', 'image/png', 'PNG image');
    cmp_ok(mime_type_from_url('https://example.com/doc.html'), 'eq', 'text/html', 'HTML document');
    cmp_ok(mime_type_from_url('https://example.com/style.css'), 'eq', 'text/css', 'CSS stylesheet');
    cmp_ok(mime_type_from_url('https://example.com/script.js'), 'eq', 'application/javascript', 'JavaScript file');
};

done_testing;