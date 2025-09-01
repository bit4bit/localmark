package Localmark::SourceCode;

=head1 DESCRIPTION

Operaciones relacionados con codigo fuente

=cut

use strict;
use warnings;

use base qw( Exporter );
use Carp;
use File::Path qw( make_path );
use File::Find qw( find );
use File::Spec::Functions qw( catfile );
use File::Basename qw( dirname );
use File::Temp qw( mkdtemp );
use File::Copy qw( copy );
use Digest::MD5 qw(md5_hex);
use Localmark::Util::File::Slurp qw( write_text wrap_file );
use Localmark::Util::Shell qw( has_command find_command exec_command );

our @EXPORT_OK = qw( htmlify );

my $has_highlight = has_command('highlight');
my $has_git = has_command('git');
my $has_fossil = has_command('fossil');
my $has_hg = has_command('hg');
my %cloners = ( "git" => $has_git, "fossil" => $has_fossil, "hg" => $has_hg );

unless ($has_highlight) {
    warn "!!DISABLED SUPPORT FOR `hightlight`";
}
unless ($has_git) {
    warn "!!DISABLED SUPPORT FOR `git`";
}
unless ($has_hg) {
    warn "!!DISABLED SUPPORT FOR `hg`";
}
unless ($has_fossil) {
    warn "!!DISABLED SUPPORT FOR `fossil`";
}

sub clone {
    my ($url) = @_;

    my $repo_id = md5_hex($url);
    my %clone_cmd_of = (
        "git" => sub {
            my ($dest_directory) = @_;
            exec_command("git", "clone", "--depth", "1", "--single-branch", "$url", "$dest_directory");
        },
        "fossil" => sub {
            my ($dest_directory) = @_;
            exec_command("fossil", "open", "-f", "$url", "--repodir", "$dest_directory", "--workdir", "$dest_directory");
        },
        "hg" => sub {
            my ($dest_directory) = @_;
            exec_command("hg", "clone", "-yv", "--insecure", "$url", "$dest_directory");
        }
        );

    for my $repo (keys %clone_cmd_of) {
        my $dest_directory = mkdtemp( '/tmp/localmark-source-code-XXXX' );

        next if (not defined $cloners{$repo});

        my $clone_cmd = $clone_cmd_of{$repo}->($dest_directory);
        carp "CLONE: $clone_cmd";

        return $dest_directory if system($clone_cmd) == 0;

        carp "CLONE: failed $repo trying next cloner..";
    }

    return;
}

sub htmlify {
    my ($src_directory) = @_;

    $has_highlight or return carp "HTMLIFY: not found command highlight in PATH";

    my $dest_directory = mkdtemp( '/tmp/localmark-htmlify-XXXX' );

    croak "invalid source directory" if !-d $src_directory;
    make_path( $dest_directory );

    # convertimos archivos de repositorio usando highlight
    my @converted_files;
    my @source_files;
    find(
        sub {
            my $filename = $File::Find::name;
            return if ! -f $filename;
            return if $filename =~ m|/\.|;
            return if $filename =~ m|\.git[/]?|;
            return if $filename =~ m|\.fossil|;

            push @source_files, $filename;
        },
        $src_directory);

    for my $filename (@source_files) {
        my $filename_relative = $filename =~ s|$src_directory/?||r;
        my $filename_relative_out = "$filename_relative.html";
        my $filename_out = catfile( $dest_directory, $filename_relative_out );

        make_path( dirname( $filename_out ) );
        my $cmd = exec_command("highlight", "--inline-css", "-a", "-l", "-i", $filename, "-o", $filename_out);
        carp "HTMLIFY: " . $cmd;

        # desconocidos los envolvemos con pre
        if (system($cmd) != 0) {
            carp "command $cmd failed: $?";
            wrap_html( $filename, $filename_out );
        }
        push @converted_files, $filename_relative_out;
    }

    # generamos indice
    my $index = '<!DOCTYPE><html><head><title>Source Code</title></head><body>';
    for my $filename (@converted_files) {
        $index .= qq{<a href="$filename">$filename</a>};
        $index .= '</br>';
    }
    $index .= "</body>";

    my $path_index = catfile( $dest_directory, 'index.html' );
    write_text( $path_index, $index );
    carp "HTMLIFY: create $path_index";

    return $dest_directory;
}

sub wrap_html {
    my ($source, $dest) = @_;

    wrap_file( $source, $dest, "<!DOCTYPE html><html><body><pre>", "</pre></body></html>");
}
