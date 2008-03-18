use warnings;
use strict;
use inc::Module::Install;

name           'kephra';
all_from       'bin/kephra';   
requires       'Clone';
requires       'Config::General';
requires       'Cwd';
requires       'File::Spec'            => '0.80';
requires       'File::Copy::Recursive' => 0;
requires       'File::HomeDir';
requires       'File::UserConfig';
requires       'Hash::Merge'           => 0;
requires       'Text::Wrap';
requires       'Wx';
requires       'YAML';
build_requires 'Test::More'            => '0.47';
build_requires 'Test::Script'          => '0.01';
install_script 'bin/kephra';
install_share;

WriteAll;