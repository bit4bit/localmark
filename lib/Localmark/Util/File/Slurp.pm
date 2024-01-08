package Localmark::Util::File::Slurp;

use strict;
use warnings;

use File::Slurper ();

use base qw( Exporter );
our @EXPORT_OK = qw(read_binary read_text write_text wrap_file);

sub read_binary {
    my $path = shift;

    return File::Slurper::read_binary($path);
}

sub read_text {
    my $path = shift;

    return File::Slurper::read_text($path);
}

sub write_text {
    my ($path, $content) = @_;

    return File::Slurper::write_text( $path, $content );
}

sub wrap_file {
    my ($source, $dest, $header, $footer) = @_;

    my $content = File::Slurper::read_text( $source );
    return File::Slurper::write_text( $dest, $header . $content . $footer);
}
1;
