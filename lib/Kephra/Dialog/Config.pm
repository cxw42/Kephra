package Kephra::Dialog::Config;
$VERSION = '0.17';

use strict;
use Wx qw( 
	wxVERTICAL wxHORIZONTAL wxLEFT wxRIGHT wxTOP wxALL wxBOTTOM
	wxGROW wxEXPAND wxALIGN_CENTRE wxALIGN_RIGHT
	wxSYSTEM_MENU wxCAPTION wxSTAY_ON_TOP wxNO_FULL_REPAINT_ON_RESIZE
	wxSIMPLE_BORDER wxRAISED_BORDER
	wxBK_LEFT
	wxCLOSE_BOX wxMINIMIZE_BOX  wxFRAME_NO_TASKBAR  wxBITMAP_TYPE_XPM  wxWHITE
	wxTR_NO_BUTTONS wxTR_HIDE_ROOT wxTR_SINGLE
	wxNOT_FOUND
);

use Wx::Event
	qw(EVT_KEY_DOWN EVT_TEXT EVT_BUTTON EVT_CHECKBOX EVT_RADIOBUTTON EVT_CLOSE);

sub _ref {
	if (ref $_[0] eq 'Wx::MiniFrame'){ $Kephra::app{dialog}{config} = $_[0] }
	else                             { $Kephra::app{dialog}{config} }
}

sub main {
	if ( !$Kephra::temp{dialog}{config}{active}
	or    $Kephra::temp{dialog}{config}{active} == 0 ) {

		# init search and replace dialog
		$Kephra::temp{dialog}{config}{active} = 1;
		my $frame  = Kephra::App::Window::_ref();
		my $config = $Kephra::config{dialog}{config};
		my $d_l10n = $Kephra::localisation{dialog}{settings};
		my $g_l10n = $Kephra::localisation{dialog}{general};
		my $m_l10n = $Kephra::localisation{app}{menu};
		my $cl_l10n= $Kephra::localisation{commandlist}{label};
		my $d_style= wxNO_FULL_REPAINT_ON_RESIZE | wxSYSTEM_MENU | wxCAPTION
			| wxMINIMIZE_BOX | wxCLOSE_BOX;
		#$d_style |= wxSTAY_ON_TOP if $Kephra::config{app}{window}{stay_on_top};

		# making window & main design
		my $d = Wx::MiniFrame->new( $frame, -1, ' '.$d_l10n->{title},
			[ $config->{position_x}, $config->{position_y} ], [ 470, 560 ],
			$d_style);
		my $icon_bmp = Kephra::API::CommandList::get_cmd_property
			('view-dialog-config', 'icon');
		my $icon = Wx::Icon->new;
		$icon->CopyFromBitmap($icon_bmp) if ref $icon_bmp eq 'Wx::Bitmap';
		$d->SetIcon($icon);
		_ref($d);

		# main panel
		my $mpanel = Wx::Panel->new( $d, -1, [-1,-1], [-1,-1] );
		#my $config_menu = Wx::Panel->new( $mpanel, -1, [10, 10], [106, 362]);
		# construction left main menu
		#$config_menu->SetBackgroundColour(wxWHITE);
		#my $menu_border = Wx::StaticBox->new( $mpanel, -1, '', 
		#	[10, 4], [110, 370], wxSIMPLE_BORDER | wxRAISED_BORDER );
		# tree of categories
		my $cfg_tree = Wx::Treebook->new( $mpanel, -1, [-1,-1], [-1,-1], wxBK_LEFT);
		my $panel;
		$panel->{general} = Wx::Panel->new( $cfg_tree, -1, [-1,-1], [-1,-1] );
		$panel->{general}->SetSizer(Wx::BoxSizer->new(wxVERTICAL));
		$cfg_tree->AddPage( $panel->{general}, 'General', 1);
		$panel->{Interface} = $cfg_tree->AddPage( undef, 'Interface', 1);
		$panel->{file} = $cfg_tree->AddPage( undef, 'File', 1);
		$cfg_tree->AddSubPage( undef, 'Defaults', 1);
		$cfg_tree->AddSubPage( undef, 'Save', 1);
		$cfg_tree->AddSubPage( undef, 'Endings', 1);
		$cfg_tree->AddSubPage( undef, 'Session', 1);
		$panel->{editpanel} = $cfg_tree->AddPage( undef, 'Editpanel', 1);
		#print "-".wxNOT_FOUND."$npanel \n";

		#my $page = $cat_tree->AddPage( $npanel, "Allgemein", 0, -1);
			#wxTR_NO_BUTTONS | wxTR_HIDE_ROOT | wxTR_SINGLE );
		#my $root_id = $cat_tree->AddRoot('invisible', -1, -1 );
		#my $fid = $cat_tree->AppendItem( $root_id, $m_l10n->{file},-1,-1);
		#my $vid = $cat_tree->AppendItem( $root_id, $m_l10n->{view},-1,-1);
#print "rid: $rid, fid: $fid\n";
#$cat_tree->Expand( $cat_tree->AppendItem( $fid, 'neu', -1,-1, td(undef)) );
		#$cat_tree->AppendItem( $fid, 'Neu',  -1,-1, );
		#$cat_tree->AppendItem( $fid, 'Öffnen', -1,-1, );
		#$cat_tree->AppendItem( $fid, 'Speichern',  -1,-1, );
		#$cat_tree->AppendItem( $fid, 'Endungen',  -1,-1, );
		#$cat_tree->Expand( $root_id );
		#$cat_tree->Expand( $fid );

		# panels with config controls
		#my $file_open_panel = Wx::Panel->new( $mpanel, -1, [400, 10], [276, 362]);
		#my $file_save_panel = Wx::Panel->new( $mpanel, -1, [400, 10], [276, 362]);


		# button line
		$d->{apply_button} = Wx::Button->new( $mpanel,-1,$g_l10n->{apply}, [-1,-1], [-1,-1] );
		$d->{cancel_button} = Wx::Button->new( $mpanel,-1,$g_l10n->{cancel},[-1,-1], [-1,-1] );
		my $button_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
		$button_sizer->Add( $d->{apply_button},  0, wxRIGHT, 14 );
		$button_sizer->Add( $d->{cancel_button}, 0, wxRIGHT, 22 );


		# assembling lines
		my $d_sizer = Wx::BoxSizer->new(wxVERTICAL);
		$d_sizer->Add( $cfg_tree,     1, wxEXPAND|wxALL,   14);
		$d_sizer->Add( $button_sizer, 0, wxBOTTOM|wxALIGN_RIGHT, 12);

		# release
		$mpanel->SetSizer($d_sizer);
		$mpanel->SetAutoLayout(1);
		#$cfg_tree->Fit();
		$d->Show(1);
		Wx::Window::SetFocus( $d->{cancel_button} );

		# events
		EVT_BUTTON( $d, $d->{apply_button}, sub {shift->Close} );
		EVT_BUTTON( $d, $d->{cancel_button},sub {shift->Close} );
		EVT_CLOSE( $d, \&quit_config_dialog );

	} else {
		my $d = _ref();
		$d->Iconize(0);
		$d->Raise;
	}
}

# helper
sub td { Wx::TreeItemData->new( $_[0] ) }

sub quit_config_dialog {
	my ( $win, $event ) = @_;
	my $config = $Kephra::config{dialog}{config};
	if ( $config->{save_position} == 1 ) {
		($config->{position_x}, $config->{position_y})
			= $win->GetPositionXY;
	}
	$Kephra::temp{dialog}{config}{active} = 0;
	$win->Destroy;
}

1;