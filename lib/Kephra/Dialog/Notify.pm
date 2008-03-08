package Kephra::Dialog::Notify;
$VERSION = '0.02';

use strict;
use Wx qw(
		wxVERTICAL wxHORIZONTAL             wxRIGHT wxLEFT wxGROW wxTOP wxALL
		wxLEFT wxCENTER wxRIGHT wxBOTTOM    wxWHITE
		wxTE_READONLY wxTE_CENTRE
		wxNO_FULL_REPAINT_ON_RESIZE wxCAPTION wxSYSTEM_MENU wxCAPTION 
		wxCLOSE_BOX wxSTAY_ON_TOP
);
use Wx::Event qw( EVT_BUTTON EVT_CLOSE );
our $dialog;

sub file_changed {
	my $file_nr = shift;
	my $file_path = Kephra::Document::get_attribute('file_path', $file_nr);
	my $file_name = Kephra::Document::get_tmp_value('name', $file_nr);
	my $l10n = $Kephra::localisation{dialog};
	my $g10n = $l10n->{general};

	$dialog = $Kephra::app{dialog}{exit} = Wx::Dialog->new(
		Kephra::App::Window::_get(), -1,
		"$file_name $g10n->{changed}",
		[-1,-1], [340, 145], wxNO_FULL_REPAINT_ON_RESIZE | 
		wxCAPTION | wxSYSTEM_MENU | wxCAPTION | wxCLOSE_BOX | wxSTAY_ON_TOP,
	);
	Kephra::App::Window::load_icon
		($dialog, Kephra::Config::dirpath($Kephra::config{app}{window}{icon}));
	#$dialog->SetBackgroundColour(wxWHITE);
	EVT_CLOSE( $dialog, \&quit_dialog );

	# starting dialog layout
	my $b_reload  = Wx::Button->new( $dialog, -1, $g10n->{reload});
	my $b_sreload = Wx::Button->new( $dialog, -1, $g10n->{save_reload});
	my $b_ignore  = Wx::Button->new( $dialog, -1, $g10n->{ignore});
	EVT_BUTTON($dialog, $b_reload,  sub {
		quit_dialog();
		Kephra::File::reload_current();
	} );
	EVT_BUTTON($dialog, $b_sreload, sub { 
		quit_dialog();
		Kephra::File::save_copy_as();
		Kephra::File::reload_current(); 
	} );
	EVT_BUTTON($dialog, $b_ignore,  \&quit_dialog );
	my $h_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
	$h_sizer->Add( $b_reload  ,0, wxRIGHT, 10);
	$h_sizer->Add( $b_sreload ,0, wxRIGHT, 10);
	$h_sizer->Add( $b_ignore  ,0, wxRIGHT,  0);

	my $msg = Wx::StaticText->new
		( $dialog, -1, $l10n->{file}{file_changed_msg}, [-1, -1],[-1,-1] );
	my $tctrl = Wx::TextCtrl->new
		( $dialog,-1, $file_path, [-1,-1],[-1,-1], wxTE_READONLY | wxTE_CENTRE );
	my $v_sizer = Wx::BoxSizer->new(wxVERTICAL);
	$v_sizer->Add( $msg     ,1, wxCENTER |            wxTOP  , 10 );
	$v_sizer->Add( $tctrl   ,0, wxCENTER | wxBOTTOM | wxGROW , 10 );
	$v_sizer->Add( $h_sizer ,0,            wxALL    | wxGROW , 10 );

	$dialog->SetSizer($v_sizer);
	$dialog->SetAutoLayout(1);
	$dialog->CenterOnScreen;
	$dialog->ShowModal; #$v_sizer->Fit($dialog);
}

sub quit_dialog {
	my ( $win, $event ) = @_;
	$dialog->Destroy();
}

1;