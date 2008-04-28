use warnings;
use strict;
use inc::Module::Install;

name           'Kephra';
all_from       'lib/Kephra.pm';
requires       'Config::General';
requires       'Cwd';
requires       'File::Spec'            => '0.80';
requires       'File::Copy::Recursive' => 0;
requires       'File::HomeDir';
requires       'File::UserConfig';
requires       'Text::Wrap';
requires       'Wx'                    => '0.70';
requires       'YAML';
build_requires 'Test::More'            => '0.47';
build_requires 'Test::Script'          => '0.01';
install_share  'share';
install_script 'bin/kephra';

WriteAll;