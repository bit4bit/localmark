package Localmark::Resource;

use strict;
use warnings;



use Moose;

has 'id' => (is => 'rw');

has 'site' => (is => 'rw');

has 'uri' => (is => 'rw');

has 'content' => (is => 'rw');

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
