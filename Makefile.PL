use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
    NAME => 'Localmark',
    AUTHOR => 'Jovany Leandro G.C <bit4bit@riseup.net>',
    VERSION_FROM => 'lib/Localmark/App.pm',
    LICENSE => 'MIT',
    PREREQ_PM => {
        'Dancer2' => '0.30',
            'Moose' => '2.20',
            'DBD::SQLite' => '1.66',
            'File::Slurp' => '9999.32'
    },
    TEST_REQUIRES => {
        'Test2::Suite' => '0.000140'
    },
    EXE_FILES => [
        'script/localmark.pl'
    ],
    META_MERGE => {
        'meta-spec'=> { version => 2 },
            resources => {
                repository => {
                    type => 'fossil',
                    url => 'https://chiselapp.com/user/bit4bit/repository/localmark',
                    web => 'https://chiselapp.com/user/bit4bit/repository/localmark'
                }
        },
    },
    );
