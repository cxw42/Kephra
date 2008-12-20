package Kephra::App::SearchBar;
use strict;
use warnings;

our $VERSION = '0.12';

use Wx qw( 
	wxTOP wxBOTTOM wxGROW
	wxSTC_CMD_LINESCROLLUP wxSTC_CMD_LINESCROLLDOWN
	wxSTC_CMD_CHARLEFT wxSTC_CMD_CHARRIGHT
	wxSTC_CMD_PAGEUP wxSTC_CMD_PAGEDOWN
	wxSTC_CMD_DOCUMENTSTART wxSTC_CMD_DOCUMENTEND
	WXK_ESCAPE WXK_RETURN WXK_F3 WXK_PAGEUP WXK_PAGEDOWN
	WXK_UP WXK_DOWN  WXK_LEFT WXK_RIGHT WXK_HOME WXK_END WXK_BACK
	wxTE_PROCESS_ENTER
);
use Wx::Event qw( 
	EVT_TEXT EVT_KEY_DOWN EVT_ENTER_WINDOW EVT_LEAVE_WINDOW EVT_COMBOBOX
);


sub _ref{ Kephra::App::ToolBar::_ref('search', $_[0]) }
sub _config { $Kephra::config{app}{toolbar}{search} }


sub create {
	# load searchbar definition
	my $bar_def = Kephra::Config::File::load_from_node_data( _config() );
	unless ($bar_def) {
		$bar_def = Kephra::Config::Tree::get_subtree
			( Kephra::Config::Default::toolbars(), 'searchbar');
	}

	# create searchbar with buttons
	my $rest_widgets = Kephra::App::ToolBar::create_new( 'search', $bar_def);
	my $bar = _ref();
	# apply special searchbar widgets
	for my $item_data (@$rest_widgets){
		if ($item_data->{type} eq 'combobox' and $item_data->{id} eq 'find'){
			my $find_input = $bar->{find_input} = Wx::ComboBox->new (
				$bar , -1, '', [-1,-1], [$item_data->{size},-1], [],
				wxTE_PROCESS_ENTER
			);
			$find_input->SetDropTarget( SearchInputTarget->new($find_input, 'find'));
			$find_input->SetValue( Kephra::Edit::Search::get_find_item() );
			$find_input->SetSize($item_data->{size},-1) if $item_data->{size};
			if ( $Kephra::config{search}{history}{use} ){
				$find_input->Append($_)
					for @{$Kephra::config{search}{history}{find_item}}
			}
			$bar->InsertControl( $item_data->{pos}, $find_input );

			EVT_TEXT( $bar, $find_input, sub {
				my ($bar, $event) = @_;
				my $old = Kephra::Edit::Search::get_find_item();
				my $new = $find_input->GetValue;
				if ($new ne $old){
					Kephra::Edit::Search::set_find_item( $new );
					Kephra::Edit::Search::first_increment()
						if $Kephra::config{search}{attribute}{incremental}
						and Wx::Window::FindFocus() eq $find_input;
				}
			} );
			EVT_KEY_DOWN( $find_input, sub {
				my ( $fi, $event ) = @_;
				my $map = $Kephra::app{editpanel}{keymap};
				my $key = $event->GetKeyCode;

				my $found_something;
				my $ep = Kephra::App::EditPanel::_ref();
				if      ( $key == WXK_RETURN ) {
					if    ( $event->ControlDown and $event->ShiftDown)   
					                           {Kephra::Edit::Search::find_last() }
					elsif ($event->ControlDown){Kephra::Edit::Search::find_first()}
					elsif ($event->ShiftDown)  {Kephra::Edit::Search::find_prev() }
					else                       {Kephra::Edit::Search::find_next() }
				} elsif ($key == WXK_F3){
					$event->ShiftDown 
						? Kephra::Edit::Search::find_prev()
						: Kephra::Edit::Search::find_next();
				} elsif ($key == WXK_ESCAPE) { # escape
					give_editpanel_focus_back()
				} elsif ($key == 65 and $event->ControlDown) {# A
					$bar->{find_input}->SetSelection
						(0, $bar->{find_input}->GetLastPosition);
				} elsif ($key == 70 and $event->ControlDown) {# F
					give_editpanel_focus_back()
				} elsif ( $key == 71 ) { # G
					if ($event->ControlDown and $event->ShiftDown){
						give_editpanel_focus_back();
						Kephra::Edit::Goto::last_edit();
					}
				} elsif ($key == 81) { # Q
					switch_visibility() if $event->ControlDown;
				#} elsif ( $key == WXK_LEFT ){ wxSTC_CMD_CHARLEFT return
				#} elsif ($key == WXK_RIGHT ){ wxSTC_CMD_CHARRIGHT return;
				} elsif ($key == WXK_UP){
					if ($event->ControlDown) {
						$ep->CmdKeyExecute( wxSTC_CMD_LINESCROLLUP ); return;
					}
				} elsif ($key == WXK_DOWN){
					if ($event->ControlDown) {
						$ep->CmdKeyExecute( wxSTC_CMD_LINESCROLLDOWN ); return;
					}
				} elsif ($key == WXK_PAGEUP) { # page up
					if ($event->ControlDown) {
						my $pos = $bar->{find_input}->GetInsertionPoint;
						Kephra::Document::Change::tab_left();
						Wx::Window::SetFocus($bar->{find_input});
						$bar->{find_input}->SetInsertionPoint($pos);
					} else {
						$ep->CmdKeyExecute( wxSTC_CMD_PAGEUP );
					}
					return;
				} elsif ($key == WXK_PAGEDOWN){ # page down
					if ($event->ControlDown) {
						my $pos = $bar->{find_input}->GetInsertionPoint;
						Kephra::Document::Change::tab_right();
						Wx::Window::SetFocus($bar->{find_input});
						$bar->{find_input}->SetInsertionPoint($pos);
					} else {
						$ep->CmdKeyExecute( wxSTC_CMD_PAGEDOWN );
					}
					return;
				} elsif ($key == WXK_HOME and $event->ControlDown) {
					$ep->CmdKeyExecute( wxSTC_CMD_DOCUMENTSTART ); return;
				} elsif ($key == WXK_END and $event->ControlDown) {
					$ep->CmdKeyExecute( wxSTC_CMD_DOCUMENTEND ); return;
				} elsif ($key == WXK_BACK and $event->ControlDown and $event->ShiftDown) {
					my $pos = $bar->{find_input}->GetInsertionPoint;
					Kephra::Document::Change::switch_back();
					Wx::Window::SetFocus($bar->{find_input});
					$bar->{find_input}->SetInsertionPoint($pos);
				} else  {
					#print "$key\n"
				}
				$event->Skip;
			} );
			#EVT_COMBOBOX( $find_input, -1, sub{ } );
			EVT_ENTER_WINDOW( $find_input, sub{
				Wx::Window::SetFocus($find_input) if _config()->{autofocus};
				disconnect_find_input();
			});
			EVT_LEAVE_WINDOW( $find_input, sub{ connect_find_input($find_input) });
			connect_find_input($find_input);
			$Kephra::temp{bar}{search}{colored} = 1;
		}
	}
	EVT_LEAVE_WINDOW($bar, \&leave_focus);
	$bar->Realize;
	$bar;
}


sub destroy{ Kephra::App::ToolBar::destroy ('search') }

sub connect_find_input {
	my $find_input = shift;
	Kephra::API::EventTable::add_call( 'find.item.changed', 'search_bar', sub {
			my $value = Kephra::Edit::Search::get_find_item();
			return if $value eq $find_input->GetValue;
			$find_input->SetValue( $value );
			my $pos = $find_input->GetLastPosition;
			$find_input->SetSelection($pos,$pos);
	});
	Kephra::API::EventTable::add_call( 'find.item.history.changed', 'search_bar', sub {
			$find_input->Clear();
			$find_input->Append($_) for @{ Kephra::Edit::Search::get_find_history() };
			$find_input->SetValue(Kephra::Edit::Search::get_find_item());
			$find_input->SetInsertionPointEnd;
	});
	Kephra::API::EventTable::add_call( 'find', 'search_bar', \&colour_find_input);
}
sub disconnect_find_input{
	Kephra::API::EventTable::del_call('find','search_bar');
	Kephra::API::EventTable::del_call('find.item.changed','search_bar');
	Kephra::API::EventTable::del_call('find.item.history.changed','search_bar');
}


sub colour_find_input {
	my $find_input      = _ref()->{find_input};
	my $found_something = $Kephra::temp{search}{item}{foundpos} > -1
		? 1 : 0;
	return if $Kephra::temp{bar}{search}{colored} eq $found_something;
	$Kephra::temp{bar}{search}{colored} = $found_something;
	if ($found_something){
		$find_input->SetForegroundColour( Wx::Colour->new( 0x00, 0x00, 0x55 ) );
		$find_input->SetBackgroundColour( Wx::Colour->new( 0xff, 0xff, 0xff ) );
	} else {
		$find_input->SetForegroundColour( Wx::Colour->new( 0xff, 0x33, 0x33 ) );
		$find_input->SetBackgroundColour( Wx::Colour->new( 0xff, 0xff, 0xff ) );
	}
	$find_input->Refresh;
}

sub enter_focus{
	my $bar = _ref();
	switch_visibility() unless get_visibility();
	Wx::Window::SetFocus($bar->{find_input}) if defined $bar->{find_input};
}
sub leave_focus{ switch_visibility() if _config()->{autohide} }

sub give_editpanel_focus_back{
	leave_focus();
	Wx::Window::SetFocus( Kephra::App::EditPanel::_ref() );
}

sub position {}

# set visibility
sub show {
	my $visible = shift || get_visibility();
	my $bar = _ref();
	my $sizer = $bar->GetParent->GetSizer;#$Kephra::app{sizer}{main}
	$sizer->Show( $bar, $visible );
	$sizer->Layout();
	#Kephra::App::Window::_ref()->Layout();
	_config()->{visible} = $visible;
}
sub get_visibility    { _config()->{visible} }
sub switch_visibility { _config()->{visible} ^= 1; show(); }

1;
