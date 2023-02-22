package Localmark::Download::Strategy::Code;

=head DESCRIPTION

codigo fuente

=cut

use strict;
use warnings;
use Carp;
use File::Find qw(find);

use Localmark::SourceCode ();

use Moose;

extends 'Localmark::Download::Strategy::Base';

sub execute {
    my ($self, $url, %args) = @_;

    my $filter_files = $args{filter}->{files} || '';
    my ($directory, @files) = $self->code($url, filter => $filter_files);

    $args{site_root} = '/index.html';
    $self->download->import_site($url, $directory, \@files, %args);
}

sub code {
    my ($self, $url, %args) = @_;

    my $filter = $args{filter};
    my $source = Localmark::SourceCode::clone($url)
        or croak "could not clone repository $url";

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

no Moose;
__PACKAGE__->meta->make_immutable;
