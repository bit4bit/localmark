package Localmark::Download::Strategy::IpfsSite;

=head DESCRIPTION

codigo fuente

=cut

use strict;
use warnings;
use Carp;
use List::Util qw(first);
use File::Find qw(find);
use File::Temp qw( mkdtemp );
use Localmark::Util::Shell qw(find_command);
use URI ();

use Carp;
use Moose;

extends 'Localmark::Download::Strategy::Base';

sub execute {
    my ($self, $url, %args) = @_;

    my ($directory, @files) = $self->ipget($url);
    my $index_file = first { defined($_) } @files;
    my $index = File::Basename::basename($index_file);

    $args{site_root} = "/" . $index;
    $self->download->import_site($url, $directory, \@files, %args);
}

sub ipget {
    my ($self, $url, %args) = @_;

    my $working_dir = mkdtemp( '/tmp/ipget-output-XXXX' );
    my $cmd_path = find_command('ipget') || croak "ipget command not found";
    my $command = qq( $cmd_path '$url' );

    # hack libgen.rs
    my $uri = URI->new($url);
    my %query = $uri->query_form;
    my $libgen_filename = $query{'filename'};
    if (defined $libgen_filename) {
        $command = qq( ipget -o '$libgen_filename' '$url' );
    }

    $self->download_state->debug( "running: $command" );
    my $output = qx( cd $working_dir && timeout 60s $command ) ;
    $self->download_state->debug( $output );

    my @files = ( );
    find(
        sub {
            my $filename = $File::Find::name;
            return if ! -f $filename;

            push @files, $filename
        },
        $working_dir
        );

    return ($working_dir, @files);
}

no Moose;
__PACKAGE__->meta->make_immutable;
