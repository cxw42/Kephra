package Kephra::Config::Interface;
our $VERSION = '0.03';

use strict;
use warnings;
 
# handling config files under config/interface and config/localisation
sub _loc_conf { $Kephra::config{app}{localisation} }

sub load {
	#my $gui_store = $Kephra::temp{configfile};
	#my $gui_ref   = $Kephra::temp{config};
	#my $conf_path = $Kephra::temp{path}{config};

	# localisation
	my $l_conf = _loc_conf();
	my $l_file = Kephra::Config::filepath( $l_conf->{directory}, $l_conf->{file} )
		if exists $l_conf->{directory} and exists $l_conf->{file};
	my $l = Kephra::Config::File::load( $l_file ) if defined $l_file;
	unless ( $l and %$l ) {
		$l = Kephra::Config::Default::localisation();
	}
	%Kephra::localisation = %$l;

	# commandlist
		# try du load from cache first
		# Kephra::CommandList::load_cache() if $conf->{commandlist}{cache}{use};
	my $cmd_list_def = Kephra::Config::File::load_from_config_node_data
		( Kephra::API::CommandList::_config() );
	unless ($cmd_list_def) {
		$cmd_list_def = Kephra::Config::Default::commandlist();
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
	if (defined $file) { _loc_conf()->{file} = $file }
	else               { _loc_conf()->{file}         }
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
