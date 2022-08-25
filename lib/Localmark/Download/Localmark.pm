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
use Data::Dumper;
use Carp;

use Moose;
use namespace::autoclean;

use Localmark::Util::File::Slurp qw(read_text);
use Localmark::Constant;
use Localmark::SourceCode ();

has 'path_wget' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => 0
    );

has 'output' => (
    is => 'rw',
    isa => 'Str'
    );

sub single_page {
    my ($self, $url, %args) = @_;

    my $path = $self->path_wget;
    my $command = qq( $path --no-check-certificate -k -p $url );

    my $res = _wget( $command );

    $self->output($res->{output});

    return @{ $res->{files} };
}

sub mirror_website {
    my ($self, $url, %args) = @_;

    my $path = $self->path_wget;
    my $command = qq( $path --mirror --convert-links --html-extension $url );

    my $res = _wget( $command, { allow_parent => 1 } );
    $self->output($res->{output});

    return @{ $res->{files} };
}

sub single_website {
    my ($self, $url, %args) = @_;

    my $filter = $args{filter};

    my $path = $self->path_wget;
    my $command = qq( $path --no-check-certificate -k -r -l 2 -p $url );


    my $res = _wget( $command, {
        allow_parent => $args{allow_parent}
                     });
    $self->output($res->{output});


    my ($directory, @files) = @{ $res->{files} };

    # TODO(bit4bit) aplica el filtro despues de descargar todo el contenido
    my @files_filtered = ($directory);

    if (defined $filter && $filter ne '') {
        push @files_filtered, grep { m{$filter}xmg } @files;
    } else {
        push @files_filtered, @files
    }

    return @files_filtered;
}

sub code {
    my ($self, $url, %args) = @_;

    my $filter = $args{filter};
    my $source = Localmark::SourceCode::clone($url)
        or croak "could'nt clone repository $url";

    my $directory = Localmark::SourceCode::htmlify($source);

    my @files = ( $directory );
    find(
        sub {
            my $filename = $File::Find::name;
            return if ! -f $filename;
            # TODO(bit4bit) aplica el filtro despues de descargar todo el contenido
            if (defined $filter && $filter ne '' && $filename !~ m{ $filter }xmg) {
                carp "OMIT: $filename by filter $filter";
                return
            }

            push @files, $filename;
        },
        $directory);

    return @files;
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

    my @extra_options = ( "-U '" . Localmark::Constant::WebAgent . "'" );
    push @extra_options, "--no-parent" if (not $args->{allow_parent});

    my $wget_options = join ' ', @extra_options;
    my $wget_command = qq( $command $wget_options -P $website -nH -E -a $command_output );
    carp 'WGET:', $wget_command;

    qx( $wget_command );

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
            if ($filename =~ /(.+\.)(png|jpg|jpeg|svg|ttf|woff|woff2|xhtml|ico|txt|html|xml|js|css|gif|data)(\.html)(.*)$/) {
                my $new_filename = $1 . $2 . $4;
                carp "FIX: renaming $filename to $new_filename\n";
                move $filename, $new_filename;
                push @files, $new_filename;
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

    my $path_wget2 = qx(bash -c 'type -p wget2');
    if ($? == 0) {
        chomp $path_wget2;
        carp "WGET2 FOUND AT $path_wget2";
        $self->path_wget( $path_wget2 );
    } else {
	$self->path_wget( qx(bash -c 'type -p wget') );
    }

    my $path_binary = $self->path_wget;

    chomp $path_binary;
    $self->path_wget( $path_binary );

    croak "not found wget binary at: $path_binary" if ! -f $path_binary;
}

no Moose;
__PACKAGE__->meta->make_immutable;
