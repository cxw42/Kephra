package Kephra::API::EventTable;
use strict;
use warnings;

our $VERSION = '0.11';

=head1 NAME

Kephra::API::EventTable - API to internal events

=head1 DESCRIPTION

Every routine can subscribe a callback to any event that will than triggered
when that event takes place. Also extentions (plugins) can do that. 
Event ID can also be triggered to simulate application events. 
Some function do freeze events to speed up certain repeating actions 
(don't forget to thaw after that). Callbacks can also sanely removed,
if no longer needed.

Names of Events contain dots as separator of of namespaces.

=head1 SPECIFICATION

=head2 add_call

=item * EvenID

=item * CallbackID

for removing that callback. Must be unique in for this event.

=item * Callback

a Coderef.

=item * Owner

for removing all callbacks of that owner.

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
	EVT_LEFT_UP EVT_LEFT_DOWN EVT_MIDDLE_DOWN EVT_MOTION
	EVT_ENTER_WINDOW EVT_LEAVE_WINDOW EVT_CLOSE 
	EVT_DROP_FILES EVT_MENU_OPEN
	EVT_STC_CHANGE EVT_STC_UPDATEUI EVT_STC_MARGINCLICK
	EVT_STC_SAVEPOINTREACHED EVT_STC_SAVEPOINTLEFT
);

# EVT_STC_CHARADDED EVT_STC_MODIFIED

# get pointer to the event list
my $timer;
my %table;
sub _data { \%table }

sub connect_all {
	my $win = Kephra::App::Window::_ref();
	my $ep  = Kephra::App::EditPanel::_ref();
	my $tb  = Kephra::App::TabBar::_ref();

	# events for whole window
	EVT_CLOSE      ($win,  sub { trigger('app.close'); Kephra::quit() });
	EVT_DROP_FILES ($win,  \&Kephra::File::add_dropped);
	EVT_MENU_OPEN  ($win,  sub { trigger('menu.open') });
	#EVT_IDLE       ($win,  sub { } );
	start_timer();

	# TabBar
	#EVT_LEFT_UP();
	#EVT_MOTION();
	#EVT_LEFT_DOWN();

	# scintilla and editpanel events
	return unless $ep;
	connect_editpanel();
	init_key_events();
	EVT_DROP_FILES ($ep,   \&Kephra::File::add_dropped); # override sci presets
	EVT_ENTER_WINDOW        ($ep,     sub { trigger('editpanel.focus') });
	EVT_MIDDLE_DOWN         ($ep,     sub {
		my ($ep, $event ) = @_;
		my $nr = Kephra::App::EditPanel::Margin::in_nr($event->GetX);
		Kephra::App::EditPanel::Margin::toggle_siblings($ep, $event ) if $nr == 2;
});
	#EVT_SET_FOCUS		    ($ep, sub {});
	EVT_STC_SAVEPOINTREACHED($ep, -1, \&Kephra::File::savepoint_reached);
	EVT_STC_SAVEPOINTLEFT   ($ep, -1, \&Kephra::File::savepoint_left);
	EVT_STC_MARGINCLICK     ($ep, -1, \&Kephra::App::EditPanel::Margin::on_click);
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
		#SCI_SETSELECTIONMODE Kephra::App::StatusBar::status_msg($event->GetKeyCode);
		#($key == 350){use Kephra::Ext::Perl::Syntax; Kephra::Ext::Perl::Syntax::check()};
	});
}

sub add_call {
	return until ref $_[2] eq 'CODE';
	my $list = _data();
	$list->{active}{ $_[0] }{ $_[1] } = $_[2];
	$list->{owner}{ $_[3] }{ $_[0] }{ $_[1] } = 1 if $_[3];
}

sub add_frozen_call {
	return until ref $_[2] eq 'CODE';
	my $list = _data();
	$list->{frozen}{ $_[0] }{ $_[1] } = $_[2];
	$list->{owner}{ $_[3] }{ $_[0] }{ $_[1] } = 1 if $_[3];
}

sub trigger {
	my $active = _data()->{active};
	for my $event (@_){
		if (ref $active->{$event} eq 'HASH'){
			$_->() for values %{ $active->{$event} }
		}
	}
}

sub freeze {
	my $list = _data();
	for my $event (@_){
		if (ref $list->{active}{$event} eq 'HASH'){
			$list->{frozen}{$event} = $list->{active}{$event};
			delete $list->{active}{$event};
		}
	}
}
sub freeze_all {
	my $list = _data();
	my $active = $list->{active};
	for my $event (keys %$active) {
		if (ref $active->{$event} eq 'HASH'){
			$list->{frozen}{$event} = $active->{$event};
			delete $active->{$event};
		}
	}
}


sub thaw {
	my $list = _data();
	for my $event (@_){
		if (ref $list->{frozen}{$event} eq 'HASH'){
			$list->{active}{$event} = $list->{frozen}{$event};
			delete $list->{frozen}{$event};
		}
	}
}
sub thaw_all {
	my $list = _data();
	my $frozen = _data()->{frozen};
	for my $event (keys %$frozen ){
		if (ref $frozen->{$event} eq 'HASH'){
			$list->{active}{$event} = $frozen->{$event};
			delete $frozen->{$event};
		}
	}
}

sub del_call {
	return until $_[1];
	my $list = _data()->{active};
	delete $list->{ $_[0] }{ $_[1] } if exists $list->{ $_[0] }{ $_[1] };
	$list = _data()->{frozen};
	delete $list->{ $_[0] }{ $_[1] } if exists $list->{ $_[0] }{ $_[1] };
}
sub del_subscription {
	my $subID = shift;
	my $list = _data()->{active};
	for my $event (keys %$list){
		delete $list->{$event}->{$subID} if exists $list->{$event}->{$subID};
	}
	$list = _data()->{frozen};
	for my $event (keys %$list){
		delete $list->{$event}->{$subID} if exists $list->{$event}->{$subID};
	}
}
sub del_own_subscription {
	my $owner = shift;
	my $list = _data();
	return unless ref $list->{owner}{ $owner } eq 'HASH';
	my $lista = $list->{active};
	my $listf = $list->{frozen};
	my $own_ev = $list->{owner}{ $owner };
	for my $ev (keys %$own_ev) {
		for (keys %{$own_ev->{$ev}}) {
			delete $lista->{ $ev  }{ $_ } if exists $lista->{ $ev  }{ $_ };
			delete $listf->{ $ev  }{ $_ } if exists $listf->{ $ev  }{ $_ };
		}
	}
	delete $list->{owner}{ $owner };
}
sub del_all_active { $table{active} = () }
sub del_all_frozen { $table{frozen} = () }
sub del_all        { %table         = () }

1;