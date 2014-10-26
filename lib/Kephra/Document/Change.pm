package Kephra::Document::Change;
our $VERSION = '0.06';

use strict;
use warnings;


# changing the current document


# set document with a given nr as current document
sub to_nr     { &to_number }
sub to_number {
	my $newtab = shift;
	my $oldtab = Kephra::Document::_get_current_nr();

	if ($newtab != $oldtab and ref $Kephra::document{open}[$newtab] eq 'HASH') {
		Kephra::Document::Internal::save_properties($oldtab);
		Kephra::File::save_current() if $Kephra::config{file}{save}{change_doc};
		Kephra::Document::Internal::change_pointer($newtab);
		Kephra::App::TabBar::set_current_page($newtab);
		Kephra::Document::Internal::eval_properties($newtab);
		Kephra::App::Window::refresh_title();
		Kephra::Edit::_center_caret();
		Kephra::Document::_set_previous_nr($oldtab);
		Kephra::API::EventTable::trigger( qw(
			document.current.number.changed'
			document.savepoint
			document.text.change
			document.text.select
		) );
		return 1;
	}
	return 0;
}

#sub to_path{} # planing

# change to the previous used document
sub switch_back { to_number( $Kephra::document{previous_nr} ) }

# change to the previous used document
sub tab_left {
	my $new_doc_nr = Kephra::Document::current_nr() - 1;
	$new_doc_nr = Kephra::Document::_get_last_nr() if $new_doc_nr == -1;
	to_number($new_doc_nr);
	$new_doc_nr;
}

sub tab_right {
	my $new_doc_nr = Kephra::Document::current_nr() + 1;
	$new_doc_nr = 0 if $new_doc_nr > Kephra::Document::_get_last_nr();
	to_number($new_doc_nr);
	$new_doc_nr;
}

1;
