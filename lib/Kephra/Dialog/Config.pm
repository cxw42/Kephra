package Kephra::Dialog::Config;
$VERSION = '0.17';

use strict;
use Wx qw( 
	wxVERTICAL wxHORIZONTAL wxLEFT wxTOP wxBOTTOM wxGROW wxEXPAND wxALIGN_CENTRE
	wxSYSTEM_MENU wxCAPTION wxSTAY_ON_TOP wxNO_FULL_REPAINT_ON_RESIZE
	wxSIMPLE_BORDER wxRAISED_BORDER  
	wxCLOSE_BOX wxMINIMIZE_BOX  wxFRAME_NO_TASKBAR  wxBITMAP_TYPE_XPM  wxWHITE
	wxTR_NO_BUTTONS wxTR_HIDE_ROOT wxTR_SINGLE
);

use Wx::Event
	qw(EVT_KEY_DOWN EVT_TEXT EVT_BUTTON EVT_CHECKBOX EVT_RADIOBUTTON EVT_CLOSE);

sub _get { $Kephra::app{dialog}{config} }
sub _set { $Kephra::app{dialog}{config} = $_[0] if ref $_[0] eq 'Wx::Frame' }

sub main {
	if ( !$Kephra::temp{dialog}{config}{active}
	or    $Kephra::temp{dialog}{config}{active} == 0 ) {

		# init search and replace dialog
		$Kephra::temp{dialog}{config}{active} = 1;
		my $frame  = Kephra::App::Window::_get();
		my $config = $Kephra::config{dialog}{config};
		my $d_l10n = $Kephra::localisation{dialog}{settings};
		my $g_l10n = $Kephra::localisation{dialog}{general};
		my $m_l10n = $Kephra::localisation{app}{menu};
		my $cl_l10n= $Kephra::localisation{commandlist}{label};
		my $d_style= wxNO_FULL_REPAINT_ON_RESIZE | wxSYSTEM_MENU | wxCAPTION
			| wxMINIMIZE_BOX | wxCLOSE_BOX | wxSTAY_ON_TOP;
		#$d_style |= wxSTAY_ON_TOP if $Kephra::config{app}{window}{stay_on_top};

		# making window & main design
		my $dialog = Wx::Frame->new( $frame, -1, ' '.$d_l10n->{title},
			[ $config->{position_x}, $config->{position_y} ], [ 440, 460 ],
			$d_style);
		Kephra::App::Window::load_icon
			($dialog,Kephra::Config::dirpath($Kephra::config{app}{window}{icon}));
		_set($dialog);

		# main panel
		my $mpanel = Wx::Panel->new( $dialog, -1, [0, 0], [480, 460] );
		my $config_menu = Wx::Panel->new( $mpanel, -1, [10, 10], [106, 362]);
		# construction left main menu
		$config_menu->SetBackgroundColour(wxWHITE);
		my $menu_border = Wx::StaticBox->new( $mpanel, -1, '', 
			[10, 4], [110, 370], wxSIMPLE_BORDER | wxRAISED_BORDER );
		# tree of categories
		my $cat_tree = Wx::TreeCtrl->new( $mpanel, -1, [10, 12], [106, 362],
			wxTR_NO_BUTTONS | wxTR_HIDE_ROOT | wxTR_SINGLE );
		my $root_id = $cat_tree->AddRoot('invisible', -1, -1, td( undef ) );
		my $fid = $cat_tree->AppendItem( $root_id, $m_l10n->{file},-1,-1, td(undef));
#print "rid: $rid, fid: $fid\n";
		$cat_tree->Expand( $cat_tree->AppendItem( $fid, 'neu', -1,-1, td(undef)) );
		$cat_tree->AppendItem( $fid, 'öffnen', -1,-1, td(undef));
		$cat_tree->AppendItem( $fid, 'speichern',  -1,-1, td(undef));
		$fid = $cat_tree->AppendItem( $root_id, $m_l10n->{view},-1,-1, td(undef));
		$cat_tree->Expand( $fid );

		# panels with config controls
		my $file_open_panel = Wx::Panel->new( $mpanel, -1, [400, 10], [276, 362]);
		my $file_save_panel = Wx::Panel->new( $mpanel, -1, [400, 10], [276, 362]);


		#
		$dialog->{apply_button} = Wx::Button->new
			( $mpanel, -1, $g_l10n->{apply},  [ 255, 392 ], [ -1, -1 ] );
		$dialog->{cancel_button} = Wx::Button->new
			( $mpanel, -1, $g_l10n->{cancel}, [ 343, 392 ], [ -1, -1 ] );

		# release
		$dialog->Show(1);
		Wx::Window::SetFocus( $dialog->{cancel_button} );

		# events
		EVT_BUTTON( $dialog, $dialog->{apply_button}, sub {shift->Close} );
		EVT_BUTTON( $dialog, $dialog->{cancel_button},sub {shift->Close} );
		EVT_CLOSE( $dialog, \&quit_config_dialog );

	} else {
		my $dialog = _get();
		$dialog->Iconize(0);
		$dialog->Raise;
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