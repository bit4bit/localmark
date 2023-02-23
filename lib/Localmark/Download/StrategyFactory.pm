package Localmark::Download::StrategyFactory;

=head DESCRIPTION

estrategias de descarga

=cut

use strict;
use warnings;
use feature 'switch';
use Carp;

use Localmark::Download::Strategy::Base;
use Localmark::Download::Strategy::SinglePage;
use Localmark::Download::Strategy::Link;
use Localmark::Download::Strategy::DownwardWebsite;
use Localmark::Download::Strategy::UpwardWebsite;
use Localmark::Download::Strategy::MirrorWebsite;
use Localmark::Download::Strategy::Code;
use Localmark::Download::Strategy::Video;
use Localmark::Download::Strategy::IpfsSite;

use Moose;

sub selectors {
    my ($self) = @_;

    [
     {'name' => 'single_page', 'title' => 'Single Page'},
     {'name' => 'link', 'title' => 'Link'},
     {'name' => 'downward_website', 'title' => 'Downward Website'},
     {'name' => 'upward_website', 'title' => 'Upward Website'},
     {'name' => 'mirror_website', 'title' => 'Mirror Website'},
     {'name' => 'code', 'title' => 'Code'},
     {'name' => 'video', 'title' => 'Video'},
     {'name' => 'ipfs_site', 'title' => 'IPFS Site'}
    ]
}

sub of {
    my ($self, %args) = @_;
    my $strategy = $args{strategy} or croak 'requires argument strategy';
    my $download = $args{download} or croak 'requires argument download';
    my $download_state = $args{download_state} or croak 'requires argument download_state';

    given ($strategy) {
        when ( 'single_page' ) {
            return Localmark::Download::Strategy::SinglePage->new(
                download => $download,
                download_state => $download_state
                )
        }
        when ( 'link' ) {
            return Localmark::Download::Strategy::Link->new(
                download => $download,
                download_state => $download_state
                )
        }
        when ( 'downward_website' ) {
            return Localmark::Download::Strategy::DownwardWebsite->new(
                download => $download,
                download_state => $download_state
                )
        }
        when ( 'upward_website' ) {
            return Localmark::Download::Strategy::UpwardWebsite->new(
                download => $download,
                download_state => $download_state
                )
        }
        when ( 'mirror_website' ) {
            return Localmark::Download::Strategy::MirrorWebsite->new(
                download => $download,
                download_state => $download_state
                )
        }
        when ( 'code' ) {
            return Localmark::Download::Strategy::Code->new(
                download => $download,
                download_state => $download_state
                )
        }
        when ( 'video' ) {
            return Localmark::Download::Strategy::Video->new(
                download => $download,
                download_state => $download_state
                )
        }
        when ( 'ipfs_site' ) {
            return Localmark::Download::Strategy::IpfsSite->new(
                download => $download,
                download_state => $download_state
                )
        }
        default {
            croak "unknown strategy $strategy";
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
