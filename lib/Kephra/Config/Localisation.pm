package Kephra::Config::Localisation;
our $VERSION = '0.03';

use strict;
use warnings;

use File::Find();
use YAML::Tiny();

# handling config files under config/localisation

sub _conf    { $Kephra::config{app}{localisation} }
sub _sub_dir { _conf()->{directory} }
sub _index   {
	if (ref $_[0] eq 'HASH') {$Kephra::temp{l18n}{index} = $_[0]}
	else                     {$Kephra::temp{l18n}{index}        }
}

sub set_file { file(@_) if @_ }
sub file {
	if (defined $_[0]) { _conf()->{file} = $_[0] }
	else               { _conf()->{file}         }
}

sub load {
	refresh_index();
	my $conf = _conf();
	my $index = _index();
	my $file = Kephra::Config::filepath( $conf->{directory}, $conf->{file} )
		if exists $conf->{directory} and exists $conf->{file};
	my $l = Kephra::Config::File::load( $file ) if defined $file;
	return $l if defined $l and %$l;
}

sub change_to {
	my ($lang) = shift;
	return unless $lang;
	set_documentation_lang( $lang );
	set_file( _index()->{$lang}{file_name} );
	Kephra::Config::Global::reload_tree();
}

# open localisation file in the editor
sub open_file {
	Kephra::Show::_open_config( 
		Kephra::Config::filepath( _conf()->{directory}, "$_[0]" )
	);
}

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
	my $l18n_index = _index();
	return unless $l18n_index;

	my (@config_app_lang, @config_localisation);
	for my $lang_code (sort keys %$l18n_index) {
		my $l18n = $Kephra::localisation{commandlist}{help}{config};
		my $al_help = $l18n->{'app-lang'};
		my $fl_help = $l18n->{file}{localisation};
		my $lang_data = $l18n_index->{$lang_code};
		my $lang = ucfirst $lang_data->{language};
		my $file = $lang_data->{file_name};
		my $al_cmd = 'config-app-lang-'.$lang_code;
		my $fl_cmd = 'config-file-localisation-'.$lang_code;
		Kephra::API::CommandList::new_cmd( $al_cmd, {
			call => 'Kephra::Config::Localisation::change_to('."'".$lang_code."')",
			state => 'Kephra::Config::Localisation::file() eq '."'".$file."'",
			label => $lang, 
			help => "$al_help $lang",
		});
		Kephra::API::CommandList::new_cmd( $fl_cmd, {
			call => 'Kephra::Config::Localisation::open_file('."'".$file."')",
			label => $lang,
			help => "$fl_help $lang",
		});
		push @config_app_lang, 'item '.$al_cmd;
		push @config_localisation, 'item '.$fl_cmd;
	}
	Kephra::App::Menu::create_static('config_localisation', \@config_localisation);
	Kephra::App::Menu::create_static('config_app_lang',     \@config_app_lang);
}

sub refresh_index {
	my $index_path = Kephra::Config::filepath
		(Kephra::Config::Interface::_cache_sub_dir(), 'l18n_index.yml');
	my $l18n_dir = Kephra::Config::dirpath( _sub_dir() );

	my %oldindex = %{ YAML::Tiny::LoadFile( $index_path ) } if -e $index_path;
	my %newindex;

	my ($FH, $file_name, $age, $line, $k, $v);
	$File::Find::prune = 1;
	File::Find::find( sub {
		#dont check directories
		return if -d $_; 
		$file_name = $_;
		$age = Kephra::File::IO::get_age($file_name);
		# if file is know and unrefreshed just copy loaded <about> data
		if (exists $oldindex{$_} and $age == $oldindex{$_}{age}) {
			$newindex{$file_name} = $oldindex{$file_name};
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
				$newindex{$file_name}{$k} = $1;
			}
		}
		$newindex{$file_name}{age} = $age;
		#if $newindex{$file_name}{purpose} eq 'global localisation'
	}, $l18n_dir);
	$File::Find::prune = 0;

	YAML::Tiny::DumpFile($index_path, \%newindex);

	# using now iso codes as indices
	for my $file (keys %newindex) {
		$newindex{$file}{file_name} = $file;
		$newindex{ $newindex{$file}{iso_code} } = $newindex{$file};
		delete $newindex{$file};
	}
	_index(\%newindex);
}

1;
