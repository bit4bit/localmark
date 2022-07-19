package Localmark::Comment;

=head1 DESCRIPTION

Comentarios de recursos.

=cut

use strict;
use warnings;

use Localmark::Util::Markdown qw( markdown plantuml_fence_block );
use Moose;
use namespace::autoclean;

has 'resource_id' => (
    is => 'ro',
    isa => 'Int'
    );

has 'resource_abs_uri' => (
    is => 'ro',
    isa => 'Str'
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
        my $content = $self->comment;
        my $resource_abs_uri = $self->resource_abs_uri;
        $content =~ s/%%view%%/\/view\/$resource_abs_uri/xg;

        return markdown
            (
             $content,
             fence_blocks => {
                 plantuml => \&plantuml_fence_block
             }
            );
    }

    return '';
}

no Moose;
__PACKAGE__->meta->make_immutable;
