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
use Digest::MD5 qw(md5_hex);
use Localmark::Util::File::Slurp qw( write_text );

our @EXPORT_OK = qw( htmlify );

my $has_highlight = system('highlight --version > /dev/null') == 0;
my $has_git = system('git --version > /dev/null') == 0;
my $has_fossil = system('fossil version > /dev/null') == 0;
my $has_hg = system('hg --version > /dev/null') == 0;
my %cloners = ( "git" => $has_git, "fossil" => $has_fossil, "hg" => $has_hg );

sub clone {
    my ($url) = @_;

    my $repo_id = md5_hex($url);
    my $dest_directory = mkdtemp( '/tmp/localmark-source-code-XXXX' );

    my %clone_cmd_of = (
        "git" => qq{git clone --single-branch "$url" "$dest_directory"},
        "fossil" => qq{fossil open -f "$url" --repodir "$dest_directory" --workdir "$dest_directory"},
        "hg" => qq{hg clone "$url" "$dest_directory"}
        );

    for my $repo (keys %clone_cmd_of) {
        next if (not defined $cloners{$repo});
        
        my $clone_cmd = $clone_cmd_of{$repo};
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
    find(
        sub {
            my $filename = $File::Find::name;
            return if ! -f $filename;
            return if $filename =~ m|/\.|;
            
            my $filename_relative = $filename =~ s|$src_directory/?||r;
            my $filename_relative_out = "$filename_relative.html";
            my $filename_out = catfile( $dest_directory, $filename_relative_out );

            make_path( dirname( $filename_out ) );
            
            my $cmd = qq{highlight --inline-css -a -l -i "$filename" -o "$filename_out"};
            carp "HTMLIFY: " . $cmd;
            
            system($cmd) == 0
                or croak "command $cmd failed: $?";

            push @converted_files, $filename_relative_out;
        },
        $src_directory);

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
