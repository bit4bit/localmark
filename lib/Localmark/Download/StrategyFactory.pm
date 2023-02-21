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

sub of {
    my ($self, $strategy, $download, $downloader) = @_;

    given ($strategy) {
        when ( 'single_page' ) {
            return Localmark::Download::Strategy::SinglePage->new(strategy => $strategy, download => $download, downloader => $downloader)
        }
        when ( 'link' ) {
            return Localmark::Download::Strategy::Link->new(strategy => $strategy, download => $download, downloader => $downloader)
        }
        when ( 'downward_website' ) {
            return Localmark::Download::Strategy::DownwardWebsite->new(strategy => $strategy, download => $download, downloader => $downloader)
        }
        when ( 'upward_website' ) {
            return Localmark::Download::Strategy::UpwardWebsite->new(strategy => $strategy, download => $download, downloader => $downloader)
        }
        when ( 'mirror_website' ) {
            return Localmark::Download::Strategy::MirrorWebsite->new(strategy => $strategy, download => $download, downloader => $downloader)
        }
        when ( 'code' ) {
            return Localmark::Download::Strategy::Code->new(strategy => $strategy, download => $download, downloader => $downloader)
        }
        when ( 'video' ) {
            return Localmark::Download::Strategy::Video->new(strategy => $strategy, download => $download, downloader => $downloader)
        }
        when ( 'ipfs_site' ) {
            return Localmark::Download::Strategy::IpfsSite->new(strategy => $strategy, download => $download, downloader => $downloader)
        }
        default {
            croak "unknown strategy $strategy";
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
