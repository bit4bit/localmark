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
use URI ();

use DBIx::Migration;
use Moose;
use namespace::autoclean;
use syntax 'try';

use Localmark::Resource;
use Localmark::Site;
use Localmark::Quote;
use Localmark::Comment;
use Localmark::Util::File::Slurp qw(read_binary);
use Localmark::Util::MIME::Type qw( is_mime_type_readable mime_type_from_path mime_type_from_url );

has 'path' => (
    is => 'ro',
    required => 1
    );

sub update_site {
    my ($self, $package, $name, %params) = @_;

    croak "argument 'package'" if not $package;
    croak "argument 'name'" if not $name;

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;

            my @fields = map { "$_=?" } keys %params;
            $dbh->do( 'UPDATE sites SET ' . (join(',', @fields)) . ' WHERE name = ?', undef, values %params, $name )
                or croak "couldn't update site: " . $dbh->errstr;

            return 1;
        }
        );
}

sub delete_site {
    my ($self, $package, $name) = @_;

    croak "requires 'package'" if not $package;
    croak "requires 'name'" if not $name;

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;
            local $dbh->{AutoCommit} = 0;
            local $dbh->{RaiseError} = 1;

            try {
                $dbh->do( 'DELETE FROM sites WHERE name = ?', undef, $name );
                $dbh->do ( 'DELETE FROM resources WHERE site = ?', undef, $name );
                $dbh->commit;
            }
            catch {
                eval { $dbh->rollback };
            }
        });
}

sub site {
    my ($self, $package, $name) = @_;

    croak "requires 'package'" if not $package;
    croak "requires 'name'" if not $name;

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;
            my $row = $dbh->selectrow_hashref( 'SELECT name, title, url, root, description FROM sites WHERE name = ?', { Slice => {} }, $name);

            return Localmark::Site->new(
                name => $row->{name},
                title => $row->{title},
                description => $row->{description},
                package => $package,
                root => $row->{root},
                url => $row->{url},
                quotes => []
                );
        }
        );
}

sub sites {
    my ($self, $package, %opts) = @_;

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;
            my $rows;
            my $filter_content = $opts{filter}->{content};

            my $search_resources;

            if (defined $filter_content) {
                # SQLITE no soporta right join
                $search_resources = $dbh->selectall_arrayref( 'SELECT id, site FROM resources WHERE text LIKE ?', { Slice => {} }, $filter_content)
                    or croak "fail execute query: " . $dbh->errstr;

                my @sites = map { $_->{site} } @{ $search_resources };
                $rows = $dbh->selectall_arrayref( 'SELECT name, title, url, root, description FROM sites WHERE title LIKE ? or name IN (' . join( ',', map { '?' } @sites) . ')', {Slice => {}}, "%$filter_content%", @sites )
                    or croak "fail execute query: " . $dbh->errstr;
            } else {
                $rows = $dbh->selectall_arrayref( 'SELECT name, title, url, root, description FROM sites', { Slice => {} } )
                    or croak "fail execute query: " . $dbh->errstr;
            }


            my @sites;


            foreach my $row ( @{ $rows } ) {
                # construimos quotes
                my @quotes;
                my @search_resources_by_site = grep { $_->{site} eq $row->{name} } @{ $search_resources };
                foreach my $search_resource ( @search_resources_by_site ) {
                    my $row_resource = $dbh->selectrow_hashref( 'SELECT id, uri, text FROM resources WHERE id = ?', { Slice => {} }, $search_resource->{id})
                        or croak "fail execute query: " . $dbh->errstr;

                    my $quote = Localmark::Quote->new(
                        resource_id => $row_resource->{id},
                        title => $row_resource->{uri},
                        url => $row_resource->{uri},
                        # TODO(bit4bit) solo el fragmento de lo encontrado
                        content => $row_resource->{text}
                        );

                    push @quotes, $quote;
                }

                my $site = Localmark::Site->new(
                    name => $row->{name},
                    title => $row->{title},
                    description => $row->{description},
                    package => $package,
                    root => $row->{root},
                    url => $row->{url},
                    quotes => \@quotes
                    );

                push @sites, $site;
            }

            return \@sites;
        });
}

sub import_content {
    my ($self, $content, %args) = @_;

    my $site = $args{site} || croak "requires 'site'";
    my $package = $args{package} || croak "requires 'package'";

    $site = $self->site_as_id( $site );

    my $site_url = $args{site_url} || $site;
    my $site_title = $args{site_title} || $site;
    my $site_root = $args{site_root} || '/index.html';
    my $site_description =  $args{site_description} || '';
    my $uri = $args{uri} || croak "requires 'uri'";
    my $mime_type = $args{mime_type} || 'application/octet-stream';


    my $text;
    if (is_mime_type_readable($mime_type)) {
        $text = $content
    }

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;

            # insertamos primero el sitio
            my $sth =
                $dbh->prepare( 'INSERT INTO sites(name, title, root, url, description) VALUES(?, ?, ?, ?, ?) ON CONFLICT(name) DO UPDATE SET title = excluded.title, root = excluded.root, url = excluded.url, description = excluded.description' )
                or croak "couldn't prepare statement: " . $dbh->errstr;

            # TODO(bit4bit) como actualizamos el titulo segun el index.html?
            $sth->execute( $site, $site_title, $site_root, $site_url, $site_description )
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

sub import_files {
    my ($self, $directory, $files, %args) = @_;

    my $package = $args{package} || croak "argument 'package'";
    my $site = $args{site} || croak "argument 'site'";
    my $site_root = $args{site_root} || croak "argument 'site_root'";
    my $site_url = $args{site_url} || croak "argument 'site_url'";
    my $site_description = $args{site_description} || '';
    my $site_title = $args{site_title} || $site;



    for my $file ( @{ $files } ) {

        my $mime_type = mime_type_from_path($file);

        # verificar mime type por url
        if (not defined $mime_type) {
            my $main_uri = URI->new($site_url);
            my $base_url = $main_uri->scheme . '://';

            if (defined $main_uri->host_port) {
                $base_url .= $main_uri->host_port;
            }

            # se almacena talcual ya que wget
            # espera la misma ruta exacta
            my $file_url = $file =~ s/^$directory/$base_url/r;

            $mime_type =  mime_type_from_url($file_url);
            if (not $mime_type) {
                carp "OMIT: could't detect mime type for $file or $file_url";
                next;
            }
        }

        my $uri = $file =~ s/^$directory//r;

        $self->import_page(
            $file,
            package => $package,
            site => $site,
            site_title => $site_title,
            site_root => $site_root,
            site_url => $site_url,
            site_description => $site_description,
            uri => $uri,
            mime_type => $mime_type
            );
    }
}

sub resource {
    my ($self, %args) = @_;

    my $package = $args{package};

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;

            my $sth = $dbh->prepare( 'SELECT resources.id, resources.site, resources.uri, resources.content, resources.text, resources.mime_type, sites.title as site_title, sites.root as site_root, sites.url as site_url, sites.description as site_description, comments.resource_id as comment_resource_id, comments.comment as comment_comment, comments.inserted_at as comment_inserted_at, comments.version as comment_version FROM resources LEFT JOIN sites ON sites.name = resources.site LEFT JOIN (SELECT resource_id, inserted_at, comment, MAX(version) as version FROM comments GROUP BY resource_id) AS comments ON comments.resource_id = resources.id WHERE resources.site = ? AND resources.uri = ?' )
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
                description => $row_ref->{site_description},
                package => $package
                );

            my $comment;
            if (defined $row_ref->{comment_resource_id}) {
                $comment = $self->_new_comment($row_ref, $site);
            }

            my $resource = $self->_new_resource($row_ref, $site, $comment);

            return $resource;
        }
        );
}

sub resources {
    my ($self, %args) = @_;

    my $package = $args{package};

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;

            my $sth = $dbh->prepare( 'SELECT resources.id, resources.site, resources.uri, resources.content, resources.text, resources.mime_type, sites.title as site_title, sites.root as site_root, sites.url as site_url, sites.description as site_description, comments.resource_id as comment_resource_id, comments.comment as comment_comment, comments.inserted_at as comment_inserted_at, comments.version as comment_version FROM resources LEFT JOIN sites ON sites.name = resources.site LEFT JOIN (SELECT resource_id, inserted_at, comment, MAX(version) as version FROM comments GROUP BY resource_id) AS comments ON comments.resource_id = resources.id WHERE resources.site = ? ORDER BY resources.id ASC' )
                or croak "couldn't prepare statement: " . $dbh->errstr;

            $sth->execute( $args{site})
                or croak "couldn't execute statement: " . $sth->errstr;


            my $rows_ref = $sth->fetchall_arrayref({});
            if (not defined $rows_ref) {
                return [];
            }

            my @resources;

            for my $row_ref (@{ $rows_ref }) {

                my $site = Localmark::Site->new(
                    name => $row_ref->{site},
                    title => $row_ref->{site_title},
                    root => $row_ref->{site_root},
                    url => $row_ref->{site_url},
                    description => $row_ref->{site_description},
                    package => $package
                    );

                my $comment;
                if (defined $row_ref->{comment_resource_id}) {
                    $comment = $self->_new_comment($row_ref, $site);
                }

                my $resource = $self->_new_resource($row_ref, $site, $comment);
                push @resources, $resource;
            }

            return \@resources;
        }
        );
}

sub insert_comment {
    my ($self, $package, $resource_id, $commentary) = @_;

    return $self->dbh(
        $package,
        sub {
            my $dbh = shift;

            my $comment = $dbh->selectrow_hashref( 'SELECT MAX(version) as version FROM comments WHERE resource_id = ? GROUP BY resource_id', { Slice => {} }, $resource_id );

            my $version = 0;
            if (defined $comment) {
                $version = $comment->{version} + 1;
            }

            $dbh->do ( q{INSERT INTO comments(resource_id, version, comment, inserted_at) VALUES(?, ?, ?, datetime("now"))}, undef, $resource_id, $version, $commentary)
                or croak "cloudn't instert comment: " . $dbh->errstr;

            return 1;
        });
}

sub site_as_id {
    my ($self, $site) = @_;

    md5_hex($site);
}

sub dbh() {
    my ($self, $package, $cb) = @_;

    my $path = File::Spec->catfile( $self->path, "$package.localmark" );

    my $dbh = DBI->connect( "dbi:SQLite:$path" )
        or croak "couldn't connect to database: " . DBI->errstr;

    $self->_deprecated_init_db( $dbh );
    $self->migrate_db($path);

    # TODO(bit4bit) aja si el callback va a retornar @?
    my $ret = $cb->( $dbh );

    $dbh->disconnect;

    return $ret;
}

# mantenemos para mantener compatibilidad anterior
# pero en adelante se usan las migraciones
sub _deprecated_init_db {
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

    # since v0.002
    # UPDATE resources SET text = NULL WHERE mime_type not IN ("text/xml", "application/xhtml+xml", "image/svg+xml", "text/javascript", "application/json", "text/html", "text/plain", "text/csv", "text/css", "application/x-httpd-php");
}

sub migrate_db {
    my ($self, $db_path) = @_;

    my $directory_migrations = File::Spec->catdir(File::Basename::dirname(Cwd::abs_path __FILE__), 'migrations');

    my $m = DBIx::Migration->new(
        {
            dsn => "dbi:SQLite:$db_path",
            dir => $directory_migrations
        }
        );

    $m->migrate(2);

}

sub build_resource_abs_uri {
    my ($self, $row_ref, $site) = @_;

    my $site_package = $site->package;
    my $site_name = $site->name;
    my $resource_uri = $row_ref->{uri};

    return "${site_package}/${site_name}${resource_uri}";
}

sub _new_comment {
    my ($self, $row_ref, $site) = @_;

    my $resource_abs_uri = $self->build_resource_abs_uri($row_ref, $site);

    return Localmark::Comment->new(
        resource_id => $row_ref->{comment_resource_id},
        resource_abs_uri => $resource_abs_uri,
        comment => $row_ref->{comment_comment} || '',
        version => $row_ref->{comment_version},
        inserted_at => $row_ref->{comment_inserted_at}
        );
}

sub _new_resource {
    my ($self, $row_ref, $site, $comment) = @_;
    my $resource_abs_uri = $self->build_resource_abs_uri($row_ref, $site);

    return Localmark::Resource->new(
        id => $row_ref->{id},
        site => $site,
        uri => $row_ref->{uri},
        abs_uri => $resource_abs_uri,
        content => $row_ref->{content},
        mime_type => $row_ref->{mime_type},
        comment => $comment
        );

}
no Moose;
__PACKAGE__->meta->make_immutable;
