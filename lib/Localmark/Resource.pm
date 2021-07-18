package Localmark::Resource;

=head1 DESCRIPTION

Un recurso es el contenido de una URL, con la metadata requerida
para renderizar nuevamente el recurso.

=cut

use strict;
use warnings;

use Moose;

has 'id' => (is => 'ro');

has 'site' => (is => 'ro');

has 'uri' => (is => 'ro');

has 'content' => (is => 'ro');

has 'mime_type' => (is => 'ro');

sub render {
    my $self = shift;
    return $self->content;
}

sub error {
    my ($class, $msg) = @_;
    
    my $content =  "<html><h1>$msg</h1></html>";
    return $class->new(content => $content);
}

no Moose;
__PACKAGE__->meta->make_immutable;
