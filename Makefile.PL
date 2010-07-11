use warnings;
use strict;
use inc::Module::Install;

use 5.006;

#eval {};
#BEGIN {};

name           'Kephra';
license        'gpl';
author         'Herbert Breunung';

all_from       'lib/Kephra.pm';
requires       'Cwd';
requires       'Encode::Guess'         => 0;
requires       'File::UserConfig';
requires       'Config::General'       => 2.40;
requires       'YAML::Tiny'            => 0.31;
requires       'Text::Wrap';
requires       'POSIX';
requires       'Wx'                    => 0.70;
requires       'Wx::Perl::ProcessStream';
build_requires 'Test::More'            => 0.47;
build_requires 'Test::Script'          => 0.01;
build_requires 'Test::NoWarnings';
build_requires 'Test::Exception';
install_share  'share';
install_script 'bin/kephra';

no_index 'directory' => qw{ t xt share inc };
homepage 'http://kephra.sourceforge.net/';


WriteAll;
