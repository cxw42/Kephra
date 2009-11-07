package Kephra::Document::Change;
our $VERSION = '0.07';

use strict;
use warnings;
#
# changing the current document
#
# set document with a given nr as current document
sub to_nr     { to_number(@_) }
sub to_number {
	my $newtab = Kephra::Document::Data::validate_doc_nr(shift);
	my $oldtab = Kephra::Document::Data::current_nr();

	if ($newtab != $oldtab and $newtab > -1) {
#print " change $oldtab to_number $newtab\n";
		Kephra::Document::Data::update_attributes($oldtab);
		Kephra::File::save_current() if $Kephra::config{file}{save}{change_doc};
		Kephra::Document::Data::set_current_nr($newtab);
		Kephra::Document::Data::set_previous_nr($oldtab);
		Kephra::App::Window::refresh_title();
		Kephra::App::TabBar::raise_tab_by_doc_nr($newtab);
		Kephra::App::StatusBar::refresh_all_cells();
		Kephra::API::EventTable::trigger_group( 'doc_change' );
		Kephra::App::EditPanel::gets_focus();
		return 1;
	} else { #print "not changed\n"
	}
	return 0;
}
#sub to_path{} # planing
# change to the previous used document
sub switch_back { to_number( Kephra::Document::Data::previous_nr() ) }
# change to the previous used document
sub tab_left  { Kephra::App::TabBar::raise_tab_left() }
sub tab_right { Kephra::App::TabBar::raise_tab_right() }
#########################################
sub move_left { Kephra::App::TabBar::rotate_tab_left();
		#Kephra::API::EventTable::trigger('document.list');
}
sub move_right { Kephra::App::TabBar::rotate_tab_right();
		#Kephra::API::EventTable::trigger('document.list');
}

1;
