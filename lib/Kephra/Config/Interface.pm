package Kephra::Config::Interface;
our $VERSION = '0.06';

use strict;
use warnings;
 
# handling config files under config/interface

sub _config        { $Kephra::config{app} }
sub _sub_dir       { _config()->{app_data_sub_dir} }
sub _cache_sub_dir { File::Spec->catdir(_sub_dir(), _config()->{cache}{sub_dir})}

sub load { 
	Kephra::API::CommandList::clear();
	Kephra::Config::Localisation::refresh_index();
	my $use_cache = _config()->{cache}{use}; # config allow to use the cache
	my $load_cache = 0;                      # cache is successful loaded
	my (%file,%old_index,%new_index);
	if ($use_cache) {
		my $read = \&Kephra::Config::File::load;
		my $path = \&Kephra::Config::filepath;
		my $get_age = \&Kephra::File::IO::get_age;
		my $cache_dir = _cache_sub_dir();
		$file{index}     = &$path( $cache_dir, 'index_cmd.yml');
		$file{cmd_cache} = &$path( $cache_dir, 'cmd_main.yml' );
		$file{l18n_cache}= &$path( $cache_dir, 'l18n_main.yml');
		$file{cmd}       = Kephra::API::CommandList::file;
		$file{l18n}      = Kephra::Config::Localisation::file;
		%old_index = %{ &$read($file{index}) } if -e $file{index};
		%new_index = (
			'l18n' => {'file' => $file{cmd}, 'age' => &$get_age($file{cmd})},
			'cmd' => {'file' => $file{l18n}, 'age' => &$get_age($file{l18n})},
		);
		if (-e $file{cmd} and -e $file{l18n}) {
			YAML::Tiny::DumpFile( $file{index}, \%new_index );
			if (-e $file{cmd_cache} and -e $file{l18n_cache} and
			    scalar keys %new_index == scalar keys %old_index) {
				$load_cache = 1;
				for (keys %new_index) {
					$load_cache = 0 
						unless $new_index{$_}{age} == $old_index{$_}{age}
						   and $new_index{$_}{file}eq $old_index{$_}{file};
				}
			}
			if ($load_cache) {
				Kephra::API::CommandList::data( &$read( $file{cmd_cache} ) );
				Kephra::Config::Localisation::_set_strings
					( &$read( $file{l18n_cache} ) );
				Kephra::Config::Localisation::set_lang_by_file();
			}
		} else {
			unlink $file{index} if -e $file{index};
		}
	}
	unless ($load_cache) {
		Kephra::Config::Localisation::load();
		Kephra::API::CommandList::load();
		del_temp_data();
		if ($use_cache) {
			my $write = \&YAML::Tiny::DumpFile;
			&$write( $file{cmd_cache}, Kephra::API::CommandList::data() );
			&$write( $file{l18n_cache}, Kephra::Config::Localisation::strings() );
		}
	}
	Kephra::API::CommandList::eval_data();
	Kephra::Config::Localisation::create_menus();
}

sub del_temp_data { Kephra::API::CommandList::del_temp_data() }

sub open_file {
	my $item = shift;
	my $config = _config();
	return unless exists $config->{$item};
	my $file = $config->{$item}{file};
	$file = $config->{$item}{defaultfile} if $item eq 'contextmenu';
	$file = $config->{toolbar}{all}{defaultfile} if $item eq 'toolbar';
	Kephra::Config::open_file( $file );
}

1;
