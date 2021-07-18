package Localmark::Storage::Localmark;

=head1 DESCRIPTION

Tipo de almacenamiento para localmark,
uso sqlite como medio.

=cut

use utf8;
use strict;
use warnings;
use v5.32;

use File::Spec;
use Data::Dumper;
use File::Basename qw(basename);
use Carp;
use DBI;

use Moose;

use Localmark::Resource;
use Localmark::Site;
use Localmark::Util::File::Slurp qw(read_binary);

has 'path' => (
    is => 'rw',
    required => 1
    );

has 'error' => (is => 'rw');

sub import_content {
    my ($self, $content, %args) = @_;

    my $site = $args{site} || croak "requires 'site'";
    my $package = $args{package} || croak "requires 'package'";
    my $uri = $args{uri} || croak "requires 'uri'";
    my $mime_type = $args{mime_type} || 'application/octet-stream';
    my $text = $args{text} || $content;
    
    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;
            
            # insertamos primero el sitio
            my $sth =
                $dbh->prepare( 'INSERT INTO sites(name) VALUES(?) ON CONFLICT(name) DO UPDATE SET name = excluded.name' )
                or croak "couldn't prepare statement: " . $dbh->errstr;
            $sth->execute( $site )
                or croak "couldn't execute statement: " . $sth->errstr;

            # insertamos recurso
            $sth =
                $dbh->prepare( 'INSERT INTO resources(site, uri, content, text, mime_type, inserted_at, updated_at) VALUES(?, ?, ?, ?, ?, datetime("now"), datetime("now")) ON CONFLICT (site, uri) DO UPDATE SET content = excluded.content, mime_type= excluded.mime_type, text = excluded.text' )
                or croak "couldn't prepare statement: " . $dbh->errstr;
            $sth->execute( $site, $uri, $content, $text, $mime_type )
                or croak "couldn't execute statement: " . $sth->errstr;

            return 1;
        }
        );
}

sub import_page {
    my ($self, $path, %args) = @_;

    my $content = read_binary($path);

    $args{uri} = $args{uri} || '/'. basename($path);
    
    $self->import_content($content, %args);
}

sub resource {
    my ($self, %args) = @_;

    my $package = $args{package};
    
    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;

            my $sth = $dbh->prepare( 'SELECT resources.id, resources.site, resources.uri, resources.content, resources.text, resources.mime_type FROM resources WHERE resources.site = ? AND resources.uri = ?' )
                or croak "couldn't prepare statement: " . $dbh->errstr;

            $sth->execute( $args{site}, $args{path} )
                or croak "couldn't execute statement: " . $sth->errstr;

            my $row_ref = $sth->fetchrow_hashref();

            if (not defined $row_ref) {
                return;
            }

            my $site = Localmark::Site->new(
                name => $row_ref->{site},
                title => $row_ref->{site_title}
                );
            my $resource = Localmark::Resource->new(
                id => $row_ref->{id},
                site => $site,
                uri => $row_ref->{uri},
                content => $row_ref->{content},
                mime_type => $row_ref->{mime_type}
                );
            
            return $resource;
        }
        );
}

sub dbh() {
    my ($self, $package, $cb) = @_;

    my $path = File::Spec->catfile( $self->path, "$package.localmark" );
    
    my $dbh = DBI->connect( "dbi:SQLite:$path" )
        or croak "couldn't connect to database: " . DBI->errstr;

    $self->init_db( $dbh );

    my $ret = $cb->( $dbh );

    $dbh->disconnect;

    return $ret;
}

sub init_db {
    my ($self, $dbh) = @_;

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS resources (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               site CHAR(128),
               uri TEXT,
               content BLOB,
               text TEXT,
               mime_type CHAR(64),
               inserted_at DATETIME,
               updated_at DATETIME
               )
               }) or croak $dbh->errstr;

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS sites (
               name CHAR(128) PRIMARY KEY,
               url  TEXT,
               inserted_at DATETIME,
               updated_at DATETIME
               );
               })  or croak $dbh->errstr;

    $dbh->do( 'CREATE UNIQUE INDEX IF NOT EXISTS resources_unique ON resources(site, uri)' )

}

no Moose;
__PACKAGE__->meta->make_immutable;
