use inc::Module::Install;

name           'Kephra';
all_from       'lib/Kephra.pm';   
requires       'File::Spec'            => '0.80';
requires       'File::Copy::Recursive' => 0;
requires       'Cwd';
requires       'Clone';
requires       'Hash::Merge'           => 0;
requires       'Text::Wrap';
build_requires 'Test::More'            => '0.47';
build_requires 'Test::Script'          => '0.01';
install_script 'bin/kephra';
install_share;

WriteAll;
