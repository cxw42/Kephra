package Kephra::Config::Localisation;
our $VERSION = '0.06';

use strict;
use warnings;

use File::Find();
use YAML::Tiny();

# handling config files under config/localisation
my %strings;
sub strings  { if (ref $_[0] eq 'HASH') {%strings = %{$_[0]}} else {\%strings} }
sub _config  { $Kephra::config{app}{localisation} }
sub _sub_dir { _config->{directory} if _config->{directory} }
sub dir      { Kephra::Config::dirpath( _sub_dir() )        }
sub file     { File::Spec->catfile( dir(), _config()->{file} ) if _config()->{file} }

my %index;
sub _index { if (ref $_[0] eq 'HASH') {%index = %{$_[0]}} else { \%index } }

sub set_file_name { file_name(@_) if @_ }
sub file_name {
	if (defined $_[0]) { _config()->{file} = $_[0] } else { _config()->{file} }
}

sub load {
	my $index = _index();
	my $file = file();
	my $l = Kephra::Config::File::load( $file ) if defined $file;
	$l = Kephra::Config::Default::localisation() unless $l and %$l;
	%strings = %Kephra::localisation = %$l;
}

sub change_to {
	my ($lang) = shift;
	return unless $lang;
	set_documentation_lang( $lang );
	set_file_name( _index()->{$lang}{file_name} );
	Kephra::Config::Global::reload_tree();
}

# open localisation file in the editor
sub open_file { Kephra::Show::_open_config( File::Spec->catfile(dir(), $_[0]) ) }

sub set_documentation_lang {
	my $lang = shift;
	return until $lang;
	$lang = 'deutsch' if $lang eq 'de';
	$lang = 'english' unless $lang eq 'deutsch';
	my $sb = Kephra::Config::Global::_sub_dir();
	my $file = Kephra::Config::filepath( $sb, 'sub/documentation', $lang.'.conf' );
	Kephra::Config::Tree::merge( Kephra::Config::File::load($file) );
}

#my %lang_map = (); config_localisation config_app_lang
sub create_menus {
	my $l18n_index = refresh_index();
	return unless ref $l18n_index eq 'HASH';

	my $l18n = strings->{commandlist}{help}{config};
	my ($al_cmd,  $fl_cmd) = ('config-app-lang', 'config-file-localisation');
	my ($al_help, $fl_help) = Kephra::API::CommandList::get_property_list
			('help', $al_cmd, $fl_cmd);
#print("--$al_help  $fl_help\n");
	my (@config_app_lang, @config_localisation);
	for my $lang_code (sort keys %$l18n_index) {
		my $lang_data = $l18n_index->{$lang_code};
		my $lang = ucfirst $lang_data->{language};
		my $file = $lang_data->{file_name};
		my $al_lang_cmd = "$al_cmd-$lang_code";
		my $fl_lang_cmd = "$fl_cmd-$lang_code";
		Kephra::API::CommandList::new_cmd( $al_lang_cmd, {
			call  => 'Kephra::Config::Localisation::change_to('."'".$lang_code."')",
			state => 'Kephra::Config::Localisation::file_name() eq '."'".$file."'",
			label => $lang, 
			help  => "$al_help $lang",
		});
		Kephra::API::CommandList::new_cmd( $fl_lang_cmd, {
			call  => 'Kephra::Config::Localisation::open_file('."'".$file."')",
			label => $lang,
			help  => "$fl_help $lang",
		});
		push @config_app_lang, 'item '.$al_lang_cmd;
		push @config_localisation, 'item '.$fl_lang_cmd;
	}
	Kephra::App::Menu::create_static('config_localisation',\@config_localisation);
	Kephra::App::Menu::create_static('config_app_lang',    \@config_app_lang);
}

sub refresh_index {
	my $use_cache = Kephra::Config::Interface::_config()->{cache}{use};
	my $index_file = Kephra::Config::filepath
		(Kephra::Config::Interface::_cache_sub_dir(), 'index_l18n.yml');
	my $l18n_dir = dir();

	my %old_index = %{ YAML::Tiny::LoadFile( $index_file ) } if -e $index_file;
	my %new_index;

	my ($FH, $file_name, $age, $line, $k, $v);
	$File::Find::prune = 1;
	File::Find::find( sub {
		#dont check directories
		return if -d $_; 
		$file_name = $_;
		$age = Kephra::File::IO::get_age($file_name);
		# if file is know and unrefreshed just copy loaded <about> data
		if (exists $old_index{$_} and $age == $old_index{$_}{age}) {
			$new_index{$file_name} = $old_index{$file_name};
			return;
		}
		open $FH, '<', $_ ;
		$line = <$FH>;
		chomp $line;
		if ($line =~ m|.*<about>$|){
			while (<$FH>){
				chomp;
				last if $_ =~ m|\s*</about>|;
				($k, $v) = split /=/;
				$k =~ tr/ \t//d;
				$v =~ /\s*(.+)\s*/;
				$new_index{$file_name}{$k} = $1;
			}
		}
		$new_index{$file_name}{age} = $age;
		#if $newindex{$file_name}{purpose} eq 'global localisation'
	}, $l18n_dir);
	$File::Find::prune = 0;

	YAML::Tiny::DumpFile($index_file, \%new_index);

	# taking iso codes as indices
	for my $file (keys %new_index) {
		$new_index{$file}{file_name} = $file;
		$new_index{ $new_index{$file}{iso_code} } = $new_index{$file};
		delete $new_index{$file};
	}
	_index(\%new_index);
	\%new_index;
}

1;
