package Localmark::Util::Markdown;
use v5.28;

use Text::Markdown ();

use Localmark::Util::File::Slurp qw( read_text );
use File::Temp qw( tempfile tempdir );
use File::Basename qw( basename );
use Carp;
use Data::Dumper;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( markdown plantuml_fence_block);


my $has_plantuml = system('plantuml -version > /dev/null') == 0;

sub markdown {
    my ($text, %args) = @_;

    my $processors_fence_blocks = $args{fence_blocks} || {};
    $text = process_fence_blocks($text, $processors_fence_blocks);

    return Text::Markdown::markdown($text);
}

sub plantuml_fence_block {
    my $content = shift;

    if (! $has_plantuml) {
        carp 'WARN: DETECTE FENCE BLOCK PLANTUML BUT NOT DETECTED COMMAND plantuml';
        return $content;
    }

    my ($fh, $filename) = tempfile();

    if ($content =~ '@startuml') {
	    say $fh $content;
    } else {
	    say $fh '@startuml';
	    say $fh $content;
	    say $fh '@enduml';
    }

    close $fh;

    my $cmd = "plantuml -tsvg $filename";

    carp "PLANTUML: $cmd";

    system( $cmd ) == 0
        or carp "PLANTUML_FENCE_BLOCK failed: $?";

    my $svgname = $filename . '.svg';

    my $xml = read_text( $svgname );
    $xml =~ s/\<\?xml[^>]+\>//;

    return $xml;
}

sub process_fence_blocks {
    my ($text, $processors) = @_;


    # adicionamos identificador ejemplo plantuml:<id>
    my $id = 1;
    $text =~ s/(~~~[ ]*[\w\d]+)/$1.":".($id++)/emxg;

    # ejecutamos procesadores
    my @outputs = ();
    while ($text =~ /~~~(\N+)\n?\s*([^~]+)~~~/xg) {
        my $fence_id = $1;
        my $fence_body = $2;
        chomp $fence_body;

        $fence_id =~ s/[^\w:\d]//;
        my $fence_name = $fence_id =~ s/:.*//r;        

        if (exists $processors->{$fence_name}) {
            my $output = $processors->{$fence_name}($fence_body);
            push @outputs, [$fence_id, $output]
        }
    }

    # sustituimos salida de procesadors
    for my $item (@outputs) {
        my ($fence_id, $fence_body) = $item->@*;

        # thanks gordonfish
        $text =~ s/~~~\s*$fence_id\R.*?\R~~~/$fence_body/sg;
    }
    
    return $text;
}
1;
