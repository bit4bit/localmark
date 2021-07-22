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
use File::Copy qw( move );
use Carp;

use Localmark::Util::File::Slurp qw(read_text);

use Moose;
use namespace::autoclean;

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
    my ($self, $url, %args) = @_;

    my $path = $self->path_wget;
    my $command = qq( $path --no-check-certificate -k -p $url);

    my $res = _wget( $command );

    $self->output($res->{output});

    return @{ $res->{files} };
}

sub single_website {
    my ($self, $url, %args) = @_;

    my $path = $self->path_wget;
    my $command = qq( $path --no-check-certificate -k -r -l 2 -p $url );


    my $res = _wget( $command, {
        allow_parent => $args{allow_parent}
                     });
    $self->output($res->{output});

    return @{ $res->{files} };
}

# obtiene una pagina
sub get {
    my ($self, $url) = @_;

    #https://perlmaven.com/simple-way-to-fetch-many-web-pages
    my $html = qx{wget --quiet --output-document=- $url};
    return $html;
}

sub _wget {
    my ($command, $args) = @_;

    my $website = mkdtemp( '/tmp/httrack-XXXX' );
    my $command_output = mktemp( '/tmp/httrack-log-XXXX' );

    my @extra_options = ();
    push @extra_options, "--no-parent" if (not $args->{allow_parent});
    
    my $wget_options = join ' ', @extra_options;

    qx( $command $wget_options -P $website -nH -E -a $command_output);

    my $output = read_text( $command_output );
    
    # primer elemento es el directorio raiz
    my @files = ( $website );
    find(
        sub {
            my $filename = $File::Find::name;
            return if ! -f $filename;

            # wget -E si no detecta el tipo correcto
            # adiciona .html dejando archivos como panel.png.html
            # intentamos corregir esto
            if ($filename =~ /(.+\.png|jpg|jpeg|svg|ttf|woff|woff2|xhtml|ico|txt|html|xml|js|css|gif)(\.html)$/) {
                carp "FIX: renaming $filename to $1\n";
                move $filename, $1;
                push @files, $1;
            } else {
                push @files, $filename;
            }

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
