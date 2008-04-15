package Kephra::Config::Interface;
$VERSION = '0.03';
 
# handling config files under config/interface and config/localisation

use strict;

sub load_data {
	my $conf      = $Kephra::config{app};
	my $gui_store = $Kephra::temp{configfile};
	my $gui_ref   = $Kephra::temp{config};
	my $conf_path = $Kephra::temp{path}{config};

	# localisation
	my $l = Kephra::Config::File::load(
		Kephra::Config::filepath( 'localisation', $conf->{localisation_file} ),
	);
	unless ( $l and %$l ) {
		require Kephra::Config::Embedded;
		$l = Kephra::Config::Embedded::get_english_localisation();
	}
	%Kephra::localisation = %$l;

	# commandlist
	#Kephra::CommandList::load_cache() if $conf->{commandlist}{cache}{use};
	#Kephra::CommandList::load_data();
	Kephra::API::CommandList::assemble_data();
	#delete $Kephra::localisation {'commandlist'};

	#try du load from cache first
}

sub del_temp_data {
	
}

sub load_cache {}
sub store_cache {}

####################################
# lcalisation stuff
####################################

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

sub set_localisation_file {
	my $file = shift;
	return until $file;
	$Kephra::config{app}{localisation_file} = $file
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