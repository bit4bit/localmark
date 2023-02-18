requires 'perl', '>= 5.28.0';
requires 'Moose', '>= 2.20, < 3.0';
requires 'Moo', '>= 0';
requires 'Dancer2', '>= 0.265, < 1.0';
requires 'Dancer2::Template::Mason2', '>= 0.00';
requires 'DBD::SQLite', '>= 1.62';
requires 'Dotenv', '== 0.002';
requires 'File::Slurper', '>= 0.012';
requires 'namespace::autoclean', '>= 0.29';
requires 'LWP::Protocol::https', '>= 6.10';
requires 'Plack', '>= 1.0047';
requires 'Syntax::Feature::Try', '>= 1.005';
requires 'DBIx::Migration', '>= 0.07';
requires 'File::MimeInfo', '>= 0.30';
requires 'Text::Markdown', '>= 1.000031';
requires 'LWP::Simple', '>= 0';
requires 'File::BaseDir', '>= 0';
requires 'Sub::Name', '>= 0';
requires 'File::BaseDir', '>= 0';
requires 'File::Slurp', '>= 0';
requires 'Import::Into', '>= 0';
requires 'Template', '>= 0';

on 'test' => sub {
    requires 'Test2::Suite', '>= 0.000140, < 1.0';
    requires 'Test2::Tools::PerlCritic', '>= 0.04';
    requires 'Plack::Test', '>= 0';
}
