package Localmark::Util::Markdown;

use Text::Markdown ();

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( markdown );


sub markdown {
    my ($text) = @_;
    
    return Text::Markdown::markdown($text);
}

1;
