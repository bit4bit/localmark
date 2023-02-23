package Localmark::Download::Strategy::Websiteable;

use Carp;
use File::Temp qw( mkdtemp mktemp );
use Localmark::Util::File::Slurp qw(read_text);
use File::Find qw(find);
use File::Copy qw( move );

use Moose::Role;

sub path_wget {
    my $path_wget2 = qx(bash -c 'type -p wget2');
    if ($? == 0) {
        chomp $path_wget2;
        carp "WGET2 FOUND AT $path_wget2";
        return $path_wget2;
    } else {
        my $path_binary = qx(bash -c 'type -p wget');
        croak "not found wget binary at: $path_binary" if ! -f $path_binary;
        return $path_binary;
    }
}

sub mirror_website {
    my ($self, $url, %args) = @_;

    my $path = $self->path_wget;
    my $command = qq( $path --mirror --convert-links --html-extension $url );

    my $res = $self->_wget( $command, { allow_parent => 1 } );
    $self->download->download_debug($res->{output});

    return @{ $res->{files} };
}

sub single_website {
    my ($self, $url, %args) = @_;

    my $filter = $args{filter};

    my $path = $self->path_wget;
    my $command = qq( $path --no-check-certificate -k -r -l 2 -p $url );


    my $res = $self->_wget( $command, {
        allow_parent => $args{allow_parent}
                     });
    $self->download_state->debug($res->{output});


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

sub _wget {
    my ($self, $command, $args) = @_;

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
1;
