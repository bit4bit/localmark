requires 'perl', '>= 5.28.0';
requires 'Moose', '>= 2.20, < 3.0';
requires 'Object::Pad', '>= 0.73';
requires 'Dancer2', '>= 0.265, < 1.0';
requires 'Dancer2::Template::Mason2', '>= 0.00';
requires 'DBD::SQLite', '>= 1.62';
requires 'Dotenv', '== 0.002';
requires 'File::Slurper', '>= 0.012';
requires 'namespace::autoclean', '>= 0.29';
# 0.25 fallan las test al instalar
requires 'LWP::Protocol::https', '>= 6.10';
requires 'Plack', '>= 1.0047';
requires 'Syntax::Feature::Try', '>= 1.005';
requires 'DBIx::Migration', '>= 0.07';
requires 'File::MimeInfo', '>= 0.30';
requires 'Text::Markdown', '>= 1.000031';

on 'test' => sub {
    requires 'Test2::Suite', '>= 0.000140, < 1.0'
}
