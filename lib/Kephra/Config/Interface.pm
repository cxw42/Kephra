package Kephra::Config::Interface;
our $VERSION = '0.04';

use strict;
use warnings;
 
# handling config files under config/interface

sub _sub_dir   { $Kephra::config{app}{app_data_sub_dir} }
sub _cache_sub_dir { 
	File::Spec->catdir( _sub_dir(), $Kephra::config{app}{cache}{sub_dir} )
}

sub load {
	#my $gui_store = $Kephra::temp{configfile};
	#my $gui_ref   = $Kephra::temp{config};
	#my $conf_path = $Kephra::temp{path}{config};
	Kephra::API::CommandList::clear_list();

	# localisation
	my $l = Kephra::Config::Localisation::load();
	$l = Kephra::Config::Default::localisation() unless $l and %$l;
	%Kephra::localisation = %$l;

	# commandlist
		# try du load from cache first
		# Kephra::CommandList::load_cache() if $conf->{commandlist}{cache}{use};
	my $cmd_list_def = Kephra::Config::File::load_from_node_data
		( Kephra::API::CommandList::_config() );
	unless ($cmd_list_def) {
		$cmd_list_def = Kephra::Config::Default::commandlist();
	}
	Kephra::API::CommandList::assemble_data($cmd_list_def);
	Kephra::API::CommandList::eval_data();
	undef $cmd_list_def;
}

sub del_temp_data {
	delete $Kephra::localisation{commandlist};
	delete $Kephra::localisation{key};

}

sub load_cache {}
sub store_cache {}


1;
