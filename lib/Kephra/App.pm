package Kephra::App;
our $VERSION = '0.12';

=pod
     App stands for gui of the main app
=cut

use strict;
use warnings;

use Wx qw(
	wxDefaultPosition wxDefaultSize   wxGROW wxTOP wxBOTTOM wxVERTICAL wxHORIZONTAL
	wxSTAY_ON_TOP wxSIMPLE_BORDER wxFRAME_NO_TASKBAR
	wxSPLASH_CENTRE_ON_SCREEN wxSPLASH_TIMEOUT 
	wxSP_3D wxSP_PERMIT_UNSPLIT wxSP_LIVE_UPDATE
	wxBITMAP_TYPE_ANY wxBITMAP_TYPE_XPM
	wxLI_HORIZONTAL
	wxTheClipboard
	wxNullAcceleratorTable 
);

our @ISA = 'Wx::App';       # $NAME is a wx application

my $obj;
sub _ref { $obj = ref $_[0] eq __PACKAGE__ ? $_[0] : $obj }

# main layout, main frame
sub splashscreen {
	Wx::InitAllImageHandlers();
	my $img = Kephra::Config::filepath( $Kephra::temp{file}{img}{splashscreen} );
	Wx::SplashScreen->new(
		Wx::Bitmap->new(
			Kephra::Config::filepath( $Kephra::temp{file}{img}{splashscreen} ),
			wxBITMAP_TYPE_ANY
		),
		wxSPLASH_CENTRE_ON_SCREEN | wxSPLASH_TIMEOUT, 150, undef, -1,
		wxDefaultPosition, wxDefaultSize,
		wxSIMPLE_BORDER | wxFRAME_NO_TASKBAR | wxSTAY_ON_TOP
	) if $img and -e $img;
}

sub assemble_layout {
	my $win = Kephra::App::Window::_ref();
	my $tg = wxTOP|wxGROW;
	Kephra::API::EventTable::freeze
		( qw(app.splitter.right.changed app.splitter.bottom.changed) );

	$Kephra::app{splitter}{right} = Wx::SplitterWindow->new
		($win, -1, [-1,-1], [-1,-1], wxSP_PERMIT_UNSPLIT|wxSP_LIVE_UPDATE)
			unless exists $Kephra::app{splitter}{right};
	my $right_splitter = $Kephra::app{splitter}{right};
	Wx::Event::EVT_SPLITTER_SASH_POS_CHANGED( $right_splitter, $right_splitter, sub {
		Kephra::API::EventTable::trigger( 'app.splitter.right.changed' );
	} );
	Wx::Event::EVT_SPLITTER_DOUBLECLICKED($right_splitter, $right_splitter, sub {
		Kephra::Plugin::Notepad::show(0);
	});
	$right_splitter->SetSashGravity(1);
	$right_splitter->SetMinimumPaneSize(10);

	$Kephra::app{panel}{main} = Wx::Panel->new($right_splitter)
		unless exists $Kephra::app{panel}{main};
	my $column_panel = $Kephra::app{panel}{main};
	$column_panel->Reparent($right_splitter);

	# setting up output splitter
	$Kephra::app{splitter}{bottom} = Wx::SplitterWindow->new
		($column_panel, -1, [-1,-1], [-1,-1], wxSP_PERMIT_UNSPLIT|wxSP_LIVE_UPDATE)
			unless exists $Kephra::app{splitter}{bottom};
	my $bottom_splitter = $Kephra::app{splitter}{bottom};
	Wx::Event::EVT_SPLITTER_SASH_POS_CHANGED( $bottom_splitter, $bottom_splitter, sub {
		Kephra::API::EventTable::trigger( 'app.splitter.bottom.changed' );
	} );
	Wx::Event::EVT_SPLITTER_DOUBLECLICKED($bottom_splitter, $bottom_splitter, sub {
		Kephra::Plugin::Output::show(0);
	});
	$bottom_splitter->SetSashGravity(1);
	$bottom_splitter->SetMinimumPaneSize(10);

	$Kephra::app{panel}{center} = Wx::Panel->new($bottom_splitter)
		unless exists $Kephra::app{panel}{center};
	my $center_panel = $Kephra::app{panel}{center};
	$center_panel->Reparent($bottom_splitter);

	my $tab_bar    = Kephra::App::TabBar::_ref();
	my $search_bar = Kephra::App::SearchBar::_ref();
	my $search_pos = Kephra::App::SearchBar::position();
	my $notepad_panel = Kephra::Plugin::Notepad::_ref();
	my $output_panel = Kephra::Plugin::Output::_ref();
	$tab_bar->Reparent($center_panel);
	$search_bar->Reparent($center_panel);
	$search_bar->Reparent($column_panel) if $search_pos eq 'bottom';
	$notepad_panel->Reparent($right_splitter);
	$output_panel->Reparent($bottom_splitter);

	my $center_sizer = Wx::BoxSizer->new(wxVERTICAL);
	$center_sizer->Add( $search_bar, 0, $tg, 0) if $search_pos eq 'above';
	$center_sizer->Add( $tab_bar,    1, $tg, 0 );
	$center_sizer->Add( $search_bar, 0, $tg, 0 ) if $search_pos eq 'below';
	$center_panel->SetSizer($center_sizer);
	$center_panel->SetAutoLayout(1);

	my $column_sizer = Wx::BoxSizer->new(wxVERTICAL);
	$column_sizer->Add( $bottom_splitter, 1, $tg, 0);
	$column_sizer->Add( $search_bar,      0, $tg, 0) if $search_pos eq 'bottom';
	$column_panel->SetSizer($column_sizer);
	$column_panel->SetAutoLayout(1);

	my $win_sizer = Wx::BoxSizer->new(wxVERTICAL);
	$win_sizer->Add( $right_splitter, 1, $tg, 0 );
	$win->SetSizer($win_sizer);
	$win->SetAutoLayout(1);
	$win->SetBackgroundColour($tab_bar->GetBackgroundColour);

	Kephra::API::EventTable::thaw
		( qw(app.splitter.right.changed app.splitter.bottom.changed) );
	Kephra::App::SearchBar::show();
	Kephra::Plugin::Notepad::show();
	Kephra::Plugin::Output::show();
}

sub OnInit {
	use Benchmark ();
	my $t0 = new Benchmark if $Kephra::BENCHMARK;
	my $app = shift;
	_ref($app);
	#setup_logging();
	Wx::InitAllImageHandlers();
	splashscreen();             # 2'nd splashscreen can close when app is ready
	my $frame = Kephra::App::Window::create();
	Kephra::Document::Data::create_slot(0);
	Kephra::App::TabBar::create();
	my $ep = Kephra::App::TabBar::add_edit_tab();
	Kephra::Document::Data::set_current_nr(0);
	Kephra::Document::Data::set_previous_nr(0);
	Kephra::Document::Data::set_value('buffer',1);

	Kephra::API::Plugin::load_all ();
	#$main::logger->debug("init app pntr");
	print " init app:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
		if $Kephra::BENCHMARK;
	my $t1 = new Benchmark;
	#$main::logger->debug("glob cfg load");
	print " glob cfg load:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t1 ) ), "\n"
		if $Kephra::BENCHMARK;
	my $t2 = new Benchmark;
	if (Kephra::Config::Global::load_autosaved()) {
		Kephra::App::EditPanel::apply_settings($ep);
		#Kephra::API::EventTable::freeze_all();
		$frame->Show(1);
		print " configs eval:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t2 ) ), "\n"
			if $Kephra::BENCHMARK;
		my $t3 = new Benchmark;
		#Kephra::File::Session::autoload();
		Kephra::Document::add($_) for @ARGV;
		print " file session:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t3 ) ), "\n"
			if $Kephra::BENCHMARK;
		my $t4 = new Benchmark;
		Kephra::File::History::init();
		#Kephra::API::EventTable::thaw_all();
		print " event table:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t4 ) ), "\n"
			if $Kephra::BENCHMARK;
		Kephra::App::EditPanel::gets_focus();
		Kephra::Edit::_let_caret_visible();
		print "app startet:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
			if $Kephra::BENCHMARK;
			1;                      # everything is good
	} else {
		$app->ExitMainLoop(1);
	}
}

sub exit { 
	Kephra::API::EventTable::stop_timer();
	if (Kephra::Dialog::save_on_exit() eq 'cancel') {
		Kephra::API::EventTable::start_timer();
		return;
	}
	exit_unsaved();
}

sub exit_unsaved {
	my $t0 = new Benchmark;
	Kephra::API::EventTable::stop_timer();
	#Kephra::File::Session::autosave();
	Kephra::Config::Global::update();
	Kephra::Config::Global::save_autosaved();
	Kephra::Config::set_xp_style(); #
	Kephra::App::Window::destroy(); # close window
	wxTheClipboard->Flush;          # set copied text free to the global Clipboard
	print "shut down in:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
		if $Kephra::BENCHMARK;
}

sub raw_exit { Wx::Window::Destroy(shift) }

#sub new_instance { system("kephra.exe") }

1;
