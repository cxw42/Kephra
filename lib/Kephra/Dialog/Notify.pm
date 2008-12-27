package Kephra::Dialog::Notify;
our $VERSION = '0.05';

use strict;
use warnings;


use Wx qw(
		wxVERTICAL wxHORIZONTAL             wxRIGHT wxLEFT wxGROW wxTOP wxALL
		wxLEFT wxCENTER wxRIGHT wxBOTTOM wxALIGN_CENTER_HORIZONTAL
		wxWHITE
		wxTE_READONLY wxTE_CENTRE
		wxNO_FULL_REPAINT_ON_RESIZE wxCAPTION wxSYSTEM_MENU wxCAPTION 
		wxCLOSE_BOX wxSTAY_ON_TOP
);
use Wx::Event qw( EVT_BUTTON EVT_CLOSE );

our $dialog;

sub file_changed {
	my $file_nr = shift;#Kephra::Document::current_nr();
	my $file_path = Kephra::Document::get_attribute('file_path', $file_nr);
	my $file_name = Kephra::Document::get_tmp_value('name', $file_nr);
	my $d10n = Kephra::Config::Localisation::strings()->{dialog};
	my $g10n = $d10n->{general};

	#$Kephra::app{dialog}{notify}{changed}
	$dialog = create_raw_dialog(3);
	$dialog->SetTitle($file_name . ' ' . $g10n->{changed});
	$dialog->{msg}->SetLabel( $d10n->{file}{file_changed_msg} );
	$dialog->{filename}->SetValue($file_path);
	$dialog->{btn}{1}->SetLabel( $g10n->{reload});
	$dialog->{btn}{2}->SetLabel( $g10n->{save_reload} );
	$dialog->{btn}{3}->SetLabel( $g10n->{ignore} );
	EVT_BUTTON($dialog, $dialog->{btn}{1},  sub {
		quit_dialog(); 
		Kephra::File::reload_current();
	} );
	EVT_BUTTON($dialog, $dialog->{btn}{2},  sub {
		quit_dialog(); 
		Kephra::File::save_copy_as(); 
		Kephra::File::reload_current() 
	} );
	EVT_BUTTON($dialog, $dialog->{btn}{3},  sub {
		quit_dialog();
	} );
		#Kephra::Document::set_tmp_value('did_notify', 'ignore', $file_nr);
	ready_dialog($dialog);
}

sub file_deleted {
	my $file_nr = shift;#Kephra::Document::current_nr();
	my $file_path = Kephra::Document::get_attribute('file_path', $file_nr);
	my $file_name = Kephra::Document::get_tmp_value('name', $file_nr);
	my $d10n = Kephra::Localisation::strings()->{dialog};
	my $g10n = $d10n->{general};

	# $Kephra::app{dialog}{notify}{deleted} 
	$dialog = create_raw_dialog(4);
	$dialog->{msg}->SetLabel( $d10n->{file}{file_deleted_msg} );
	$dialog->{btn}{1}->SetLabel( $g10n->{close});
	$dialog->{btn}{2}->SetLabel( $d10n->{file}{save_as} );
	$dialog->{btn}{3}->SetLabel( $g10n->{save} );
	$dialog->{btn}{4}->SetLabel( $g10n->{ignore} );
	EVT_BUTTON($dialog, $dialog->{btn}{1},  sub {
		quit_dialog(); Kephra::File::close_current_unsaved() 
	} );
	EVT_BUTTON($dialog, $dialog->{btn}{2},  sub {
		quit_dialog(); Kephra::File::save_as() 
	} );
	EVT_BUTTON($dialog, $dialog->{btn}{3},  sub {
		quit_dialog(); Kephra::File::save_current() 
	} );
	$dialog->SetTitle($file_name . ' ' . $g10n->{deleted});
	$dialog->{filename}->SetValue($file_path);
	EVT_BUTTON($dialog, $dialog->{btn}{4},  sub {
		quit_dialog();
		Kephra::Document::set_tmp_value('did_notify', 'ignore', $file_nr);
	} );
	ready_dialog($dialog);
}

sub create_raw_dialog {
	my $btn_count = shift || 3;
	my $dialog = Wx::Dialog->new(
		Kephra::App::Window::_ref(), -1, '', [-1,-1], [361, 145], 
		wxNO_FULL_REPAINT_ON_RESIZE | 
		wxCAPTION | wxSYSTEM_MENU | wxCAPTION | wxCLOSE_BOX | wxSTAY_ON_TOP,
	);
	Kephra::App::Window::load_icon
		($dialog, Kephra::Config::filepath($Kephra::config{app}{window}{icon}));
	#$dialog->SetBackgroundColour(wxWHITE);
	EVT_CLOSE( $dialog, \&quit_dialog );

	# starting dialog layout
	my $h_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
	$dialog->{btn}{1} = Wx::Button->new( $dialog, -1, '' );
	$h_sizer->Add( $dialog->{btn}{1}  ,0, wxLEFT, 0);
	for my $btn_nr (2 .. $btn_count) {
		$dialog->{btn}{$btn_nr} = Wx::Button->new( $dialog, -1, '' );
		$h_sizer->Add( $dialog->{btn}{$btn_nr} ,0, wxLEFT, 10);
	}

	$dialog->{msg} = Wx::StaticText->new($dialog, -1, '');
	$dialog->{filename} = Wx::TextCtrl->new
		( $dialog,-1, '', [-1,-1], [-1,-1], wxTE_READONLY | wxTE_CENTRE );
	my $v_sizer = Wx::BoxSizer->new(wxVERTICAL);
	$v_sizer->Add( $dialog->{msg}     ,1, wxCENTER | wxTOP                 , 10 );
	$v_sizer->Add( $dialog->{filename},0, wxCENTER | wxBOTTOM | wxGROW     , 10 );
	$v_sizer->Add( $h_sizer           ,0, wxALL | wxALIGN_CENTER_HORIZONTAL, 10 );

	$dialog->SetSizer($v_sizer);
	return $dialog;
}

sub ready_dialog {
	$dialog = shift;
	$dialog->SetAutoLayout(1);
	$dialog->CenterOnScreen;
	$dialog->ShowModal; #$v_sizer->Fit($dialog);
}

sub quit_dialog {
	my ( $win, $event ) = @_;
	$dialog->Destroy();
}

1;
