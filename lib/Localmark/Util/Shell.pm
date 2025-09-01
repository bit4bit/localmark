package Localmark::Util::Shell;
use strict;
use warnings "all";
use v5.36;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(find_command exec_command has_command);

use Carp;

sub exec_command {
    my ($cmd, @args) = @_;
    my $args_str = join ' ', @args;
    my $output = qq{"$cmd" $args_str};
    chomp $output;
    return $output;
}

sub find_command {
    my  ($name) = @_;

    my $bash_path = `command -v $name 2>/dev/null`;
    chomp $bash_path;
    return $bash_path if -x $bash_path;

    my @paths = (
    "/usr/bin/wget",
    "/usr/bin/wget2",
    "$ENV{HOME}/.local/bin/yt-dlp",
    "/usr/bin/yt-dlp",
    "/usr/bin/git",
    "/usr/bin/fossil",
    "/usr/bin/hg"
    );

    for my $path (@paths) {
        if (-x $path && $path =~ /\Q$name\E/) {
            return $path;
        }
    }

    return "";
}

sub has_command {
    my ($name) = @_;
    return -x find_command($name);
}

1;
