package Kephra::Dialog;
our $VERSION = '0.18';

use strict;
use warnings;

use Wx qw(:filedialog );    # :messagebox
use Wx qw (wxDefaultPosition wxDefaultSize
	wxOK wxYES wxYES_NO wxNO wxCANCEL wxID_CANCEL
	wxICON_INFORMATION wxICON_QUESTION wxICON_WARNING
	wxFD_SAVE wxFD_OPEN wxFD_MULTIPLE    wxSTAY_ON_TOP
);

sub _set_icon { my ($d, $cmd_id) = @_; }

sub msg_box {
	Wx::MessageBox
		( $_[1], $_[2], wxOK | wxSTAY_ON_TOP, $_[0] );
}

sub info_box {
	Wx::MessageBox
		( $_[1], $_[2], wxOK | wxICON_INFORMATION | wxSTAY_ON_TOP, $_[0] );
}

sub warning_box {
	Wx::MessageBox
		( $_[1], $_[2], wxOK | wxICON_WARNING | wxSTAY_ON_TOP, $_[0] );
}

sub get_confirm_2 {
	Wx::MessageBox
		( $_[1], $_[2], wxYES_NO | wxICON_QUESTION | wxSTAY_ON_TOP, $_[0]);
}

sub get_confirm_3 {
	Wx::MessageBox( $_[1], $_[2], wxYES_NO | wxCANCEL | wxICON_QUESTION,
		$_[0], $_[3], $_[4] );
}

sub get_file_open {
	Wx::FileSelector( $_[1], $_[2], '', '', $_[3], wxFD_OPEN, $_[0], -1, -1 );
}

sub get_files_open {
	my $dialog = Wx::FileDialog->new(
		$_[0], $_[1], $_[2], '', $_[3], wxFD_OPEN | wxFD_MULTIPLE, [-1,-1] );
	if ($dialog->ShowModal != wxID_CANCEL) {
		my @files = $dialog->GetPaths;
		return \@files;
	}
}

sub get_file_save {
	Wx::FileSelector( $_[1], $_[2], '', '', $_[3], wxFD_SAVE, $_[0], -1, -1)
}

sub get_dir {
	Wx::DirSelector($_[0], $_[1],);
}

sub get_font { Wx::GetFontFromUser  ( $_[0], $_[1] ) }
sub get_text { Wx::GetTextFromUser  ( $_[1], $_[2], "", $_[0], -1, -1, 1 ) }
sub get_number{Wx::GetNumberFromUser( $_[1], '', $_[2],$_[3], 0, 100000, $_[0])}

sub find {
	require Kephra::Dialog::Search;
	&Kephra::Dialog::Search::find;
}

sub replace {
	require Kephra::Dialog::Search;
	&Kephra::Dialog::Search::replace;
}

sub config {
	require Kephra::Dialog::Config;
	&Kephra::Dialog::Config::main;
}

sub info {
	require Kephra::Dialog::Info;
	&Kephra::Dialog::Info::combined;
}

sub notify_file_changed {
	require Kephra::Dialog::Notify;
	&Kephra::Dialog::Notify::file_changed;
}
sub notify_file_deleted {
	require Kephra::Dialog::Notify;
	&Kephra::Dialog::Notify::file_deleted;
}

sub save_on_exit {
	require Kephra::Dialog::Exit;
	&Kephra::Dialog::Exit::save_on_exit;
}

1;

