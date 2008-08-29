package Kephra::App;
use strict;
use warnings;

our $VERSION = '0.06';

use Wx qw(
	wxDefaultPosition wxDefaultSize   wxGROW wxTOP wxBOTTOM wxVERTICAL wxHORIZONTAL
	wxSTAY_ON_TOP wxSIMPLE_BORDER wxFRAME_NO_TASKBAR
	wxSPLASH_CENTRE_ON_SCREEN wxSPLASH_TIMEOUT 
	wxBITMAP_TYPE_ANY wxBITMAP_TYPE_XPM
	wxLI_HORIZONTAL
	wxTheClipboard
	wxNullAcceleratorTable 
);

sub _ref { 
	if (ref $_[0] eq 'Kephra'){ $Kephra::app{ref} = $_[0] }
	else                      { $Kephra::app{ref} }
}

# main layout, main frame
sub splashscreen {
	Wx::InitAllImageHandlers();
	Wx::SplashScreen->new(
		Wx::Bitmap->new(
			Kephra::Config::filepath( $Kephra::temp{file}{img}{splashscreen} ),
			wxBITMAP_TYPE_ANY
		),
		wxSPLASH_CENTRE_ON_SCREEN | wxSPLASH_TIMEOUT, 150, undef, -1,
		wxDefaultPosition, wxDefaultSize,
		wxSIMPLE_BORDER | wxFRAME_NO_TASKBAR | wxSTAY_ON_TOP
	);
}

sub setup_logging {
    eval {
        require Log::Dispatch;
        require Log::Dispatch::File;
    };
    if ($@) {
        _setup_fake_logger();
    } else {
        _setup_real_logger();
    }
    $main::logger->info("Starting");


    return;
}

sub _setup_fake_logger {
    package Kephra::FakeLogger;
    $main::logger = bless {}, __PACKAGE__; 
    no strict 'refs';
    foreach my $l ( qw( debug info notice warning err error crit critical alert emerg emergency ) )
    {
        *{$l} = sub {};
    }
    return;
}

sub _setup_real_logger {
    mkdir $Kephra::temp{path}{logger};
    # TODO: setup pseudo logger in case the directory does not exist or
    # otherwise cannot start the logger, report error
    $main::logger = Log::Dispatch->new;
    require POSIX;
    my $ts = POSIX::strftime("%Y%m%d", localtime);
            print File::Spec->catfile($Kephra::temp{path}{logger}, "$ts.log");
    $main::logger->add( Log::Dispatch::File->new( 
            name        => 'file1',
            min_level   => ($ENV{KEPHRA_LOGGIN} || 'debug'),
            filename    => File::Spec->catfile($Kephra::temp{path}{logger}, "$ts.log"),
            mode        => 'append',
            callbacks   => \&_logger,
    ));
    $SIG{__WARN__} = sub { $main::logger->warning($_[0]) };
    return;
}


sub _logger {
    my %data = @_;
    # TODO maybe we should use regular timestamp here and turn on the hires timestamp
    # only if KEPHRA_TIME or similar env variable is set
    require Time::HiRes;
    return sprintf("%s - %s - %s - %s\n", Time::HiRes::time(), $$, $data{level}, $data{message});
}

sub assemble_layout {
	my $win = Kephra::App::Window::_ref();

	my $main_sizer = $win->{vsizer} = Wx::BoxSizer->new(wxVERTICAL);
	my $hs_sizer = $win->{hsizer} = Wx::BoxSizer->new(wxHORIZONTAL);
	my $tg = wxTOP|wxGROW;

	my $search_pos = Kephra::App::SearchBar::_config()->{position};
	my $search_bar = Kephra::App::SearchBar::_ref();


	$hs_sizer->Add( Kephra::App::EditPanel::_ref(),      1, $tg, 0 );
	$hs_sizer->Add( Kephra::Extention::Notepad::create(),0, $tg, 0 );

	$main_sizer->Add( $search_bar, 0, wxTOP|wxGROW, 0) if $search_pos eq 'top';
	$main_sizer->Add( Kephra::App::TabBar::_get_sizer(), 0, $tg, 0 );
	if ($search_pos eq 'middle') {
		$main_sizer->Add( $search_bar, 0, $tg, 0);
		$main_sizer->Add( Wx::StaticLine->new
			($win, -1, [-1,-1],[-1,2], wxLI_HORIZONTAL), 0, $tg, 0 );
	}
	$main_sizer->Add( $hs_sizer,   1, $tg, 0 );
	$main_sizer->Add( $search_bar, 0, $tg, 0 ) if $search_pos eq 'below';
	$main_sizer->Add( Kephra::Extention::Output::create(),0, $tg, 0 );
	$main_sizer->Add( $search_bar, 0, $tg, 0 ) if $search_pos eq 'bottom';

	$win->SetSizer($main_sizer);
	$win->SetAutoLayout(1);
	$win->Layout;
	$win->SetBackgroundColour(Kephra::App::TabBar::_ref()->GetBackgroundColour);
	Kephra::App::TabBar::show();
}

sub start {
	use Benchmark ();
	my $t0 = new Benchmark if $Kephra::BENCHMARK;
	my $app = shift;
	_ref($app);
	Kephra::Config::init();
	#setup_logging();
	splashscreen();             # 2'nd splashscreen can close when app is ready
	Wx::InitAllImageHandlers();
	Kephra::Extention::Output::init();
	my $frame = Kephra::App::Window::create();
	my $ep = Kephra::App::EditPanel::create();
	$Kephra::temp{document}{open}[0]{pointer} = $ep->GetDocPointer();
	$Kephra::temp{document}{buffer} = 1;
	#$main::logger->debug("init app pntr");
	print " init app pntr:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
		if $Kephra::BENCHMARK;
	my $t1 = new Benchmark;
	Kephra::Config::Global::load_autosaved();
	#$main::logger->debug("glob cfg load");
	print " glob cfg load:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t1 ) ), "\n"
		if $Kephra::BENCHMARK;
	my $t2 = new Benchmark;
	if (Kephra::Config::Global::evaluate()) {
		#Kephra::API::EventTable::freeze_all();

		#clean_acc_table();
		$frame->Show(1);
		print " configs eval:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t2 ) ), "\n"
			if $Kephra::BENCHMARK;
		my $t3 = new Benchmark;
		Kephra::File::Session::autoload();
		Kephra::Document::Internal::add($_) for @ARGV;
		print " file session:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t3 ) ), "\n"
			if $Kephra::BENCHMARK;
		my $t4 = new Benchmark;
		Kephra::File::History::init();
		#Kephra::API::EventTable::thaw_all();
		Kephra::API::EventTable::connect_all();
		print " event table:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t4 ) ), "\n"
			if $Kephra::BENCHMARK;
		print "app startet:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
			if $Kephra::BENCHMARK;
			1;                      # everything is good
	} else {
		$app->ExitMainLoop(1);
	}
}

sub exit { 
	my $t0 = new Benchmark;
	Kephra::API::EventTable::stop_timer();
	Kephra::File::Session::autosave();
	return if Kephra::Dialog::save_on_exit() eq 'cancel';
	Kephra::Config::Global::update();
	Kephra::Config::Global::save_autosaved();
	#Kephra::API::CommandList::store_cache();
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
