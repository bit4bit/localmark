package Localmark::Download::State;

=head DESCRIPTION

Estado de la descarga en curso

=cut

use strict;
use utf8;
use warnings;

use Moose;

has 'name' => (
    is => 'ro',
    required => 1
    );

has 'state' => (
    is => 'rw',
    required => 1
    );

has '_debug' => (
    is => 'rw',
    isa => 'Str',
    default => sub { '' }
    );

has 'manager' => (
    is => 'ro',
    required => 1
    );

sub debug {
    my $self = shift;
    @_ or return $self->_debug;
    $self->_debug( shift );
    $self->manager->sync();
}

sub start_download {
    my $self = shift;

    $self->_set_state( 'starting' );
}

sub stop_download {
    my $self = shift;

    $self->_set_state( 'done' );
}

sub _set_state {
    my ($self, $state) = @_;

    $self->state( $state );
    $self->manager->sync();
}

no Moose;
__PACKAGE__->meta->make_immutable;
