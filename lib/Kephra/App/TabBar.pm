package Kephra::App::TabBar;    # notebook file selector
use strict;
use warnings;

our $VERSION = '0.12';

=pod
Tabbar is the visual element in top area of the main window which displays
       end enables selection between all curently opened documents
=cut

use Wx qw(
	wxTOP wxLEFT wxRIGHT wxHORIZONTAL wxVERTICAL wxALIGN_CENTER_VERTICAL
	wxGROW wxLI_HORIZONTAL wxTAB_TRAVERSAL
	wxBU_AUTODRAW wxNO_BORDER wxWHITE
);
use Wx::Event qw(
	EVT_LEFT_UP EVT_LEFT_DOWN EVT_MIDDLE_UP EVT_BUTTON
	EVT_ENTER_WINDOW EVT_LEAVE_WINDOW EVT_NOTEBOOK_PAGE_CHANGED
);

sub _ref { 
	if (ref $_[0] eq 'Wx::Panel') { $Kephra::app{window}{tabbar}{panel} = $_[0] }
	else                          { $Kephra::app{window}{tabbar}{panel} } 
}
sub _tabs { 
	if (ref $_[0] eq 'Wx::Notebook') { $Kephra::app{window}{tabbar}{tabs} = $_[0] }
	else                             { $Kephra::app{window}{tabbar}{tabs} } 
}
sub _compound { $Kephra::app{window}{tabbar} }
sub _config   { $Kephra::config{app}{tabbar} }

sub create {
	my $win = Kephra::App::Window::_ref();
	my $tb_panel = Wx::Panel->new($win, -1);

	# create notebook if there is none
	unless (_tabs()) {
		_tabs( Wx::Notebook->new( $tb_panel, -1, [0,0], [-1,23]) );
		add_tab();
	}
	my $tabbar = _compound();
	my $tabbar_h_sizer = $tabbar->{h_sizer} = Wx::BoxSizer->new(wxHORIZONTAL);
	$tabbar_h_sizer->Add( $tabbar->{tabs} , 1, wxLEFT | wxGROW, 0 );
	my $bg_colour = $tabbar->{tabs}->GetBackgroundColour();

	$tabbar->{seperator_line} = Wx::StaticLine->new
		($tb_panel, -1, [-1,-1],[-1,2], wxLI_HORIZONTAL);
	$tabbar->{seperator_line}->SetBackgroundColour(wxWHITE);

	# create icons above panels
	my $cmd_new_data = Kephra::API::CommandList::get_cmd_properties('file-new');
	if (ref $cmd_new_data->{icon} eq 'Wx::Bitmap'){
		my $new_btn = $tabbar->{button}{new} = Wx::BitmapButton->new
			($tb_panel, -1, $cmd_new_data->{icon}, [-1,-1], [-1,-1], wxNO_BORDER );
		$new_btn->SetToolTip( $cmd_new_data->{label} );
		$new_btn->SetBackgroundColour( $bg_colour );
		$tabbar_h_sizer->Prepend($new_btn, 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 2);
		EVT_BUTTON($tb_panel, $new_btn, $cmd_new_data->{call} );
		EVT_ENTER_WINDOW( $new_btn, sub {
			Kephra::App::StatusBar::info_msg( $cmd_new_data->{help} )
		});
		EVT_LEAVE_WINDOW( $new_btn, \&Kephra::App::StatusBar::refresh_info_msg );
	}

	my $cmd_close_data = Kephra::API::CommandList::get_cmd_properties('file-close-current');
	if (ref $cmd_close_data->{icon} eq 'Wx::Bitmap'){
		my $close_btn = $tabbar->{button}{close} = Wx::BitmapButton->new
			($tb_panel, -1, $cmd_close_data->{icon}, [-1,-1], [-1,-1], wxNO_BORDER );
		$close_btn->SetToolTip( $cmd_close_data->{label} );
		$close_btn->SetBackgroundColour( $bg_colour );
		$tabbar_h_sizer->Add($close_btn, 0, wxRIGHT|wxALIGN_CENTER_VERTICAL, 2);
		EVT_BUTTON($tb_panel, $close_btn, $cmd_close_data->{call});
		EVT_ENTER_WINDOW($close_btn, sub {
			Kephra::App::StatusBar::info_msg( $cmd_close_data->{help} )
		});
		EVT_LEAVE_WINDOW( $close_btn, \&Kephra::App::StatusBar::refresh_info_msg );
	}

	EVT_LEFT_UP(   $tabbar->{tabs}, \&left_off_tabs);
	EVT_LEFT_DOWN( $tabbar->{tabs}, \&left_on_tabs);
	# Optional middle click over the tabs
	if ( _config()->{middle_click} ) {
		EVT_MIDDLE_UP(
			$tabbar->{tabs},
			Kephra::API::CommandList::get_cmd_property
				( _config()->{middle_click}, 'call' )
		);
	}
	EVT_NOTEBOOK_PAGE_CHANGED( $tb_panel, $tabbar->{tabs}, \&change_tab);

	# assemble tabbar seperator line
	my $tabbar_v_sizer = $tabbar->{v_sizer} = Wx::BoxSizer->new(wxVERTICAL);
	$tabbar_v_sizer->Add( $tabbar->{seperator_line}, 0, wxTOP | wxGROW , 0 );
	$tabbar_v_sizer->Add( $tabbar_h_sizer          , 1, wxTOP | wxGROW , 0 );
	refresh_layout();

	$tb_panel->SetSizer($tabbar_v_sizer);
	$tb_panel->SetAutoLayout(1);
	$tb_panel->Layout;
	_ref($tb_panel);
}

sub left_on_tabs {
	my ($tabs, $event) = @_;
	$Kephra::temp{document}{b4tabchange} = $tabs->GetSelection;
	$event->Skip;
}
sub left_off_tabs {
	my ($tabs, $event) = @_;
	Kephra::Document::Change::switch_back()
		if $Kephra::temp{document}{b4tabchange} == $tabs->GetSelection;
	$event->Skip;
}

##################################
# tab functions
##################################
sub add_tab {
	my $tabs = _tabs();
	$tabs->AddPage( Wx::Panel->new( $tabs, -1, [ -1, -1 ], [ -1, 0 ] ), '', 0 );
}

sub switch_tab_content {
	my ($old_nr, $new_nr) = @_;
	return unless defined $new_nr;
	my $tabs = _tabs();
	my $text = $tabs->GetPageText($new_nr);
	$tabs->SetPageText($new_nr, $tabs->GetPageText($old_nr) );
	$tabs->SetPageText($old_nr, $text );
}

sub rot_tab_content {
	my $dir = shift;
	my $tabs = _tabs();
	my $max = $tabs->GetPageCount() - 1;
	if ($dir eq 'left'){
		my $text = $tabs->GetPageText($max);
		$tabs->SetPageText($_, $tabs->GetPageText($_-1)) for reverse 1 .. $max;
		$tabs->SetPageText(0, $text);
	}
	elsif ($dir eq 'right'){
		my $text = $tabs->GetPageText(0);
		$tabs->SetPageText($_, $tabs->GetPageText($_+1)) for 0 .. $max - 1;
		$tabs->SetPageText($max, $text);
	}
}

sub change_tab {
	my ( $frame, $event ) = @_;
	Kephra::Document::Change::to_number( $event->GetSelection );
	$event->Skip;
}
sub delete_tab { _tabs()->DeletePage(shift) }
sub set_current_page {
	my $nr = shift;
	my $tabs = _tabs();
	$tabs->SetSelection($nr) unless $nr == $tabs->GetSelection;
}

# refresh the label of given number
sub refresh_label {
	my $doc_nr = shift;
	$doc_nr = Kephra::Document::current_nr() unless defined $doc_nr;
	return unless defined $Kephra::temp{document}{open}[$doc_nr];

	my $config   = _config();
	my $doc_info = $Kephra::temp{document}{open}[$doc_nr];
	my $untitled = Kephra::Config::Localisation::strings()->{app}{general}{untitled};
	my $label    = $doc_info->{ $config->{file_info} } || "<$untitled>";

	# shorten too long filenames
	my $max_width = $config->{max_tab_width};
	if ( length($label) > $max_width and $max_width > 7 ) {
		$label = substr( $label, 0, $max_width - 3 ) . '...';
	}
	# set config files in square brackets
	if (    $config->{mark_configs}
		and Kephra::Document::Internal::get_attribute('config_file', $doc_nr)
		and $Kephra::config{file}{save}{reload_config}              ) {
		$label = '$ ' . $label;
	}
	$label = ( $doc_nr + 1 ) . " $label" if $config->{number_tabs};
	$doc_info->{label} = $label;
	if ( $config->{info_symbol} ) {
		$label .= ' #' if $doc_info->{readonly};
		$label .= ' *' if $doc_info->{modified};
	}
	_tabs()->SetPageText( $doc_nr, $label );
}

sub refresh_current_label{ refresh_label(Kephra::Document::current_nr()) }

sub refresh_all_label {
	if ( $Kephra::temp{document}{loaded} ) {
		refresh_label($_) for @{ Kephra::Document::all_nr() };
		set_current_page( Kephra::Document::current_nr() );
	}
}

# set tabbar visibility
sub get_visibility { _config()->{visible} }
sub switch_visibility {
	_config()->{visible} ^= 1;
	show();
}
sub show {
	my $visible = shift || get_visibility();
	my $panel = _ref();
	my $sizer = $panel->GetParent->GetSizer;
	refresh_layout();
	$sizer->Show( $panel, $visible );
	$sizer->Layout();
	#Kephra::App::Window::_ref()->Layout();
	_config()->{visible} = $visible;
}

# visibility of parts
sub refresh_layout{
 my $tabbar     = _compound();
 my $tab_config = _config();
 my $v          = $tab_config->{visible};
	if ($tabbar->{seperator_line}) {
		$tabbar->{seperator_line}->Show( $v && $tab_config->{seperator_line});
	}
	if ($tabbar->{button}{new}   ) {
		$tabbar->{button}{new}   ->Show( $v && $tab_config->{button}{new}   );
	}
	if ($tabbar->{button}{close} ) {
		$tabbar->{button}{close} ->Show( $v && $tab_config->{button}{close} );
	}
}

sub switch_contextmenu_visibility { 
	_config()->{contextmenu_use} ^= 1;
	Kephra::App::ContextMenu::connect_tabbar();
}
sub get_contextmenu_visibility { _config()->{contextmenu_use} }

1;
