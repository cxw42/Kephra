package Kephra::API::EventTable;
use strict;
use warnings;

our $VERSION = '0.09';

=head1 NAME

Kephra::API::EventTable - API to internal events

=head1 DESCRIPTION

Every routine can subscribe a callback to any event that will than triggered
when that event takes place. Also extentions could do that. Events can also
be triggered to simulate events. Some function freeze events to speed up 
certain repeating actions (don't forget to thaw after that). Callbacks can
also sanely removed if no longer needed.

Names of Events contain dots as separator of of namespaces.

=head1 SPECIFICATION

=head1 List of all Events

=over 4

=item * menu.open

=item * editpanel.focus

=item * document.text.select

=item * document.text.change

=item * document.savepoint

=item * document.list

=item * caret.move

=item * app.close

=back

=cut

use Wx qw( wxSTC_CMD_NEWLINE WXK_RETURN );
use Wx::Event qw(
	EVT_TIMER EVT_IDLE
	EVT_KEY_UP EVT_KEY_DOWN
	EVT_LEFT_UP EVT_LEFT_DOWN EVT_MOTION
	EVT_ENTER_WINDOW EVT_LEAVE_WINDOW EVT_CLOSE 
	EVT_DROP_FILES EVT_MENU_OPEN
	EVT_STC_CHANGE EVT_STC_UPDATEUI EVT_STC_MARGINCLICK
	EVT_STC_SAVEPOINTREACHED EVT_STC_SAVEPOINTLEFT
);

# EVT_STC_CHARADDED EVT_STC_MODIFIED

# get pointer to the event list
sub _get_active { $Kephra::app{eventtable} }
sub _get_frozen { $Kephra::temp{eventtable} }
my  $timer;


sub connect_all {
	my $win = Kephra::App::Window::_ref();
	my $ep  = Kephra::App::EditPanel::_ref();
	my $tb  = Kephra::App::TabBar::_ref();
	#$Kephra::app{eventtable}{test} = 1;
	#$Kephra::temp{eventtable}{test} = 1;

	# events for whole window
	EVT_CLOSE      ($win,  sub { trigger('app.close'); Kephra::quit() });
	EVT_DROP_FILES ($win,  \&Kephra::File::add_dropped);
	EVT_MENU_OPEN  ($win,  sub {
#print"menu ",$_[1]->GetMenuId, ' ', $_[1]->GetMenu, "\n";
		trigger('menu.open') });
	#EVT_IDLE       ($win,  sub { } );



	# scintilla and editpanel events
	return unless $ep;
	connect_editpanel();
	init_key_events();
	EVT_DROP_FILES ($ep,   \&Kephra::File::add_dropped); # override sci presets

	# TabBar
	#EVT_LEFT_UP();
	#EVT_MOTION();
	#EVT_LEFT_DOWN();

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

	start_timer();
}


sub start_timer {
	# set or update timer events
	my $win = Kephra::App::Window::_ref();

	stop_timer();
	if ($Kephra::config{file}{save}{auto_save}) {
		$timer->{file_save} = Wx::Timer->new( $win, 1 );
		$timer->{file_save}->Start
			( $Kephra::config{file}{save}{auto_save} * 1000 );
		EVT_TIMER( $win, 1, sub { Kephra::File::save_all_named() } );
	}

	if ($Kephra::config{file}{open}{notify_change}) {
		$timer->{file_notify} = Wx::Timer->new( $win, 2 );
		$timer->{file_notify}->Start
			( $Kephra::config{file}{open}{notify_change} * 1000 );
		EVT_TIMER( $win, 2, sub { Kephra::File::changed_notify_check() } );
	}
}

sub stop_timer {
	my $win = Kephra::App::Window::_ref();
	$timer->{file_save}->Stop if ref $timer->{file_save} eq 'Wx::Timer';
	delete $timer->{file_save};
	$timer->{file_notify}->Stop if ref $timer->{file_notify} eq 'Wx::Timer';
	delete $timer->{file_notify};
}


sub connect_editpanel{
	my $ep  = Kephra::App::EditPanel::_ref();

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
	my $ep  = Kephra::App::EditPanel::_ref();

	EVT_STC_CHANGE  ($ep, -1, sub {});
	EVT_STC_UPDATEUI($ep, -1, sub {});
}

sub init_key_events {

	EVT_KEY_DOWN  (Kephra::App::EditPanel::_ref(), sub {
		my ($ep, $event) = @_;
		my $key = $event->GetKeyCode +
			1000 * ($event->ShiftDown + $event->ControlDown*2 + $event->AltDown*4);

		# reacting on shortkeys that are defined in the Commanlist
		return if Kephra::API::CommandList::run_cmd_by_keycode($key);
		# reacting on Enter
		if ($key ==  WXK_RETURN) { # Enter
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
		}
		# scintilla handles the rest of the shortkeys
		else { $event->Skip }
		#Kephra::App::Visual::status_msg();
		#SCI_SETSELECTIONMODE
		#($key == 350){use Kephra::Ext::Perl::Syntax; Kephra::Ext::Perl::Syntax::check()};
	});
}

sub add_call {
	return until ref $_[2] eq 'CODE';
	$Kephra::app{eventtable}{ $_[0] }{ $_[1] } = $_[2];
}

sub add_frozen_call {
	return until ref $_[2] eq 'CODE';
	$Kephra::temp{eventtable}{ $_[0] }{ $_[1] } = $_[2];
}

sub trigger {
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

sub freeze {
	my $list = _get_active();
	my $frozen = _get_frozen();
	for my $event (@_){
		if (ref $list->{$event} eq 'HASH'){
			$frozen->{$event} = $list->{$event};
			delete $list->{$event};
		}
	}
}

sub freeze_all {
	my $list = _get_active();
	my $frozen = _get_frozen();
	for my $event (keys %$list ){
		if (ref $list->{$event} eq 'HASH'){
			$frozen->{$event} = $list->{$event};
			delete $list->{$event};
		}
	}
}

sub thaw {
	my $list = _get_active();
	my $frozen = _get_frozen();
	for my $event (@_){
		if (ref $frozen->{$event} eq 'HASH'){
			$list->{$event} = $frozen->{$event};
			delete $frozen->{$event};
		}
	}
}

sub thaw_all {
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
