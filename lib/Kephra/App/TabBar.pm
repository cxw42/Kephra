package Kephra::App::TabBar;
our $VERSION = '0.17';
=pod

Tabbar is the visual element in top area of the main window which displays
       end enables selection between all curently opened documents
       
       this module manages the tab position handling because the nr of document
       might be different from its postition in the tabbar
=cut

use strict;
use warnings;
use Wx qw( 
	wxVERTICAL wxGROW
	wxAUI_NB_TOP wxAUI_NB_WINDOWLIST_BUTTON wxAUI_NB_TAB_MOVE
	wxAUI_NB_CLOSE_BUTTON wxAUI_NB_CLOSE_ON_ACTIVE_TAB wxAUI_NB_SCROLL_BUTTONS
);

#
# internal data
#
my @tab_order; # doc numbers in tab order
my @doc_order; # tab numbers in doc order
sub _update_doc_pos  { $doc_order[ $tab_order[$_] ] = $_ for 0 .. $#tab_order }
sub _validate_doc_nr { &Kephra::Document::Data::validate_doc_nr }
sub doc2tab_pos {
	my $nr = _validate_doc_nr(shift);
	return $nr == -1 ? -1 : $doc_order[$nr];
}
sub tab2doc_pos {
	my $nr = _validate_doc_nr(shift);
	return $nr == -1 ? -1 : $tab_order[$nr];
}
sub move_tab {
	my $from = _validate_doc_nr(shift);
	my $to = _validate_doc_nr(shift);
	return if $from == -1 or $to == -1;
	my $doc_nr = splice @tab_order, $from, 1;
	splice @tab_order, $to, 0, $doc_nr;
	_update_doc_pos(); #print "taborder: @tab_order, doc_order: @doc_order\n";
#print $notebook->GetPageIndex( Kephra::Document::Data::_ep($_) )."\n" for @{Kephra::Document::Data::all_nr()};
}
my $notebook;
sub _ref    { $notebook = ref $_[0] eq 'Wx::AuiNotebook' ? $_[0] : $notebook }
sub _config { $Kephra::config{app}{tabbar} }
my $tabmove;
#
# basic toolbar creation
#
sub create {
	# create notebook if there is none
	my $notebook = _ref();
	$notebook->Destroy if defined $notebook;
	$notebook = Wx::AuiNotebook->new
		(Kephra::App::Window::_ref(),-1, [0,0], [-1,23],
		wxAUI_NB_TOP | wxAUI_NB_SCROLL_BUTTONS);
	_ref($notebook);
	Wx::Event::EVT_LEFT_UP( $notebook, sub {
		my ($tabs, $event) = @_; print "\n left up\n";
		Kephra::Document::Data::set_value('b4tabchange', $tabs->GetSelection);
		#Kephra::App::EditPanel::gets_focus();
		$event->Skip;
	});
	Wx::Event::EVT_LEFT_DOWN( $notebook, sub {
		my ($tabs, $event) = @_; print "\n left down\n";
		Kephra::Document::Change::switch_back()
			if Kephra::Document::Data::get_value('b4tabchange')==$tabs->GetSelection;
		Kephra::App::EditPanel::gets_focus();
		$event->Skip;
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CLOSE( $notebook, -1, sub {
		my ( $bar, $event ) = @_;
		if($bar->GetPageCount == 1) { Kephra::Document::reset(0) }
		else                        { delete_tab($event->GetSelection) }
		$event->Veto;
	});
	Wx::Event::EVT_AUINOTEBOOK_PAGE_CHANGED( $notebook, -1, sub {
		my ( $bar, $event ) = @_;
my $nr = $event->GetSelection;
my $oldnr = $event->GetOldSelection;
#print "=begin change page $oldnr -> $nr\n";
		#print "=end change page $nr\n";
		Kephra::Document::Change::to_number
			( $event->GetSelection, $event->GetOldSelection) unless $tabmove;
		Kephra::App::EditPanel::gets_focus();
		$tabmove = 0;
		$event->Skip;
	});
	my $begin_drag_index;
	Wx::Event::EVT_AUINOTEBOOK_BEGIN_DRAG($notebook, -1, sub {
		$begin_drag_index = $_[1]->GetSelection;
	});	
	Wx::Event::EVT_AUINOTEBOOK_END_DRAG($notebook, -1, sub {
		move_tab($begin_drag_index, $_[1]->GetSelection);
		Kephra::App::EditPanel::gets_focus();
	});
}

sub apply_settings {
	my $notebook = _ref();
	# Optional middle click over the tabs
	if ( _config()->{middle_click} ) {
		Wx::Event::EVT_MIDDLE_UP(
			$notebook,
			Kephra::API::CommandList::get_cmd_property
				( _config()->{middle_click}, 'call' )
		);
	}
	my $style = $notebook->GetWindowStyleFlag();
	$style |= wxAUI_NB_TAB_MOVE if _config->{movable_tabs};
	$style |= wxAUI_NB_WINDOWLIST_BUTTON if _config->{tablist_button};
	if (_config->{close_button} eq 'all'){ $style |= wxAUI_NB_CLOSE_BUTTON }
	elsif (_config->{close_button})   { $style |= wxAUI_NB_CLOSE_ON_ACTIVE_TAB }
	$notebook->SetWindowStyle( $style );
	# wxAUI_NB_TAB_SPLIT wxAUI_NB_TAB_EXTERNAL_MOVE contextmenu_use, insert
}
#
# tab functions
#
sub add_edit_tab  {
	my $doc_nr = shift || Kephra::Document::Data::current_nr();
	my $notebook = _ref();
	#$notebook->Freeze();

#$nr = 0             if $nr eq 'leftmost';
#$nr = $current_nr   if $nr eq 'left';
#$nr = $current_nr+1 if $nr eq 'right';
#$nr = last_nr()+1   if $nr eq 'rightmost';
	#my $panel = Wx::Panel->new( $notebook, -1);
	my $stc = Kephra::App::EditPanel::new();
	Kephra::Document::Data::set_attribute('ref', $stc, $doc_nr);
	#$stc->Reparent($panel);
	#my $sizer = Wx::BoxSizer->new( wxVERTICAL );
	#$sizer->Add( $stc, 1, wxGROW, 0);
	#$panel->SetSizer($sizer);
	#$panel->SetAutoLayout(1);
	$notebook->AddPage( $stc, '', 0 );
	push @tab_order, $doc_nr;
	_update_doc_pos();
	#$notebook->Thaw();
	return $stc;
}

sub add_panel_tab {
	my $doc_nr = shift || Kephra::Document::Data::current_nr();
	my $panel = shift;
	return unless defined $panel and substr(ref $panel, 0, 4) eq 'Wx::';
	$panel->Reparent($notebook);
	$notebook->AddPage( $panel, '', 0 );
	return $panel;
}
sub raise_tab     { # tab selection
	my ( $frame, $event ) = @_;
	my $nr = $event->GetSelection;
	Kephra::Document::Change::to_number( $nr, $event->GetOldSelection);
	Wx::Window::SetFocus( $notebook->GetPage($nr) );
	Kephra::App::EditPanel::gets_focus();
	$event->Skip;
}
sub raise_tab_by_tab_nr { raise_tab_by_doc_nr( tab2doc_pos(shift) ) }
sub raise_tab_by_doc_nr {
	my $nr = shift;
	$notebook->SetSelection($nr) unless $nr == $notebook->GetSelection;
}

sub raise_tab_left {
	my $nr = doc2tab_pos( Kephra::Document::Data::current_nr() );
	raise_tab_by_tab_nr( Kephra::Document::Data::next_nr(-1, $nr) );
}
sub raise_tab_right {
	my $nr = doc2tab_pos( Kephra::Document::Data::current_nr() );
	raise_tab_by_tab_nr( Kephra::Document::Data::next_nr(1, $nr) );
}
sub rotate_tab_left {
	
}

sub rotate_tab_right {
	my $old_tab_nr = doc2tab_pos( Kephra::Document::Data::current_nr() );
	my $new_tab_nr = Kephra::Document::Data::next_nr(1, $old_tab_nr);
	my $notebook = _ref();
	my $label = $notebook->GetPageText( $old_tab_nr );
	my $stc = Kephra::Document::Data::get_attribute('ref');
	move_tab( $old_tab_nr, $new_tab_nr );
	$notebook->RemovePage( $old_tab_nr );
	$tabmove = 1;
print "between";
	$notebook->InsertPage( $new_tab_nr, $stc, $label, 1 );
#print "rot $old_tab_nr -> $new_tab_nr || ".$notebook->GetSelection." \n";
}

sub switch_tab_content {
	my ($old_nr, $new_nr) = @_;
	return unless defined $new_nr;
	my $text = $notebook->GetPageText($new_nr);
	$notebook->SetPageText($new_nr, $notebook->GetPageText($old_nr) );
	$notebook->SetPageText($old_nr, $text );
}

sub rot_tab_content {
	my $dir = shift;
	my $max = $notebook->GetPageCount() - 1;
	if ($dir eq 'left'){
		my $text = $notebook->GetPageText($max);
		$notebook->SetPageText($_, $notebook->GetPageText($_-1)) 
			for reverse 1 .. $max;
		$notebook->SetPageText(0, $text);
	}
	elsif ($dir eq 'right'){
		my $text = $notebook->GetPageText(0);
		$notebook->SetPageText($_, $notebook->GetPageText($_+1)) 
			for 0 .. $max - 1;
		$notebook->SetPageText($max, $text);
	}
}
sub delete_tab { 
	my $nr = shift;
print "delete tab";
	my $xw = Kephra::Document::Data::_ep($nr);
#print $notebook->GetSelection."current, del tab nr $nr\n";
	$notebook->RemovePage($nr);#DeletePage,RemovePage
	#$xw->Reparent( undef );
	#$xw->Destroy();
}
#
# refresh the label of given number
#
sub refresh_label {
	my $doc_nr = shift;
	$doc_nr = Kephra::Document::Data::current_nr() unless defined $doc_nr;
	return unless _validate_doc_nr($doc_nr) > -1;

	my $config   = _config();
	my $untitled = Kephra::Config::Localisation::strings()->{app}{general}{untitled};
	my $label    = Kephra::Document::Data::get_attribute
					( $config->{file_info} ) || "<$untitled>";

	# shorten too long filenames
	my $max_width = $config->{max_tab_width};
	if ( length($label) > $max_width and $max_width > 7 ) {
		$label = substr( $label, 0, $max_width - 3 ) . '...';
	}
	# set config files in square brackets
	if (    $config->{mark_configs}
		and Kephra::Document::Data::get_attribute('config_file', $doc_nr)
		and $Kephra::config{file}{save}{reload_config}              ) {
		$label = '$ ' . $label;
	}
	$label = ( $doc_nr + 1 ) . " $label" if $config->{number_tabs};
	Kephra::Document::Data::set_attribute('label', $label);
	if ( $config->{info_symbol} ) {
		$label .= ' #' if Kephra::Document::Data::get_attribute('editable');
		$label .= ' *' if Kephra::Document::Data::get_attribute('modified');
	}
	$notebook->SetPageText( $doc_nr, $label );
}

sub refresh_current_label{ refresh_label(Kephra::Document::Data::current_nr()) }
sub refresh_all_label {
	if ( Kephra::Document::Data::get_value('loaded') ) {
		refresh_label($_) for @{ Kephra::Document::Data::all_nr() };
		raise_tab_by_doc_nr( Kephra::Document::Data::current_nr() );
	}
}

#
# set tabbar visibility
#
sub switch_contextmenu_visibility { 
	_config()->{contextmenu_use} ^= 1;
	Kephra::App::ContextMenu::connect_tabbar();
}
sub get_contextmenu_visibility { _config()->{contextmenu_use} }

1;
