package Kephra::API::EventTable;
$VERSION = '0.09';

=pod
 internal app events handling
 events call functions that subscribed to that event
 other function can trigger events
 plugins can also add funcionality triggered by events
 they can be frozen to speed some things up (don't forget to thaw)
 names of Events contain dots as separator
=cut

use strict;
use Wx qw( wxSTC_CMD_NEWLINE WXK_RETURN );
use Wx::Event qw(
	EVT_KEY_UP EVT_KEY_DOWN
	EVT_ENTER_WINDOW EVT_LEAVE_WINDOW EVT_CLOSE EVT_DROP_FILES EVT_MENU_OPEN
	EVT_STC_CHANGE EVT_STC_UPDATEUI EVT_STC_MARGINCLICK
	EVT_STC_SAVEPOINTREACHED EVT_STC_SAVEPOINTLEFT
	EVT_TIMER EVT_IDLE
);
# EVT_STC_CHARADDED EVT_STC_MODIFIED

# get pointer to the event list
sub _get_active { $Kephra::app{eventtable} }
sub _get_frozen { $Kephra::temp{eventtable} }


sub connect_all {
	my $win = Kephra::App::Window::_get();
	my $ep  = Kephra::App::EditPanel::_get();
	$Kephra::app{eventtable}{test} = 1;
	$Kephra::temp{eventtable}{test} = 1;
	my $timer;

	# events for whole window
	EVT_CLOSE      ($win,  sub { trigger('app.close'); Kephra::quit() });
	EVT_DROP_FILES ($win,  \&Kephra::File::add_dropped);
	EVT_MENU_OPEN  ($win,  sub { trigger('menu.open') });
	#EVT_IDLE       ($win,  sub { } );

	# set or update timer events
	if ($Kephra::config{file}{save}{auto_save}) {
		$timer->{file_save} = Wx::Timer->new( $win, 1 );
		$timer->{file_save}->Start
			( $Kephra::config{file}{save}{auto_save} * 1000 );
		EVT_TIMER( $win, 1, sub { Kephra::File::save_all_named() } );
	}
	else {$timer->{file_save}->Stop if $timer->{file_save} }

	if ($Kephra::config{file}{open}{notify_change}) {
		$timer->{file_notify} = Wx::Timer->new( $win, 2 );
		$timer->{file_notify}->Start
			( $Kephra::config{file}{open}{notify_change} * 1000 );
		EVT_TIMER( $win, 2, sub { Kephra::File::changed_notify_check() } );
	}
	else {$timer->{file_notify}->Stop if $timer->{file_notify} }

 
	# scintilla and editpanel events
	return unless $ep;
	connect_editpanel();
	init_key_events();
	EVT_DROP_FILES ($ep,   \&Kephra::File::add_dropped); # override sci presets

	EVT_ENTER_WINDOW ($ep,   sub {
		Wx::Window::SetFocus( $ep ) unless $Kephra::temp{dialog}{active};
		trigger('editpanel.focus');
	});
	#EVT_SET_FOCUS		   ($stc,	sub {});

	EVT_STC_SAVEPOINTREACHED($ep, -1, \&Kephra::File::savepoint_reached);
	EVT_STC_SAVEPOINTLEFT   ($ep, -1, \&Kephra::File::savepoint_left);
	EVT_STC_MARGINCLICK     ($ep, -1, sub {
		#Kephra::Dialog::msg_box(undef, "a", 'b')
	});
}

sub connect_editpanel{
	my $ep  = Kephra::App::EditPanel::_get();

	EVT_STC_CHANGE ($ep, -1, sub {
		my ( $ep, $event ) = @_;
		$Kephra::document{current}{edit_pos} = $ep->GetCurrentPos;
		trigger('document.text.change');#print "change \n";
	});

	EVT_STC_UPDATEUI ($ep, -1, sub {
		my ( $ep, $event) = @_;
		my ( $sel_beg, $sel_end ) = $ep->GetSelection;
		my $prev_selected = $Kephra::temp{current_doc}{text_selected};
		$Kephra::temp{current_doc}{text_selected} = $sel_beg != $sel_end;
		trigger('document.text.select')
			if $Kephra::temp{current_doc}{text_selected} xor $prev_selected;
		trigger('caret.move');#print "caret move \n";
	});
}

sub disconnect_editpanel{
	my $ep  = Kephra::App::EditPanel::_get();

	EVT_STC_CHANGE  ($ep, -1, sub {});
	EVT_STC_UPDATEUI($ep, -1, sub {});
}

sub init_key_events{
 my $stc    = Kephra::App::EditPanel::_get();

	EVT_KEY_DOWN  ($stc,     sub {
		my ($ep, $event) = @_;

		my $map = $Kephra::app{editpanel}{keymap};
		my $key = $event->GetKeyCode +
			1000 * ($event->ShiftDown + $event->ControlDown*2 + $event->AltDown*4);

		if (ref $map->[$key] eq 'CODE'){
			$map->[$key]();
		} elsif ($key ==  WXK_RETURN) { # Enter
			if ($Kephra::config{editpanel}{auto}{brace}{indention}) {
				my $pos  = $ep->GetCurrentPos - 1;
				my $char = $ep->GetCharAt($pos);
				if      ($char == 123) {
					Kephra::Edit::Format::blockindent_open($pos) ; return;
				} elsif ($char == 125) {
					Kephra::Edit::Format::blockindent_close($pos); return;
				}
			}
			$Kephra::config{editpanel}{auto}{indention}
				? Kephra::Edit::Format::autoindent()
				: $ep->CmdKeyExecute(wxSTC_CMD_NEWLINE) ;
		} else { $event->Skip }
		#Kephra::App::Visual::status_msg();
		#SCI_SETSELECTIONMODE
		#($key == 350){use Kephra::Ext::Perl::Syntax;  Kephra::Ext::Perl::Syntax::check()};
	});
}

sub add_call{
	return until ref $_[2] eq 'CODE';
	$Kephra::app{eventtable}{ $_[0] }{ $_[1] } = $_[2];
}

sub add_frozen_call{
	return until ref $_[2] eq 'CODE';
	$Kephra::temp{eventtable}{ $_[0] }{ $_[1] } = $_[2];
}

sub trigger{
	my $list = _get_active();
	for my $event (@_){
		if (ref $list->{$event} eq 'HASH'){
#if ($event eq 'document.list'){
	#print "event: $event $_\n" for keys %{ $list->{$event} };
#}
			$_->() for values %{ $list->{$event} }
		}
	}
}

sub freeze{
	my $list = _get_active();
	my $frozen = _get_frozen();
	for my $event (@_){
		if (ref $list->{$event} eq 'HASH'){
			$frozen->{$event} = $list->{$event};
			delete $list->{$event};
		}
	}
}

sub freeze_all{
	my $list = _get_active();
	my $frozen = _get_frozen();
	for my $event (keys %$list ){
		if (ref $list->{$event} eq 'HASH'){
			$frozen->{$event} = $list->{$event};
			delete $list->{$event};
		}
	}
}

sub thaw{
	my $list = _get_active();
	my $frozen = _get_frozen();
	for my $event (@_){
		if (ref $frozen->{$event} eq 'HASH'){
			$list->{$event} = $frozen->{$event};
			delete $frozen->{$event};
		}
	}
}

sub thaw_all{
	my $list = _get_active();
	my $frozen = _get_frozen();
	for my $event (keys %$frozen ){
		if (ref $frozen->{$event} eq 'HASH'){
			$list->{$event} = $frozen->{$event};
			delete $frozen->{$event};
		}
	}
}

sub del_call{
	return until $_[1];
	my $list = _get_active();
	delete $list->{ $_[0] }{ $_[1] } if exists $list->{ $_[0] }{ $_[1] };
}

sub delete_active{
	my $list = _get_active();
	delete $list->{ $_ } for keys %$list;
}

sub delete_frozen{
	my $frozen = _get_frozen();
	delete $frozen->{ $_ } for keys %$frozen;
}

sub delete_all {
	delete_active();
	delete_frozen();
}

1;