package Kephra::Config::Localisation;
our $VERSION = '0.06';

use strict;
use warnings;

use File::Find();
use YAML::Tiny();

# handling config files under config/localisation
my %strings;
sub _set_strings { %strings = %{$_[0]} if ref $_[0] eq 'HASH' }
sub strings   { \%strings }
sub _config   { Kephra::API::settings()->{app}{localisation} }
sub _sub_dir  { _config->{directory} if _config->{directory} }

my %index;
sub _index    { if (ref $_[0] eq 'HASH') {%index = %{$_[0]}} else { \%index } }
my $language;
sub language  { $language }

sub file     { Kephra::Config::filepath(  _sub_dir(), _config()->{file} ) }
sub set_file_name { file_name($_[0]) if defined $_[0]}
sub file_name {
	if (defined $_[0]) { _config()->{file} = $_[0] } else { _config()->{file} }
}
sub set_lang_by_file { $language = $index{ _config()->{file} }{ language } }

#
sub load {
	my $file = file();
	my $l = Kephra::Config::File::load( $file ) if defined $file;
	$l = Kephra::Config::Default::localisation() unless $l and %$l;
	%strings = %$l;
	set_lang_by_file();
}


sub change_to {
	my ($lang_file) = shift;
	return unless $lang_file;
	set_documentation_lang( _index()->{$lang_file}{iso_code} );
	set_file_name( $lang_file );
	Kephra::Config::Global::reload_tree();
}

# open localisation file in the editor
sub open_file { Kephra::Config::open_file( _sub_dir(), $_[0]) }

sub set_documentation_lang {
	my $lang = shift;
	return until $lang;
	$lang = 'deutsch' if $lang eq 'de';
	$lang = 'english' unless $lang eq 'deutsch';
	my $sb = Kephra::Config::Global::_sub_dir();
	my $file = Kephra::Config::filepath( $sb, 'sub/documentation', $lang.'.conf' );
	%Kephra::config = %{ Kephra::Config::Tree::merge
			(Kephra::Config::File::load($file), \%Kephra::config) };
}

# create menus for l18n selection nd opening l18n files
sub create_menus {
	my $l18n_index = _index();
	return unless ref $l18n_index eq 'HASH';

	my $l18n = strings()->{commandlist}{help}{config};
	my ($al_cmd,  $fl_cmd) = ('config-app-lang', 'config-file-localisation');
	my ($al_help, $fl_help) = Kephra::CommandList::get_property_list
			('help', $al_cmd, $fl_cmd);
	my (@config_app_lang, @config_localisation);
	for my $lang_file (sort keys %$l18n_index) {
		my $lang_data = $l18n_index->{$lang_file};
		my $lang = ucfirst $lang_data->{language};
		my $lang_code = $lang_data->{iso_code} || '';
		my $al_lang_cmd = "$al_cmd-$lang_code";
		my $fl_lang_cmd = "$fl_cmd-$lang_code";
		Kephra::CommandList::new_cmd( $al_lang_cmd, {
			call  => 'Kephra::Config::Localisation::change_to('."'".$lang_file."')",
			state => 'Kephra::Config::Localisation::file_name() eq '."'".$lang_file."'",
			label => $lang, 
			help  => "$al_help $lang",
		});
		Kephra::CommandList::new_cmd( $fl_lang_cmd, {
			call  => 'Kephra::Config::Localisation::open_file('."'".$lang_file."')",
			label => $lang,
			help  => "$fl_help $lang",
		});
		push @config_app_lang, 'item '.$al_lang_cmd;
		push @config_localisation, 'item '.$fl_lang_cmd;
	}
	Kephra::Menu::create_static('config_localisation',\@config_localisation);
	Kephra::Menu::create_static('config_app_lang',    \@config_app_lang);
}

sub refresh_index {
	my $use_cache = Kephra::Config::Interface::_config()->{cache}{use};
	my $index_file = Kephra::Config::filepath
		(Kephra::Config::Interface::_cache_sub_dir(), 'index_l18n.yml');
	my $l18n_dir = Kephra::Config::dirpath( _sub_dir() );

	my %old_index = %{ YAML::Tiny::LoadFile( $index_file ) } if -e $index_file;
	my %new_index;

	my ($FH, $file_name, $age, $line, $k, $v);
	$File::Find::prune = 1;
	File::Find::find( sub {
		# don't check directories
		return if -d $_; 
		$file_name = $_;
		$age = Kephra::File::IO::get_age($file_name);
		# if file is know and unrefreshed just copy loaded <about> data
		if (exists $old_index{$_} and $age == $old_index{$_}{age}) {
			$new_index{$file_name} = $old_index{$file_name};
			return;
		}
		open $FH, '<', $_ ;
		binmode($FH, ":raw:crlf");
		$line = <$FH>;
		chomp $line;
		if ($line =~ m|<about>|){
			while (<$FH>){
				chomp;
				last if $_ =~ m|</about>|;
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
	_index(\%new_index);
	\%new_index;
}

1;
