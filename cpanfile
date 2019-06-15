requires 'perl', '5.008001';

requires       'Cwd';
requires       'Encode::Guess';
requires       'File::UserConfig';
requires       'Config::General'         => '2.40';
requires       'YAML::Tiny'              => '0.31';
requires       'Text::Wrap';
requires       'POSIX';
requires       'Wx'                      => '0.94';
requires       'Wx::Perl::ProcessStream' => '0.25';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Script'            => '0.01';
    requires 'Test::NoWarnings';
    requires 'Test::Exception';
};

