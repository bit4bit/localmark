package Localmark::Storage::Localmark;

# este tipo de almacenamiento usa sqlite para empaquetar
# y facilitar las consultas sobre los recursos.
# un recurso es basicamente el contenido de una url,
# con la metadata necesaria para reconstruir el sitio.

use utf8;
use strict;
use warnings;
use v5.32;

use Data::Dumper;
use File::Basename qw(basename);

use DBI;

use Moose;
use File::Slurp qw(read_file);

use Localmark::Resource;
use Localmark::Site;

has 'path' => (
    is => 'rw',
    required => 1
    );

has 'error' => (is => 'rw');

sub import_page {
    my ($self, $path, %args) = @_;

    my $site = $args{site};
    my $package = $args{package};
    my $uri = $args{uri} || '/'. basename($path);
    my $content = read_file($path);
    chomp $content;

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;
            
            # insertamos primero el sitio
            my $sth =
                $dbh->prepare( 'INSERT INTO sites(name) VALUES(?) ON CONFLICT(name) DO UPDATE SET name = excluded.name' )
                or die "couldn't prepare statement: " . $dbh->errstr;
            $sth->execute( $site )
                or die "couldn't execute statement: " . $sth->errstr;

            my $row_ref = $sth->fetchrow_hashref();

            # insertamos recurso
            $sth =
                $dbh->prepare( 'INSERT INTO resources(site, uri, content, inserted_at, updated_at) VALUES(?, ?, ?, datetime("now"), datetime("now")) ON CONFLICT (site, uri) DO UPDATE SET content = excluded.content' )
                or die "couldn't prepare statement: " . $dbh->errstr;
            $sth->execute( $site, $uri, $content )
                or die "couldn't execute statement: " . $sth->errstr;

            return 1;
        }
        );
}

sub resource {
    my ($self, %args) = @_;

    my $package = $args{package};
    
    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;

            my $sth = $dbh->prepare( 'SELECT resources.id, resources.site, resources.uri, resources.content FROM resources WHERE resources.site = ? AND resources.uri = ?' )
                or die "couldn't prepare statement: " . $dbh->errstr;

            $sth->execute( $args{site}, $args{path} )
                or die "couldn't execute statement: " . $sth->errstr;

            my $row_ref = $sth->fetchrow_hashref();

            if (not defined $row_ref) {
                # TODO(bit4bit) debe ser tipo
                $self->error("not found");
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
                content => $row_ref->{content}
                );
            
            return $resource;
        }
        );
}

sub dbh() {
    my ($self, $package, $cb) = @_;

    my $path = $self->path . "/$package";
    
    my $dbh = DBI->connect("dbi:SQLite:$path.localmark")
        or die "couldn't connect to database: " . DBI->error;
    $self->init_db($dbh);

    my $ret = $cb->($dbh);

    $dbh->disconnect;

    return $ret;
}

sub init_db {
    my ($self, $dbh) = @_;
    
    $dbh->do(q{;
        CREATE TABLE IF NOT EXISTS resources (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               site CHAR(128),
               uri TEXT,
               content BLOB,
               inserted_at DATETIME,
               updated_at DATETIME
               )
               }) or die $dbh->errstr;

        $dbh->do(q{
        CREATE TABLE IF NOT EXISTS sites (
               name CHAR(128) PRIMARY KEY,
               url  TEXT,
               inserted_at DATETIME,
               updated_at DATETIME
               );
               })  or die $dbh->errstr;

    $dbh->do( 'CREATE UNIQUE INDEX IF NOT EXISTS resources_unique ON resources(site, uri)' )

}

no Moose;
__PACKAGE__->meta->make_immutable;
