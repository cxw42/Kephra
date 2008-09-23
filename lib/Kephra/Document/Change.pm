package Kephra::Document::Change;
our $VERSION = '0.06';

use strict;
use warnings;


# changing the current document


# set document with a given nr as current document
sub to_nr     { &to_number }
sub to_number {
	my $newtab = Kephra::Document::validate_nr(shift);;
	my $oldtab = Kephra::Document::current_nr();
	my $attr   = Kephra::Document::_attributes();

	if ($newtab != $oldtab and ref $attr->[$newtab] eq 'HASH') {
		Kephra::Document::Internal::save_properties($oldtab);
		Kephra::File::save_current() if $Kephra::config{file}{save}{change_doc};
		Kephra::Document::Internal::change_pointer($newtab);
		Kephra::App::TabBar::set_current_page($newtab);
		Kephra::Document::Internal::eval_properties($newtab);
		Kephra::App::Window::refresh_title();
		Kephra::Edit::_center_caret();
		Kephra::Document::Internal::previous_nr($oldtab);
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
sub switch_back { to_number( Kephra::Document::previous_nr() ) }

# change to the previous used document
sub tab_left {
	my $new_doc_nr = Kephra::Document::current_nr() - 1;
	$new_doc_nr = Kephra::Document::_get_last_nr() if $new_doc_nr == -1;
	to_number($new_doc_nr);
	$new_doc_nr;
}

sub tab_right {
	my $new_doc_nr = Kephra::Document::current_nr() + 1;
	$new_doc_nr = 0 if $new_doc_nr > Kephra::Document::get_last_nr();
	to_number($new_doc_nr);
	$new_doc_nr;
}


#########################################

sub move_left {
	my $old_nr = Kephra::Document::current_nr();
	my $new_nr = $old_nr - 1;
	if ($new_nr > -1) { switch($old_nr, $new_nr) }
	else { 
		$new_nr = Kephra::Document::get_last_nr();
		my $attr = Kephra::Document::_attributes();
		my $data = Kephra::Document::_temp_data();
		my $doc_a = shift @$attr;
		push @$attr, $doc_a;
		my $doc_d = shift @$data;
		push @$data, $doc_d;
		Kephra::Document::set_current_nr($new_nr);
		Kephra::App::TabBar::rot_tab_content('right');
		Kephra::App::TabBar::set_current_page($new_nr);
		Kephra::App::EditPanel::gets_focus();
		Kephra::API::EventTable::trigger('document.list');
	}
}

sub move_right {
	my $old_nr = Kephra::Document::current_nr(); 
	my $new_nr = $old_nr + 1;
	if ( $new_nr <= _Kephra::Document::get_last_nr() ) { switch($old_nr, $new_nr) }
	else {
		$new_nr = 0;
		my $attr = Kephra::Document::_attributes();
		my $data = Kephra::Document::_temp_data();
		my $doc_a = pop @$attr;
		unshift @$attr, $doc_a;
		my $doc_d = pop @$data;
		unshift @$data, $doc_d;
		Kephra::Document::_set_current_nr($new_nr);
		Kephra::App::TabBar::rot_tab_content('left');
		Kephra::App::TabBar::set_current_page($new_nr);
		Kephra::App::EditPanel::gets_focus();
		Kephra::API::EventTable::trigger('document.list');
	}
}

sub switch {
	my ($old_nr, $new_nr) = @_;
	return unless defined $new_nr;
	my $cur_nr = Kephra::Document::current_nr(); 
	my $attr = Kephra::Document::_attributes();
	my $data = Kephra::Document::_temp_data();
	($attr->[$old_nr], $attr->[$new_nr]) = ($attr->[$new_nr], $attr->[$old_nr]);
	($data->[$old_nr], $data->[$new_nr]) = ($data->[$new_nr], $data->[$old_nr]);
	Kephra::App::TabBar::switch_tab_content($old_nr, $new_nr);
	if ($cur_nr == $old_nr) {
		Kephra::Document::set_current_nr($new_nr);
		Kephra::App::TabBar::set_current_page($new_nr);
	} 
	elsif ($cur_nr == $new_nr) {
		Kephra::Document::set_current_nr($old_nr);
		Kephra::App::TabBar::set_current_page($old_nr);
	}
	Kephra::App::EditPanel::gets_focus();
	Kephra::API::EventTable::trigger('document.list');
}

1;
