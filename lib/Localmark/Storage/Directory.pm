package Localmark::Storage::Directory;

use strict;
use warnings;


use Localmark::Site;
use Localmark::Resource;

use Moose;

has 'root' => (
    is => 'rw',
    required => 1
    );

has 'error' => (is => 'rw');

sub resource {
    my ($self, %args) = @_;
    
    my $filename = $self->root . "/" . $args{package} . "/" . $args{site} . "/" . $args{path};

    if (not open(my $fh, '<:encoding(UTF-8)', $filename)) {
        $self->error("$!");
        return;
    } else {
        my $content = <$fh>;

        close $fh;

        chomp $content;

        my $site = Localmark::Site->new(
            name => $args{site},
            title => $args{site}
            );
        my $resource = Localmark::Resource->new(
            id => $filename,
            site => $site,
            uri => $args{path},
            content => $content
            );

        return $resource;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
