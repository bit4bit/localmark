package Localmark::App;

use strict;
use warnings;
use syntax 'try';
use v5.14;

use Dotenv;
use Data::Dumper;

use Localmark::Storage;
use Localmark::Storage::Localmark;
use Localmark::Download;
use Localmark::Download::Localmark;

use Dancer2;

our $VERSION = '0.005';

set template => 'template_toolkit';

get '/diagramer' => sub {
    template diagramer => {
        diagram => "",
        code => "",
        cursor_position => 0
    };
};

post '/diagramer' => sub {
    my $code = body_parameters->get('code');
    my $cursor_position = body_parameters->get('area-code-cursor-position');
    my $diagram = Localmark::Util::Markdown::plantuml_fence_block($code);

    template diagramer => {
        diagram => $diagram,
        code => $code,
        cursor_position => $cursor_position
    };
};

get '/' => sub {
    my $filter_package = query_parameters->get('filter_package');
    my $filter_content = query_parameters->get('filter_content');

    if ($filter_content) {
        $filter_content =~ s/^[^%](.+)[^%]$/%$1%/ms;
    }

    my $storage = current_storage();
    my $sites = sites( $storage,
                       filter => {
                           package => $filter_package,
                           content => $filter_content
                       });
    template index => {
        sites => $sites,
        filter_package => $filter_package
    };
};

post '/download' => sub {
    my $storage = current_storage();

    my $package = body_parameters->get('package');
    my $url = body_parameters->get('url');
    my $strategy = body_parameters->get('strategy');
    my $description = body_parameters->get('description');
    my $title = body_parameters->get('title');
    my $filter_files = body_parameters->get('filter-files');
    my $filter_files_extras = body_parameters->get('filter-files-extras');
    my $download = downloader();

    $filter_files .= $filter_files_extras;

    $download->using_strategy(
        $strategy,
        $url,
        package => $package,
        description => $description,
        title => $title,
        filter => {
            files => $filter_files
        }
        );

    my $sites = sites( $storage );
    template index => {
        sites => $sites,
        download_output => $download->output,
        package => $package
    };
};

get '/site/:package/:site' => sub {
    my $package = route_parameters->get('package');
    my $name = route_parameters->get('site');
    my $storage = current_storage();
    my $add_comment_resource = query_parameters->get('add-comment-resource');

    template site => {
        site => $storage->site($package, $name),
        resources => $storage->resources($package, $name),
        add_comment_resource => $add_comment_resource
    };
};

post '/site/:package/:site/info' => sub {
    my $storage = current_storage();

    my $package = route_parameters->get('package');
    my $name = route_parameters->get('site');

    my $title = body_parameters->get('title');
    my $description = body_parameters->get('description');

    $storage->update($package, $name,
                     title => $title,
                     description => $description);

    redirect "/site/$package/$name";
};

post '/site/:package/:site/comment/:resource_id' => sub {
    my $storage = current_storage();

    my $package = route_parameters->get('package');
    my $name = route_parameters->get('site');
    my $resource_id = route_parameters->get('resource_id');

    my $comment = body_parameters->get('comment');

    $storage->insert_comment(
        $package,
        $resource_id,
        $comment
        );

    redirect "/site/$package/$name#resource-$resource_id";
};

get '/view/:package/:site/**?' => sub {

    my $package = route_parameters->get('package');
    my $site = route_parameters->get('site');

    # url relativa del sitio web
    # no usa splat debido a que todo el resto de la ruta
    # es la uri incluido los parametros query
    my $resource_path = request->path =~ s/\/view\/$package\/$site//r;
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

post '/sites/action' => sub {
    my $storage = current_storage();
    my $action = body_parameters->get('action');
    my $site_package = body_parameters->get('site_package');
    my $site_name = body_parameters->get('site_name');


    for ($action) {
        when ('view') {
            my $site = $storage->site($site_package, $site_name);
            my $site_root = $site->root;

            return redirect "/site/$site_package/$site_name";
        }
        when ('delete') {
            $storage->delete($site_package, $site_name);

            return redirect '/';
        }
        default {
            return send_error('unknown action', 418);
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
    my ($storage, %opts) = @_;

    my %site_of = $storage->sites(
        filter => {
            package => $opts{filter}->{package},
            content => $opts{filter}->{content}
        });

    my @sites;
    foreach my $package (keys %site_of) {
        push @sites, @{ $site_of{$package} };
    }
    @sites = sort {$a->package cmp $b->package} @sites;

    [@sites];
}
