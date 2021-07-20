package Localmark::Download::Localmark;

=head DESCRIPTION

Descargar sitios usando comando *wget*.

=cut

use utf8;
use strict;
use warnings;

use File::Temp qw( mkdtemp mktemp );
use File::Spec;
use File::Find qw(find);
use Carp;

use Localmark::Util::File::Slurp qw(read_text);

use Moose;

has 'path_wget' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    default => '/usr/bin/wget'
    );

has 'output' => (
    is => 'rw'
    );

sub single_page {
    my ($self, $url) = @_;

    my $path = $self->path_wget;
    my $command = qq( $path --no-check-certificate -k -p $url);

    my $res = _wget( $command );
    $self->output($res->{output});

    return @{ $res->{files} };
}

sub single_website {
    my ($self, $url) = @_;

    my $path = $self->path_wget;
    my $command = qq( $path --no-check-certificate -k -p $url -r -l 2 );

    my $res = _wget( $command );
    $self->output($res->{output});

    return @{ $res->{files} };
}

sub _wget {
    my ($command, $url) = @_;

    my $website = mkdtemp( '/tmp/httrack-XXXX' );
    my $command_output = mktemp( '/tmp/httrack-log-XXXX' );
        
    # usamos wget para obtener una sola pagina
    qx( $command  -P $website -nH -a $command_output);
    my $output = read_text( $command_output );
    
    # primer elemento es el directorio raiz
    my @files = ( $website );
    find(
        sub {
            my $filename = $File::Find::name;
            return if ! -f $filename;

            push @files, $filename;
        },
        $website);
    

    return {
        output => $output,
        files => \@files
    };
}
sub BUILD {
    my $self = shift;

    croak "not found wget binary at: ${$self->path_wget}" if ! -f $self->path_wget;
}

no Moose;
__PACKAGE__->meta->make_immutable;
