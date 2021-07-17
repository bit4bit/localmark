requires 'perl', '>= 5.34.0';
requires 'Moose', '>= 2.20, < 3.0';
requires 'Dancer2', '>= 0.30, < 1.0';
requires 'DBD::SQLite', '>= 1.66';
requires 'Dotenv', '== 0.002';
requires 'File::Slurp', '> 0';

on 'test' => sub {
    requires 'Test2::Suite', '>= 0.000140, < 1.0'
}
