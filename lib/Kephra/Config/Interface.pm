package Kephra::Config::Interface;
$VERSION = '0.03';
 
# handling config files under config/interface and config/localisation

use strict;

sub load {
	my $conf      = $Kephra::config{app};
	#my $gui_store = $Kephra::temp{configfile};
	#my $gui_ref   = $Kephra::temp{config};
	#my $conf_path = $Kephra::temp{path}{config};

	# localisation
	my $l = Kephra::Config::File::load(
		Kephra::Config::filepath( 'localisation', $conf->{localisation_file} ),
	);
	unless ( $l and %$l ) {
		require Kephra::Config::Embedded;
		$l = Kephra::Config::Embedded::english_localisation();
	}
	%Kephra::localisation = %$l;

	# commandlist
		# try du load from cache first
		# Kephra::CommandList::load_cache() if $conf->{commandlist}{cache}{use};
	my $cmd_list_def = Kephra::Config::File::load_from_config_node_data
		( Kephra::API::CommandList::_config() );
	unless ($cmd_list_def) {
		require Kephra::Config::Embedded;
		$cmd_list_def = Kephra::Config::Embedded::commandlist();
	}
	Kephra::API::CommandList::assemble_data($cmd_list_def);
	Kephra::API::CommandList::eval_data();
	undef $cmd_list_def;
	delete $Kephra::localisation{commandlist};
	delete $Kephra::localisation{key};
}

sub del_temp_data {}

sub load_cache {}
sub store_cache {}

####################################
# lcalisation stuff
####################################

#my %lang_map = ();

sub set_lang_2_cesky_utf   { change_localisation('cesky',  'utf') }
sub set_lang_2_cesky_iso   { change_localisation('cesky',  'iso') }
sub set_lang_2_deutsch_utf { change_localisation('deutsch','utf') }
sub set_lang_2_deutsch_iso { change_localisation('deutsch','iso') }
sub set_lang_2_deutsch     { change_localisation('deutsch') }
sub set_lang_2_english     { change_localisation('english') }

sub change_localisation {
	my ($lang, $charset) = @_;
	return unless $lang;
	set_documentation_lang( $lang );
	$lang .= "_$charset" if $charset;
	set_localisation_file( $lang.'.conf');
	Kephra::Config::Global::reload_tree();
}

sub localisation_file {
	my $file = shift;
	if (defined $file) {
		$Kephra::config{app}{localisation_file} = $file
	} else {
		$Kephra::config{app}{localisation_file};
	}
}

sub set_documentation_lang {
	my $lang = shift;
	return until $lang;
	if ( $lang eq 'english'
	  or $lang eq 'deutsch'
	  or $lang eq 'cesky') {
		my $sb = Kephra::Config::Global::_conf_sub_path();
		my $file = Kephra::Config::filepath
			( $sb, 'sub/documentation', $lang.'.conf' );
		Kephra::Config::Global::merge_tree( Kephra::Config::File::load($file) );
	}
}

1;