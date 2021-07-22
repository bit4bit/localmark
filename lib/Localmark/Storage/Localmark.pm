package Localmark::Storage::Localmark;

=head1 DESCRIPTION

Tipo de almacenamiento para localmark,
uso sqlite como medio.

=cut

use utf8;
use strict;
use warnings;
use v5.16;

use File::Spec;
use Data::Dumper;
use File::Basename qw(basename);
use Carp;
use DBI;
use Digest::MD5 qw(md5_hex);

use Moose;
use namespace::autoclean;

use Localmark::Resource;
use Localmark::Site;
use Localmark::Util::File::Slurp qw(read_binary);

has 'path' => (
    is => 'ro',
    required => 1
    );

has 'error' => (is => 'rw');

sub sites {
    my ($self, $package, %opts) = @_;

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;
            my $rows;
            my $filter_content = $opts{filter}->{content};

            if (defined $filter_content) {
                # SQLITE no soporta right join
                my $site_rows = $dbh->selectall_arrayref( 'SELECT DISTINCT site FROM resources WHERE text LIKE ?', { Slice => {} }, $filter_content)
                    or croak "fail execute query: " . $dbh->errstr;

                my @sites = map { $_->{site} } @{ $site_rows };
                $rows = $dbh->selectall_arrayref( 'SELECT name, title, url, root, note FROM sites WHERE name IN (' . join( ',', map { '?' } @sites) . ')', {Slice => {}}, @sites )
                    or croak "fail execute query: " . $dbh->errstr;
            } else {
                $rows = $dbh->selectall_arrayref( 'SELECT name, title, url, root, note FROM sites', { Slice => {} } )
                    or croak "fail execute query: " . $dbh->errstr;
            }

            my @sites;
            foreach my $row ( @{ $rows } ) {
                my $site = Localmark::Site->new(
                    name => $row->{name},
                    title => $row->{title},
                    note => $row->{note},
                    package => $package,
                    root => $row->{root},
                    url => $row->{url}
                    );

                push @sites, $site;
            }

            return \@sites;
        });
}

sub import_content {
    my ($self, $content, %args) = @_;

    my $site = $args{site} || croak "requires 'site'";
    $site = md5_hex($site);

    my $site_url = $args{site_url} || $site;
    my $site_title = $args{site_title} || $site;
    my $site_root = $args{site_root} || '/index.html';
    my $site_note =  $args{site_note} || '';
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
                $dbh->prepare( 'INSERT INTO sites(name, title, root, url, note) VALUES(?, ?, ?, ?, ?) ON CONFLICT(name) DO UPDATE SET title = excluded.title, root = excluded.root, url = excluded.url, note = excluded.note' )
                or croak "couldn't prepare statement: " . $dbh->errstr;

            # TODO(bit4bit) como actualizamos el titulo segun el index.html?
            $sth->execute( $site, $site_title, $site_root, $site_url, $site_note )
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

            my $sth = $dbh->prepare( 'SELECT resources.id, resources.site, resources.uri, resources.content, resources.text, resources.mime_type, sites.title as site_title, sites.root as site_root, sites.url as site_url, sites.note as site_note FROM resources LEFT JOIN sites ON sites.name = resources.site WHERE resources.site = ? AND resources.uri = ?' )
                or croak "couldn't prepare statement: " . $dbh->errstr;

            $sth->execute( $args{site}, $args{path} )
                or croak "couldn't execute statement: " . $sth->errstr;

            my $row_ref = $sth->fetchrow_hashref();

            if (not defined $row_ref) {
                return;
            }

            my $site = Localmark::Site->new(
                name => $row_ref->{site},
                title => $row_ref->{site_title},
                root => $row_ref->{site_root},
                url => $row_ref->{site_url},
                note => $row_ref->{site_note},
                package => $package
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

    # TODO(bit4bit) aja si el callback va a retornar @?
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
               title TEXT,
               url  TEXT,
               root TEXT,
               inserted_at DATETIME,
               updated_at DATETIME
               );
               })  or croak $dbh->errstr;

    $dbh->do( 'CREATE UNIQUE INDEX IF NOT EXISTS resources_unique ON resources(site, uri)' );

    # NOTE(bit4bit) de que otra manera podemos confirmar que existe la columna?
    my $sth = $dbh->column_info( undef, undef, 'sites', 'note' );
    if (not $sth->fetchrow_array()) {
        $dbh->do( 'ALTER TABLE sites ADD COLUMN note TEXT');
    }
        
}

no Moose;
__PACKAGE__->meta->make_immutable;
