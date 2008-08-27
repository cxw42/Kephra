use warnings;
use strict;
use inc::Module::Install;

use 5.006;

name           'Kephra';
all_from       'lib/Kephra.pm';
requires       'Cwd';
requires       'File::Spec'            => 0.80;
requires       'File::Copy::Recursive';
requires       'File::HomeDir';
requires       'File::UserConfig';
requires       'Config::General'       => 2.40;
requires       'YAML::Tiny'            => 0.31;
requires       'Text::Wrap';
requires       'Log::Dispatch';
requires       'Log::Dispatch::File';
requires       'POSIX';
requires       'Wx'                    => 0.70;
build_requires 'Test::More'            => 0.47;
build_requires 'Test::Script'          => 0.01;
build_requires 'Test::NoWarnings';
build_requires 'Test::Exception';
install_share  'share';
install_script 'bin/kephra';

WriteAll;
