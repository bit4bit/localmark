package Localmark::Download::Manager;

=head DESCRIPTION

Gestor de descargas

=cut

use strict;
use utf8;
use warnings;
use Data::Dumper;
use Carp;
use Storable;
use File::Temp qw/ :POSIX /;

use Localmark::Download::State;

use Moose;

has 'download_history' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] }
    );

has 'storage_path' => (
    is => 'rw',
    default => sub {
        my $file = tmpnam();
        $file;
    }
    );

sub BUILD {
    my $self = shift;

    if (-e $self->storage_path) {
        $self->_restore();
    }
}

sub downloads {
    my $self = shift;

    return $self->download_history;
}

sub start_download {
    my ($self, $id) = @_;

    push(@{$self->download_history}, Localmark::Download::State->new(
             name => $id,
             state => 'starting'
         ));
    $self->_save();
}

sub stop_download {
    my ($self, $id) = @_;
    for my $download (@{$self->download_history}) {
        if ($download->name eq $id) {
            $download->state('done');
        }
    }
    $self->_save();
}

sub _save {
    my $self = shift;
    store($self->download_history, $self->storage_path);
}

sub _restore {
    my $self = shift;
    $self->download_history(retrieve($self->storage_path));
}

no Moose;
__PACKAGE__->meta->make_immutable;
