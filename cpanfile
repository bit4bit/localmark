requires 'perl', '>= 5.28.0';
requires 'Moose', '>= 2.20, < 3.0';
requires 'Dancer2', '>= 0.265, < 1.0';
requires 'DBD::SQLite', '>= 1.66';
requires 'Dotenv', '== 0.002';
requires 'File::Slurper', '>= 0.012';
requires 'namespace::autoclean', '>= 0.29';
# 0.25 fallan las test al instalar
requires 'Syntax::Keyword::Try', '== 0.24';
requires 'Feature::Compat::Try', '>= 0.04';
requires 'LWP::Protocol::https', '>= 6.10';

on 'test' => sub {
    requires 'Test2::Suite', '>= 0.000140, < 1.0'
}
