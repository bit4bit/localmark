package Localmark::Comment;

=head1 DESCRIPTION

Comentarios de recursos.

=cut

use strict;
use warnings;

use Localmark::Util::Markdown qw( markdown );
use Moose;
use namespace::autoclean;

has 'resource_id' => (
    is => 'ro',
    isa => 'Int'
    );

has 'comment' => (
    is => 'ro',
    isa => 'Str'
    );

has 'version' => (
    is => 'ro',
    isa => 'Int',
    default => 0
    );

has 'inserted_at' => (
    is => 'ro',
    isa => 'Str'
    );

sub comment_as_markdown {
    my $self = shift;

    if (defined $self->comment) {
        return markdown($self->comment);
    }

    return '';
}

no Moose;
__PACKAGE__->meta->make_immutable;
