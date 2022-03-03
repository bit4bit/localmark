use strict;
use warnings;

use Test2::V0;

use Localmark::Util::Markdown qw( markdown plantuml_fence_block );

subtest "processor" => sub {
    my $text = <<"FENCE";
# hola   

~~~ text
TEXT
~~~

# hola 2

~~~ text
TEXT
~~~

# hola 3
FENCE
    my $want = <<"FENCE";
<h1>hola</h1>

<p>TXET</p>

<h1>hola 2</h1>

<p>TXET</p>

<h1>hola 3</h1>
FENCE

    my $output = markdown
        (
         $text,
         fence_blocks => {
             text => sub {
                 my $content = shift;
                 cmp_ok($content, 'eq', 'TEXT', 'content');
                 "TXET";
             }
         }
        );

    cmp_ok($output, 'eq', $want, 'processor');
};


subtest "plantuml" => sub {
    my $plantuml = <<"FENCE";
# hola

generando plantuml

~~~ plantuml
ClassA o-- ClassB
~~~

FENCE

    my $output = markdown
        (
         $plantuml,
         fence_blocks => {
             plantuml => \&plantuml_fence_block
         }
        );

    ok(1);
};

done_testing;
