package Test::Factory;

use strict;
use warnings;
use Exporter 'import';
use File::Temp qw(tempdir);
use Localmark::Storage;
use Localmark::Storage::Localmark;

our @EXPORT_OK = qw(create_storage create_site create_resource mock_downloader);

sub create_storage {
    my (%args) = @_;
    my $dir = $args{dir} // tempdir(CLEANUP => 1);
    my $storer = Localmark::Storage::Localmark->new(path => $dir);
    return (Localmark::Storage->new(storage => $storer), $dir);
}

sub create_site {
    my ($storage, %args) = @_;
    my $storer = $storage->{storage};
    
    $storer->import_content(
        $args{content} // "default content",
        package => $args{package} // die "requires package",
        site => $args{site} // die "requires site",
        uri => $args{uri} // '/index.html',
        site_url => $args{site_url} // $args{site},
        site_root => $args{site_root} // '/index.html',
        site_title => $args{site_title} // $args{site},
        site_description => $args{site_description} // '',
        mime_type => $args{mime_type} // 'text/html'
    );
}

sub create_resource {
    my ($storage, %args) = @_;
    create_site($storage, %args);
}

sub mock_downloader {
    my (%args) = @_;
    
    return Localmark::Download::Mock->new(
        fixtures => $args{fixtures} // {}
    );
}

package Localmark::Download::Mock;

use strict;
use warnings;
use Moose;

has 'fixtures' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} }
);

has 'calls' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] }
);

sub get {
    my ($self, $url) = @_;
    push @{$self->calls}, { method => 'get', url => $url };
    return $self->fixtures->{$url} // "<html><body>mock content</body></html>";
}

sub download {
    my ($self, $url, %args) = @_;
    push @{$self->calls}, { method => 'download', url => $url, args => \%args };
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;