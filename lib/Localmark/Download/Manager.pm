package Localmark::Download::Manager;

=head DESCRIPTION

Gestor de descargas

=cut

use strict;
use utf8;
use warnings;
use Data::Dumper;
use Carp;
use Storable qw(store retrieve) ;
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

sub new_download {
    my ($self, $id) = @_;

    my $state = Localmark::Download::State->new(
        name => $id,
        state => 'new',
        manager => $self
        );
    push(@{$self->download_history}, $state);
    $self->sync();

    $state;
}

sub sync {
    my $self = shift;
    store($self->download_history, $self->storage_path) || die "can't store Manager\n";
}

sub _restore {
    my $self = shift;

    my $store = retrieve($self->storage_path) || die "can't store Manager\n";
    $self->download_history($store);
}

no Moose;
__PACKAGE__->meta->make_immutable;
