package Kephra::App::Window;    # Main application window
our $VERSION = '0.09';

use strict;
use warnings;

my $frame;
sub _ref { if (ref $_[0] eq 'Wx::Frame'){ $frame = $_[0] } else { $frame } }
sub _config { $Kephra::config{app}{window} }

sub create {
	my $win = Wx::Frame->new
		(undef, -1, '', [-1,-1], [-1,-1], &Wx::wxDEFAULT_FRAME_STYLE);
	Wx::Window::SetWindowVariant($win, &Wx::wxWINDOW_VARIANT_SMALL) if Wx::wxMAC();
	_ref($win);
	connect_events($win);
	$win;
}

sub connect_events {
	my $win = shift || _ref();
	my $trigger = \&Kephra::EventTable::trigger;
	Wx::Event::EVT_MENU_OPEN ($win,  sub {&$trigger('menu.open')});
	Wx::Event::EVT_DROP_FILES($win, \&Kephra::File::add_dropped);
	Wx::Event::EVT_CLOSE     ($win,  sub {
		&$trigger('app.close');
		Kephra::App::exit() 
	});
	#Wx::Event::EVT_IDLE       ($win,  sub { } );
}

sub apply_settings {
	my $win = shift || _ref();
	$win->DragAcceptFiles(1) if Wx::wxMSW();
	my $icon_file = Kephra::Config::existing_filepath( _config()->{icon} );
	load_icon( $win, $icon_file );
	restore_positions();
	eval_on_top_flag();
}

sub load_icon {
	my $frame     = shift;
	my $icon_file = shift;
	return unless -e $icon_file;
	my $type ;
	if    ($icon_file =~ /.ico$/) { $type = &Wx::wxBITMAP_TYPE_ICO }
	elsif ($icon_file =~ /.xpm$/) { $type = &Wx::wxBITMAP_TYPE_XPM }
	my $icon;
    $icon = Wx::Icon->new( $icon_file, $type ) if $type;
	$frame->SetIcon( $icon ) if defined $icon;
}

sub set_title {
	my $title = shift;
	_ref()->SetTitle($title);

}

sub refresh_title {
	my $appname = $Kephra::NAME;
	my $version = $Kephra::VERSION;
	my $untitled = Kephra::Config::Localisation::strings()->{app}{general}{untitled};
	my $filepath = Kephra::Document::Data::get_file_path() || "<$untitled>";
	my $filename = Kephra::Document::Data::file_name() || "<$untitled>";
	my $docnr = Kephra::Document::Data::current_nr() + 1;
	my $doccount = Kephra::Document::Data::last_nr();
	set_title( eval qq/"$Kephra::config{app}{window}{title}"/ );
}


sub get_on_top_mode { _config()->{stay_on_top} }
sub switch_on_top_mode {
	_config()->{stay_on_top} ^= 1;
	eval_on_top_flag();
}
sub eval_on_top_flag {
	my $win   = _ref();
	my $style = $win->GetWindowStyleFlag();
	if ( get_on_top_mode() ) { $style |= &Wx::wxSTAY_ON_TOP }
	else                     { $style &= ~&Wx::wxSTAY_ON_TOP }
	$win->SetWindowStyle($style);
	Kephra::EventTable::trigger('app.window.ontop');
}


sub save_positions{
	my $app_win = Kephra::App::Window::_ref();
	my $config  = _config();
	if ($config->{save_position}){
		($config->{position_x},$config->{position_y}) = $app_win->GetPositionXY;
		($config->{size_x},    $config->{size_y})     = $app_win->GetSizeWH;
	}
}
sub restore_positions{
	# main window: resize when its got lost
	my $config  = _config();
	my $default  = $config->{default};
	my $screen = Wx::GetDisplaySize();
	my ($screen_x, $screen_y ) = ( $screen->GetWidth, $screen->GetHeight );
	if ($config->{save_position}){
		if (   ( 0 > $config->{position_x} + $config->{size_x} )
			or ( 0 > $config->{position_y} + $config->{size_y} ) ) {
			$config->{position_x} = 0;
			$config->{position_y} = 0;
			if ( int $default->{size_x} == 0 )
				{ $config->{size_x} = $screen_x }
			else{ $config->{size_x} = $default->{size_x} }
			if ( int $default->{size_y} == 0 )
				{ $config->{size_y} = $screen_y - 55}
			else{ $config->{size_y} = $default->{size_y} }
		}
		if (Wx::wxMAC()) {$config->{size_y}-=23; if ($config->{position_y}<21) {$config->{position_y}=21;}}
		$config->{position_x} = 0 if $screen_x < $config->{position_x};
		$config->{position_y} = 0 if $screen_y < $config->{position_y};
	} else {
		$config->{position_x} = $default->{position_x};
		$config->{position_y} = $default->{position_y};
		$config->{size_x} = $default->{size_x};
		$config->{size_y} = $default->{size_y};
	}
	_ref()->SetSize(
		$config->{position_x}, $config->{position_y},
		$config->{size_x},     $config->{size_y}
	);
}

sub OnPaint {
	my ( $self, $event ) = @_;
	my $dc = Wx::PaintDC->new($self);  # create a device context (DC)
}

sub OnQuit {
	my ( $self, $event ) = @_;
	$self->Close(1);
}

sub destroy { _ref()->Destroy() }

1;
