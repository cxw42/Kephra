package Kephra::App;
our $VERSION = '0.04';

use strict;
use Wx qw(
	wxDefaultPosition wxDefaultSize   wxGROW wxTOP wxBOTTOM
	wxVERTICAL 
	wxSTAY_ON_TOP wxSIMPLE_BORDER wxFRAME_NO_TASKBAR
	wxSPLASH_CENTRE_ON_SCREEN wxSPLASH_TIMEOUT 
	wxBITMAP_TYPE_JPEG wxBITMAP_TYPE_PNG wxBITMAP_TYPE_ICO wxBITMAP_TYPE_XPM
	wxTheClipboard
);

sub _get{ $Kephra::app{ref} };
sub _set{ $Kephra::app{ref} = shift };

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
	my $win = Kephra::App::Window::_get();

	my $main_sizer = $win->{sizer} = Wx::BoxSizer->new(wxVERTICAL);
	$main_sizer->Add( Kephra::App::TabBar::_get_sizer(), 0, wxTOP|wxGROW, 0 );
	#$main_sizer->AddSpace(8, 0) if ($^O eq 'linux'); #dirty lin hack remove asap
	$main_sizer->Add( Kephra::App::EditPanel::_get(),    1, wxTOP|wxGROW, 0 );
	if (Kephra::App::SearchBar::_get_config()->{position} eq 'top') {
		$main_sizer->Prepend(Kephra::App::SearchBar::_get(), 0, wxTOP|wxGROW, 2)
	} else {
		$main_sizer->Add(Kephra::App::SearchBar::_get(), 0, wxBOTTOM|wxGROW, 3)
	}
	$win->SetSizer($main_sizer);
	$win->SetAutoLayout(1);
	$win->Layout;
	$win->SetBackgroundColour(Kephra::App::TabBar::_get_tabs()->GetBackgroundColour);
	Kephra::App::TabBar::show();
	$win;
}

sub start {
	use Benchmark qw(:all);
	my $t0 = new Benchmark;
	my $app = shift;
	_set($app);
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
