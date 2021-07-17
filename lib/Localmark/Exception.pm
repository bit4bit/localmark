package Localmark::Exception;

use strict;
use warnings;



use Moose;

has 'error' => (
    is => 'rw'
    );

sub raise {
    my ($class, $message) = @_;
    die "requires message" if not defined $message;

    # TODO(bit4bit) obtener el stacktrace del llamador es posible y almacenarlo local es posible?
    die $class->new(error => $message);
}

no Moose;
__PACKAGE__->meta->make_immutable;
