package Localmark::App;

use strict;
use warnings;
use Feature::Compat::Try;

use Dotenv;
use Data::Dumper;

use Localmark::Storage;
use Localmark::Storage::Localmark;
use Localmark::Download;
use Localmark::Download::Localmark;

use Dancer2;

our $VERSION = '0.001';


get '/' => sub {
    my $storage = current_storage();
    my $sites = sites( $storage );

    template index => {
        sites => $sites,
    };
};

post '/' => sub {
    my $storage = current_storage();
    my $sites = sites( $storage );

    my $package = body_parameters->get('package');
    my $url = body_parameters->get('url');
    my $strategy = body_parameters->get('strategy');
    my $download = downloader();

    $download->using_strategy(
        $strategy,
        $url,
        package => $package
        );

    template index => {
        sites => $sites,
        download_output => $download->output,
        package => $package
    };
};

get '/view/:package/:site/**?' => sub {
    
    my $package = route_parameters->get('package');
    my $site = route_parameters->get('site');

    # url relativa del sitio web
    my ($rest) = splat;
    my $resource_path = join('/', @{$rest});
    $resource_path = '/' . $resource_path;
    
    my $storage = current_storage();

    try {
        my $resource = $storage->resource(
            package => $package,
            site  => $site,
            path => $resource_path
            );

        if (not defined $resource) {
            return send_error("not found package: $package site: $site path: $resource_path" , 404);
        } else {
            header( 'content-type' => $resource->mime_type );
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


sub current_storage {
    my $storage_directory = $ENV{'STORAGE_DIRECTORY'}
    || die 'requires environment STORAGE_DIRECTORY';

    print "Storage directory at: $storage_directory\n";

    my $storage =
        Localmark::Storage::Localmark->new( path => $storage_directory);

    return Localmark::Storage->new( storage => $storage );
}

sub downloader {
    my $storage = current_storage();

    my $downloader = Localmark::Download::Localmark->new();

    return Localmark::Download->new(
        storage => $storage,
        downloader => $downloader
        );
}

sub sites {
    my $storage = shift;
    my %site_of = $storage->sites();

    my @sites;
    foreach my $package (keys %site_of) {
        push @sites, @{ $site_of{$package} };
    }
    @sites = sort {$a->package cmp $b->package} @sites;

    [@sites];
}
