package Localmark::Download::Strategy::Video;

=head DESCRIPTION

obvio no?

=cut

use strict;
use warnings;
use feature 'try';

use Carp;
use List::Util qw(first);
use File::Find qw(find);
use File::Temp qw( mkdtemp );

use Moose;

extends 'Localmark::Download::Strategy::Base';

sub execute {
    my ($self, $url, %args) = @_;

    my ($directory, @files) = $self->video($url);
    my $index_file = first { defined($_) } @files;
    my $index = File::Basename::basename($index_file);

    $args{site_root} = "/" . $index;
    $self->download->import_site($url, $directory, \@files, %args);
}

sub video {
    my ($self, $url, %args) = @_;

    my $command = qq( youtube-dl -q --no-progress --abort-on-error --no-cache-dir --prefer-free-formats --youtube-skip-dash-manifest --no-check-certificate $url );
    my $video_output = mkdtemp( '/tmp/video-output-XXXX' );

    $self->download_state->debug( "running: $command" );
    my $output = qx( cd $video_output && $command );
    $self->download_state->debug( $output );

    my @files = ( );
    find(
        sub {
            my $filename = $File::Find::name;
            return if ! -f $filename;
            push @files, $filename
        },
        $video_output
        );

    return ($video_output, @files);
}

no Moose;
__PACKAGE__->meta->make_immutable;
