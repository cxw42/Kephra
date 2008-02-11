package Kephra::Config::Global;
$VERSION = '0.17';

# handling main config files under /config/global/

use strict;

sub _get_conf_sub_path {'global'}

sub load_autosaved {
	my @main_conf_files = (
		$Kephra::temp{file}{config}{auto},
		$Kephra::temp{file}{config}{auto}.'~',
		$Kephra::temp{file}{config}{default}
	);

	# try first auto config file, than backup, then defaults
	for my $configfile (@main_conf_files) {
		$configfile = Kephra::Config::filepath( $configfile );
		if ( -e $configfile ) {
			%Kephra::config = %{ Kephra::Config::File::load($configfile) };
			last if %Kephra::config;
			rename $configfile, 'failed.' . $configfile;
		}
	}

	# emergency program if configs missing
	unless ( %Kephra::config ) {
		require Kephra::Config::Embedded;
		%Kephra::config = %{Kephra::Config::Embedded::get_global_settings()};
	}
}

sub save_autosaved {
	my $file_name = Kephra::Config::filepath($Kephra::temp{file}{config}{auto});
	rename $file_name, $file_name . '~';
	Kephra::Config::File::store( $file_name, \%Kephra::config );
}

sub open_current_file {
	save_current();
	require Cwd;
	Kephra::Document::Internal::add( 
		Cwd::getcwd() . '/' .
		Kephra::Config::filepath( $Kephra::temp{file}{config}{auto} )
	);
	Kephra::File::reload_current();
	Kephra::Document::set_attribute('config_file',1);
	Kephra::App::TabBar::refresh_current_label();
}

sub load_backup_file {
	reload( Kephra::Config::filepath( $Kephra::temp{file}{config}{auto}.'~') )
}

sub load_default_file {
	reload( Kephra::Config::filepath( $Kephra::temp{file}{config}{default} ) )
}

sub load_from {
	my $filename = Kephra::Dialog::get_file_open(
		Kephra::App::Window::_get(),
		$Kephra::localisation{dialog}{config_file}{load},
		Kephra::Config::filepath('general'),
		$Kephra::temp{file}{filterstring}{config}
	);
	reload($filename) if -e $filename;
}

sub update {
	Kephra::App::Window::save_positions();
	Kephra::Document::Internal::save_properties();
	Kephra::Edit::Bookmark::save_all();
}

sub evaluate {
	my $t0 = new Benchmark;

	Kephra::API::EventTable::delete_all();
	Kephra::Config::Interface::load_data();
	my $t1 = new Benchmark;
print "  iface cnfg:", Benchmark::timestr( Benchmark::timediff( $t1, $t0 ) ), "\n"
	if $Kephra::benchmark;

	# set interna to default
	$Kephra::app{GUI}{masterID}     = 20;
	$Kephra::temp{dialog}{control}  = 0;
	Kephra::Edit::Search::_init_history();
	Kephra::Edit::Search::_refresh_search_flags();
	Kephra::Config::build_fileendings2syntaxstyle_map();
	Kephra::Config::build_fileendings_filterstring();
	my $t2 = new Benchmark;
print "  prep. data:", Benchmark::timestr( Benchmark::timediff( $t2, $t1 ) ), "\n"
	if $Kephra::benchmark;

	# main window components
	Kephra::API::CommandList::eval_data();
	Kephra::App::Window::apply_settings();
	Kephra::App::ContextMenu::create_all();
	Kephra::App::MenuBar::create();
	Kephra::App::MainToolBar::create();
	Kephra::App::SearchBar::create();
	Kephra::App::TabBar::create();
	Kephra::App::StatusBar::create();
	Kephra::App::assemble_layout();
	my $t3 = new Benchmark;
print "  create gui:", Benchmark::timestr( Benchmark::timediff( $t3, $t2 ) ), "\n"
	if $Kephra::benchmark;

	Kephra::App::ContextMenu::connect_all();
	Kephra::App::EditPanel::apply_settings();
	Kephra::Edit::Bookmark::define_marker();
	my $t4 = new Benchmark;
print "  apply sets:", Benchmark::timestr( Benchmark::timediff( $t4, $t3 ) ), "\n"
	if $Kephra::benchmark;

	Kephra::Config::Interface::del_temp_data();
	Kephra::API::CommandList::del_temp_data();
	#Kephra::API::EventTable::thaw_all();

	return 1;
}


sub reload {
	my $configfile = shift ||
		Kephra::Config::filepath( $Kephra::temp{file}{config}{auto} );
	if ( -e $configfile ) {
		Kephra::Document::Internal::save_properties();
		my %test_hash = %{ Kephra::Config::File::load($configfile) };
		if (%test_hash) {
			%Kephra::config = %test_hash;
			reload_tree();
		} else {
			save();
			Kephra::File::reload_current();
		}
	} else {
		my $err_msg = $Kephra::localisation{dialog}{error};
		Kephra::Dialog::warning_box( undef, 
			$err_msg->{file_find} . "\n $configfile", $err_msg->{config_read} );
	}
}

sub reload_tree {
		update();
		evaluate();
		Kephra::App::TabBar::refresh_all_label();
		Kephra::Document::Internal::eval_properties();
}

sub reload_current {
	reload( Kephra::Config::filepath( $Kephra::temp{file}{config}{auto} ) );
}

sub eval_config_file {
	my $file_name   = shift;
	my $config_path = Kephra::Config::dirpath();
	my $l_path = length $config_path;
	if ($config_path eq substr( $file_name, 0, $l_path)){
		$file_name = substr $file_name, $l_path;
	}

	my $conf = $Kephra::config{app};

	if ($file_name eq $Kephra::temp{file}{config}{auto} or
		$file_name eq $conf->{localisation_file}        or
		$file_name eq $conf->{commandlist}{file}           ) {
		return reload();
	}
	if ( $file_name eq $conf->{menubar}{file}) {
		Kephra::App::MenuBar::create() 
	}
	if ($file_name eq $conf->{toolbar}{main}{file} ) {
		Kephra::App::MainToolBar::create();
	} 
	if ($file_name eq $conf->{toolbar}{search}{file} ) {
		Kephra::App::SearchBar::destroy();
		Kephra::App::SearchBar::create();
		Kephra::App::SearchBar::position();
	}
	# reload template menu wenn template file changed
	my $cfg = $Kephra::config{file}{templates};
	my $path = File::Spec->catfile( $cfg->{directory}, $cfg->{file} );
	if ( substr($file_name, - length $path) eq $path ) {
		Kephra::App::Menu::set_absolete('file_insert_templates');
		Kephra::App::Menu::ready('file_insert_templates');
	}
}

#
sub save {
	my $file_name = shift ||
			Kephra::Config::filepath( $Kephra::temp{file}{config}{auto} );
	update();
	Kephra::Config::File::store( $file_name, \%Kephra::config );
}

sub save_as {
	my $file_name = Kephra::Dialog::get_file_save(
		Kephra::App::Window::_get(),
		$Kephra::localisation{dialog}{config_file}{save},
		$Kephra::temp{path}{config} . _get_conf_sub_path(),
		$Kephra::temp{file}{filterstring}{config}
	);
	save($file_name) if ( length($file_name) > 0 );
}

sub save_current {
	save( Kephra::Config::filepath( $Kephra::temp{file}{config}{auto} ) );
}

#
sub merge_with {
	my $app_win  = Kephra::App::Window::_get();
	my $filename = Kephra::Dialog::get_file_open( $app_win,
		$Kephra::localisation{dialog}{config_file}{load},
		Kephra::Config::filepath( _get_conf_sub_path(), 'sub'),
		$Kephra::temp{file}{filterstring}{config}
	);
	load_subconfig($filename);
}

sub merge_tree {
	my $tree = shift;
	return unless ref $tree eq 'HASH';
	%Kephra::config = %{ Kephra::Config::Tree::merge($tree, \%Kephra::config) };
}

#
sub load_subconfig {
	my $file = shift;
	if ( -e $file ) {
		%Kephra::config = %{ Kephra::Config::Tree::merge
			(Kephra::Config::File::load($file), \%Kephra::config) };
		reload_tree();
	}
}


1;
