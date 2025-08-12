package Localmark::App;

use strict;
use warnings;
use syntax 'try';
use v5.14;

use Dotenv;

use Localmark::Storage;
use Localmark::Storage::Localmark;
use Localmark::Download;
use Localmark::Download::Manager;
use Localmark::Download::Localmark;

use Dancer2;
set session => "Simple";

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
    my $strategies = downloader()->strategies();

    template index => {
        sites => $sites,
        filter_package => $filter_package,
        strategies => $strategies
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
    my $filter_package = query_parameters->get('filter_package');
    my $filter_content = query_parameters->get('filter_content');

    my $download = downloader();
    my $strategies = $download->strategies();

    if ($filter_content) {
        $filter_content =~ s/^[^%](.+)[^%]$/%$1%/ms;
    }

    $filter_files .= $filter_files_extras;

    $download->using_strategy(
        $strategy,
        $url,
        package => $package,
        site => $url,
        description => $description,
        site_title => $title,
        filter => {
            files => $filter_files
        }
        );
     my $sites = sites( $storage,
                           filter => {
                               package => $filter_package,
                               content => $filter_content
                           });

    template index => {
        sites => $sites,
        download_output => $download->output,
        package => $package,
        strategies => $strategies
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
    my $main_resource_path = request->path =~ s/\/view\/$package\/$site//r;
    my $storage = current_storage();

    my @guess_resource_path = (
        sub {
            $main_resource_path;
        },
        sub {
            $main_resource_path . ".html"
        }
        );

    for my $guess_path (@guess_resource_path) {
        my $resource_path = $guess_path->();
        my $resource = $storage->resource(
            package => $package,
            site  => $site,
            path => $resource_path
            );
        if (defined $resource) {
            response_header( 'content-type' => $resource->mime_type );
            return $resource->render;
        }
    }

    return send_error("not found package: $package site: $site path: $main_resource_path" , 404);
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

use Carp;
use Data::Dumper;

get '/downloads' => sub {
    my $download = downloader();

    my @downloads = $download->downloads();
    my $downloads = \@downloads;
    template downloads => {
        downloads => $downloads
    };
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
    my $download_manager = Localmark::Download::Manager->new(storage_path => '/tmp/session');

    return Localmark::Download->new(
        storage => $storage,
        downloader => $downloader,
        manager => $download_manager
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
