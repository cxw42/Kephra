package Kephra::App;
our $VERSION = '0.04';

use strict;
use Wx qw(
	wxDefaultPosition wxDefaultSize   wxGROW wxTOP wxBOTTOM wxVERTICAL 
	wxSTAY_ON_TOP wxSIMPLE_BORDER wxFRAME_NO_TASKBAR
	wxSPLASH_CENTRE_ON_SCREEN wxSPLASH_TIMEOUT 
	wxBITMAP_TYPE_JPEG wxBITMAP_TYPE_PNG wxBITMAP_TYPE_ICO wxBITMAP_TYPE_XPM
	wxLI_HORIZONTAL
	wxTheClipboard
);

sub _ref { 
	if ($_[0]){ $Kephra::app{ref} = $_[0] }
	else      { $Kephra::app{ref} }
 }

# main layout, main frame
sub splashscreen {
	Wx::InitAllImageHandlers();
	Wx::SplashScreen->new(
		Wx::Bitmap->new(
			Kephra::Config::filepath( $Kephra::temp{file}{img}{splashscreen} ),
			wxBITMAP_TYPE_JPEG
		),
		wxSPLASH_CENTRE_ON_SCREEN | wxSPLASH_TIMEOUT, 150, undef, -1,
		wxDefaultPosition, wxDefaultSize,
		wxSIMPLE_BORDER | wxFRAME_NO_TASKBAR | wxSTAY_ON_TOP
	);
}

sub assemble_layout {
	my $win = Kephra::App::Window::_ref();

	my $main_sizer = $win->{sizer} = Wx::BoxSizer->new(wxVERTICAL);
	my $search_pos = Kephra::App::SearchBar::_config()->{position};
	if ($search_pos eq 'top') {
		$main_sizer->Add( Kephra::App::SearchBar::_ref(), 0, wxTOP|wxGROW, 0)
	}
	$main_sizer->Add( Kephra::App::TabBar::_get_sizer(), 0, wxTOP|wxGROW, 0);
	if ($search_pos eq 'middle') {
		$main_sizer->Add( Kephra::App::SearchBar::_ref(), 0, wxTOP|wxGROW, 0);
		$main_sizer->Add( Wx::StaticLine->new
			($win, -1, [-1,-1],[-1,2], wxLI_HORIZONTAL), 0, wxBOTTOM|wxGROW, 0);
	}
	$main_sizer->Add( Kephra::App::EditPanel::_ref(),    1, wxTOP|wxGROW, 0 );
	if ($search_pos eq 'bottom') {
		$main_sizer->Add( Kephra::App::SearchBar::_ref(), 0, wxBOTTOM|wxGROW, 0)
	}
	$win->SetSizer($main_sizer);
	$win->SetAutoLayout(1);
	$win->Layout;
	$win->SetBackgroundColour(Kephra::App::TabBar::_ref()->GetBackgroundColour);
	Kephra::App::TabBar::show();
}

sub clean_acc_table {
	my $win = Kephra::App::Window::_ref();
	$win->SetAcceleratorTable(Wx::AcceleratorTable->new());
}

sub start {
	use Benchmark qw(:all);
	my $t0 = new Benchmark;
	my $app = shift;
	_ref($app);
	splashscreen();             # 2'nd splashscreen can close when app is ready
	Wx::InitAllImageHandlers();
	my $frame = Kephra::App::Window::create();
	my $ep = Kephra::App::EditPanel::create();
	$Kephra::temp{document}{open}[0]{pointer} = $ep->GetDocPointer();
	$Kephra::temp{document}{buffer} = 1;
	print " init app pntr:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
		if $Kephra::benchmark;
	my $t1 = new Benchmark;
	Kephra::Config::Global::load_autosaved();
	print " glob cfg load:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t1 ) ), "\n"
		if $Kephra::benchmark;
	my $t2 = new Benchmark;
	if (Kephra::Config::Global::evaluate()) {
		#Kephra::API::EventTable::freeze_all();
		$frame->Show(1);
		print " configs eval:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t2 ) ), "\n"
			if $Kephra::benchmark;
		my $t3 = new Benchmark;
		Kephra::File::Session::autoload();
		Kephra::Document::Internal::add($_) for @ARGV;
		print " file session:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t3 ) ), "\n"
			if $Kephra::benchmark;
		my $t4 = new Benchmark;
		Kephra::File::History::init();
		#Kephra::API::EventTable::thaw_all();
		Kephra::API::EventTable::connect_all();
		print " event table:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t4 ) ), "\n"
			if $Kephra::benchmark;
		print "app startet:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
			if $Kephra::benchmark;
			1;                      # everything is good
	} else {
		$app->ExitMainLoop(1);
	}
}

sub exit { 
	my $t0 = new Benchmark;
	Kephra::File::Session::autosave();
	return if Kephra::Dialog::save_on_exit() eq 'cancel';
	Kephra::Config::Global::update();
	Kephra::Config::Global::save_autosaved();
	#Kephra::API::CommandList::store_cache();
	Kephra::Config::set_xp_style(); #
	wxTheClipboard->Flush;          # set copied text free to the global Clipboard
	Kephra::App::Window::destroy(); # close window
	print "shut down in:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
		if $Kephra::benchmark;
}

sub raw_exit { Wx::Window::Destroy(shift) }

#sub new_instance { system("pce.exe") }

1;
