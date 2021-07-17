package Localmark::App;

use strict;
use warnings;
use feature 'try';

use Dotenv;

use Localmark::Storage;
use Localmark::Storage::Localmark;

use Dancer2;

our $VERSION = '0.001';


get '/localmark' => sub {
    return 'not implemented';
};

get '/**?' => sub {
    my $package = current_package();
    my $site = current_site();

    # url relativa del sitio web
    my ($rest) = splat;

    my $storage = current_storage();

    my ($resource_path) = @{$rest};

    try {
        my $resource = $storage->resource(
            package => $package,
            site  => $site,
            path => "/" . $resource_path
            );

        if (not defined $resource) {
            return send_error("not found", 404);
        } else {
            return $resource->render;
        }
    }
    catch ($e) {
        if ( UNIVERSAL::isa($e, 'Localmark::Exception') ) {
            send_error( $e->error, 418 );
        } else {
            # TODO(bit4bit): al reemitir el die se pierde la stacktrace
            die $e;
        }
    }
};

# TODO(bit4bit) una estrategia
# es usar una cookie para saber el valor seleccionado
# pero no permitiria varias ventanas al tiempo
sub current_package {
    "test-package";
}

# TODO(bit4bit) una estrategia
# es usar una cookie para saber el valor seleccionado
# pero no permitiria varias ventanas al tiempo
sub current_site {
    "hello";
}

sub current_storage {
    my $storage_directory = $ENV{'STORAGE_DIRECTORY'}
    || die 'requires environment STORAGE_DIRECTORY';

    my $storage =
        Localmark::Storage::Localmark->new( path => $storage_directory);

    return Localmark::Storage->new( storage => $storage );
}
