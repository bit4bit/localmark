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
use URI ();

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
    my $command = qq( ipget '$url' );

    # hack libgen.rs
    my $uri = URI->new($url);
    my %query = $uri->query_form;
    my $libgen_filename = $query{'filename'};
    if (defined $libgen_filename) {
        $command = qq( ipget -o '$libgen_filename' '$url' );
    }

    qx( cd $working_dir && timeout 60s $command ) ;

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
