package Kephra::Dialog::Search;
our $VERSION = '0.24';

use strict;
use warnings;

use Wx qw(
	wxVERTICAL wxHORIZONTAL wxLEFT wxRIGHT wxTOP wxBOTTOM wxGROW 
	wxALIGN_LEFT wxALIGN_CENTER wxALIGN_RIGHT
	wxALIGN_CENTER_VERTICAL wxALIGN_CENTER_HORIZONTAL 
	wxSYSTEM_MENU wxCAPTION wxNO_FULL_REPAINT_ON_RESIZE wxCLOSE_BOX
	wxMINIMIZE_BOX wxSTAY_ON_TOP wxSIMPLE_BORDER wxRAISED_BORDER
	wxLI_HORIZONTAL
	wxTE_PROCESS_ENTER
	wxBITMAP_TYPE_XPM
	WXK_BACK WXK_TAB WXK_ESCAPE WXK_RETURN WXK_SPACE
);

use Wx::Event qw(
	EVT_KEY_DOWN EVT_TEXT EVT_BUTTON EVT_CHECKBOX EVT_RADIOBUTTON EVT_CLOSE 
	EVT_CHAR EVT_TEXT_ENTER EVT_ENTER_WINDOW
);

sub _ID     { 'search_dialog' }
sub _ref {
	if (ref $_[0] eq 'Wx::Dialog'){ $Kephra::app{dialog}{search} = $_[0] }
	else                          { $Kephra::app{dialog}{search} }
}

##########################
# call as find dialog
sub find {
	my $d = ready();
	my $selection = Kephra::App::EditPanel::_ref()->GetSelectedText;
	if ($selection and not $d->{selection_radio}->GetValue ) {
		Kephra::Edit::Search::set_find_item( $selection );
		$d->{find_input}->SetValue( $selection );
	} else {$d->{find_input}->SetValue( Kephra::Edit::Search::get_find_item())}
	$d->{replace_input}->SetValue( Kephra::Edit::Search::get_replace_item() );
	Wx::Window::SetFocus( $d->{find_input} );
}
##########################
# call as replace dialog
sub replace {
	my $d = ready();
	my $selection = Kephra::App::EditPanel::_ref()->GetSelectedText;
	if ( length $selection > 0 and not $d->{selection_radio}->GetValue ) {
		Kephra::Edit::Search::set_replace_item( $selection );
		$d->{replace_input}->SetValue( $selection );
	} else {
		$d->{replace_input}->SetValue(Kephra::Edit::Search::get_replace_item());
	}
	$d->{find_input}->SetValue( $selection );
	Wx::Window::SetFocus( $d->{replace_input} );
}
##########################
# display find and replace dialog
sub ready {
	if ( not $Kephra::temp{dialog}{search}{active} ) {

		# prepare some internal var and for better handling
		my $edit_panel      = Kephra::App::EditPanel::_ref();
		my $attr            = $Kephra::config{search}{attribute};
		my $dsettings       = $Kephra::config{dialog}{search};
		my $l18n            = Kephra::Config::Localisation::strings();
		my $label           = $l18n->{dialog}{search}{label};
		my $hint            = $l18n->{dialog}{search}{hint};
		my @find_history    = ();
		my @replace_history = ();
		my $d_style = wxNO_FULL_REPAINT_ON_RESIZE | wxSYSTEM_MENU | wxCAPTION
			| wxMINIMIZE_BOX | wxCLOSE_BOX;
		$d_style |= wxSTAY_ON_TOP if $Kephra::config{app}{window}{stay_on_top};
		$dsettings->{position_x} = 10 if $dsettings->{position_x} < 0;
		$dsettings->{position_y} = 10 if $dsettings->{position_y} < 0;
		$dsettings->{width} = Wx::wxMSW() ? 436 : 466;
		if ( $Kephra::config{search}{history}{use} ) {
			@find_history = @{ $Kephra::config{search}{history}{find_item} };
			@replace_history = @{ $Kephra::config{search}{history}{replace_item} };
		}

		# init search and replace dialog and release
		Kephra::Edit::Search::_refresh_search_flags();
		$Kephra::temp{dialog}{search}{active} = 1;
		$Kephra::temp{dialog}{active}++;
		$Kephra::temp{dialog}{search}{colored} = 1;

		# make dialog window and main panel
		my $d = Wx::Dialog->new( 
			Kephra::App::Window::_ref(), -1, 
			$l18n->{dialog}{search}{title},
			[ $dsettings->{position_x}, $dsettings->{position_y} ],
			[ $dsettings->{width}     , 268                      ], $d_style );
		my $icon = Wx::Icon->new;
		my $icon_bmp = Kephra::API::CommandList::get_cmd_property
			('view-dialog-find', 'icon');
		$icon->CopyFromBitmap($icon_bmp) if ref $icon_bmp eq 'Wx::Bitmap';
		$d->SetIcon($icon);
		_ref($d);

		# input boxes with labels
		$d->{find_label}   = Wx::StaticText->new($d, -1, $label->{search_for} );
		$d->{replace_label}= Wx::StaticText->new($d, -1, $label->{replace_with} );
		$d->{find_input} = Wx::ComboBox->new($d, -1,'', [-1,-1], [324,22], [@find_history], wxTE_PROCESS_ENTER );
		$d->{find_input}->SetDropTarget( SearchInputTarget->new($d->{find_input}, 'find'));
		$d->{replace_input} = Wx::ComboBox->new($d, -1, '', [-1,-1], [324,22], [@replace_history], wxTE_PROCESS_ENTER);
		$d->{replace_input}->SetDropTarget( SearchInputTarget->new($d->{replace_input}, 'replace'));
		$d->{sep_line} = Wx::StaticLine->new($d, -1, [0,0], [420,1], wxLI_HORIZONTAL,);

		# search attributes checkboxes
		$d->{inc_box}  = Wx::CheckBox->new($d, -1, $label->{incremental});
		$d->{case_box} = Wx::CheckBox->new($d, -1, $label->{case});
		$d->{begin_box}= Wx::CheckBox->new($d, -1, $label->{word_begin});
		$d->{word_box} = Wx::CheckBox->new($d, -1, $label->{whole_word});
		$d->{regex_box}= Wx::CheckBox->new($d, -1, $label->{regex});
		$d->{wrap_box} = Wx::CheckBox->new($d, -1, $label->{auto_wrap});
		$d->{inc_box}  ->SetValue( $attr->{incremental} );
		$d->{case_box} ->SetValue( $attr->{match_case} );
		$d->{begin_box}->SetValue( $attr->{match_word_begin} );
		$d->{word_box} ->SetValue( $attr->{match_whole_word} );
		$d->{regex_box}->SetValue( $attr->{match_regex} );
		$d->{wrap_box} ->SetValue( $attr->{auto_wrap} );

		# range radio group
		my $range_box = Wx::StaticBox->new($d, -1, $label->{search_in},
			[-1,-1], [-1,-1], wxSIMPLE_BORDER | wxRAISED_BORDER,
		);
		$d->{selection_radio}= Wx::RadioButton->new($d, -1, $label->{selection});
		$d->{document_radio} = Wx::RadioButton->new($d, -1, $label->{document} );
		$d->{all_open_radio} = Wx::RadioButton->new($d, -1, $label->{open_documents} );
################### disable

		# buttons
		my $bmp = \&Kephra::Config::icon_bitmap;
		$d->{replace_back}=Wx::BitmapButton->new($d,-1,&$bmp('replace-previous.xpm'));
		$d->{replace_fore}=Wx::BitmapButton->new($d,-1,&$bmp('replace-next.xpm'));
		$d->{backward_button}=Wx::BitmapButton->new($d,-1,&$bmp('go-previous.xpm'));
		$d->{foreward_button}=Wx::BitmapButton->new($d,-1,&$bmp('go-next.xpm'));
		$d->{fast_back_button}=Wx::BitmapButton->new($d,-1,&$bmp('go-fast-backward.xpm'));
		$d->{fast_fore_button}=Wx::BitmapButton->new($d,-1,&$bmp('go-fast-forward.xpm'));
		$d->{first_button}=Wx::BitmapButton->new($d,-1,&$bmp('go-first.xpm'));
		$d->{last_button}=Wx::BitmapButton->new($d,-1,&$bmp('go-last.xpm'));
		$d->{search_button} = Wx::Button->new($d, -1, $label->{search} );
		$d->{replace_button}= Wx::Button->new($d, -1, $label->{replace_all} );
		$d->{confirm_button}= Wx::Button->new($d, -1, $label->{with_confirmation} );
		$d->{close_button}  = Wx::Button->new($d, -1, $l18n->{dialog}{general}{close} );

		#tooltips / hints
		if ( $dsettings->{tooltips} ) {
			$d->{foreward_button}->SetToolTip( $hint->{forward});
			$d->{backward_button}->SetToolTip( $hint->{backward});
			$d->{fast_fore_button}->SetToolTip( $hint->{fast_forward});
			$d->{fast_back_button}->SetToolTip( $hint->{fast_backward});
			$d->{first_button}->SetToolTip( $hint->{document_start});
			$d->{last_button}->SetToolTip( $hint->{document_end});
			$d->{replace_fore}->SetToolTip( $hint->{replace_forward});
			$d->{replace_back}->SetToolTip( $hint->{replace_backward});
			$d->{case_box}->SetToolTip( $hint->{match_case});
			$d->{begin_box}->SetToolTip( $hint->{match_word_begin});
			$d->{word_box}->SetToolTip( $hint->{match_whole_word});
			$d->{regex_box}->SetToolTip( $hint->{match_regex});
			$d->{wrap_box}->SetToolTip( $hint->{auto_wrap});
			$d->{inc_box}->SetToolTip( $hint->{incremental});
		}

		# eventhandling
		EVT_KEY_DOWN($d->{find_input},       \&find_input_keyfilter );
		EVT_KEY_DOWN($d->{replace_input},    \&replace_input_keyfilter );
		EVT_TEXT($d, $d->{find_input},       \&incremental_search );
		EVT_TEXT($d, $d->{replace_input}, sub {
			my $input = $d->{replace_input};
			my $pos   = $input->GetInsertionPoint;
			Kephra::Edit::Search::set_replace_item( $input->GetValue );
			$input->SetInsertionPoint($pos);
		});
		EVT_CHECKBOX($d, $d->{case_box}, sub {
			$$attr{match_case} = $d->{case_box}->GetValue;
			Kephra::Edit::Search::_refresh_search_flags();
		} );
		EVT_CHECKBOX($d, $d->{begin_box}, sub {
			$$attr{match_word_begin} = $d->{begin_box}->GetValue;
			Kephra::Edit::Search::_refresh_search_flags();
		} );
		EVT_CHECKBOX($d, $d->{word_box}, sub {
			$$attr{match_whole_word} = $d->{word_box}->GetValue;
			Kephra::Edit::Search::_refresh_search_flags();
		} );
		EVT_CHECKBOX($d, $d->{regex_box}, sub {
			$$attr{match_regex} = $d->{regex_box}->GetValue;
			Kephra::Edit::Search::_refresh_search_flags();
		} );
		EVT_CHECKBOX($d, $d->{wrap_box}, sub {
			$$attr{auto_wrap} = $d->{wrap_box}->GetValue;
		} );
		EVT_CHECKBOX($d, $d->{inc_box}, sub {
			$$attr{incremental} = $d->{inc_box}->GetValue;
		} );
		EVT_RADIOBUTTON($d, $d->{selection_radio},sub {$attr->{in} = 'selection'});
		EVT_RADIOBUTTON($d, $d->{document_radio}, sub {$attr->{in} = 'document'});
		EVT_RADIOBUTTON($d, $d->{all_open_radio}, sub {$attr->{in} = 'open_docs'});
		EVT_BUTTON($d, $d->{foreward_button}, sub {
			&no_sel_range; Kephra::Edit::Search::find_next();
		} );
		EVT_BUTTON($d, $d->{backward_button}, sub {
			&no_sel_range; Kephra::Edit::Search::find_prev();
		} );
		EVT_BUTTON($d, $d->{fast_fore_button}, sub {
			&no_sel_range; Kephra::Edit::Search::fast_fore();
		} );
		EVT_BUTTON($d, $d->{fast_back_button}, sub {
			&no_sel_range; Kephra::Edit::Search::fast_back();
		} );
		EVT_BUTTON($d, $d->{first_button}, sub {
			&no_sel_range; Kephra::Edit::Search::find_first();
		} );
		EVT_BUTTON($d, $d->{last_button}, sub {
			&no_sel_range; Kephra::Edit::Search::find_last();
		} );
		EVT_BUTTON($d, $d->{replace_fore}, sub {
			&no_sel_range; Kephra::Edit::Search::replace_fore();
		} );
		EVT_BUTTON($d, $d->{replace_back}, sub {
			&no_sel_range; Kephra::Edit::Search::replace_back();
		} );
		EVT_BUTTON($d, $d->{search_button},  sub{ &Kephra::Edit::Search::find_first } );
		EVT_BUTTON($d, $d->{replace_button}, sub{ &Kephra::Edit::Search::replace_all } );
		EVT_BUTTON($d, $d->{confirm_button}, sub{ &Kephra::Edit::Search::replace_confirm } );
		EVT_BUTTON($d, $d->{close_button},   sub{ shift->Close() } );

		EVT_CLOSE( $d, \&quit_search_dialog );


		my $ID = _ID();
		my $add_call = \&Kephra::API::EventTable::add_call;

		&$add_call( 'find', $ID.'_color_refresh', \&colour_find_input, $ID);

		&$add_call( 'find.item.changed', $ID, sub {
			$d->{find_input}->SetValue(Kephra::Edit::Search::get_find_item());
			$d->{find_input}->SetInsertionPointEnd;
		}, $ID);
		&$add_call( 'replace.item.changed', $ID, sub {
			$d->{replace_input}->SetValue(Kephra::Edit::Search::get_replace_item());
			$d->{replace_input}->SetInsertionPointEnd;
		}, $ID);

		Kephra::API::EventTable::add_call('find.item.history.changed', $ID, sub {
			Kephra::App::_ref()->Yield();
			my $cb = $d->{find_input};
			$Kephra::temp{dialog}{search}{control} = 1;
			$cb->Clear();
			$cb->Append($_) for @{ Kephra::Edit::Search::get_find_history() };
			$cb->SetValue( Kephra::Edit::Search::get_find_item() );
			$cb->SetInsertionPointEnd;
			$Kephra::temp{dialog}{search}{control} = 0;
		}, $ID);
		Kephra::API::EventTable::add_call('replace.item.history.changed', $ID, sub {
			my $cb = $d->{replace_input};
			$Kephra::temp{dialog}{search}{control} = 1;
			$cb->Clear();
			$cb->Append($_) for @{ Kephra::Edit::Search::get_replace_history() };
			$cb->SetValue( Kephra::Edit::Search::get_replace_item() );
			$cb->SetInsertionPointEnd;
			$Kephra::temp{dialog}{search}{control} = 0;
		}, $ID);

		# detecting and selecting search range
		# if selection is just on one line
		if ( $edit_panel->LineFromPosition( $edit_panel->GetSelectionStart )
			!= $edit_panel->LineFromPosition( $edit_panel->GetSelectionEnd ) ) {
			$attr->{in} = 'selection';
			$d->{selection_radio}->SetValue(1);
		} elsif ( $attr->{in} eq 'open_docs' ) {
			$d->{all_open_radio}->SetValue(1);
		} else {
			$attr->{in} = 'document';
			$d->{document_radio}->SetValue(1);
		}

		# asembling
		my $option_sizer = Wx::BoxSizer->new(wxVERTICAL);
		$option_sizer->Add( $d->{inc_box},   0, wxTOP,  0 );
		$option_sizer->Add( $d->{case_box},  0, wxTOP, 15 );
		$option_sizer->Add( $d->{begin_box}, 0, wxTOP,  5 );
		$option_sizer->Add( $d->{word_box},  0, wxTOP,  5 );
		$option_sizer->Add( $d->{regex_box}, 0, wxTOP,  5 );

		my $rbz = Wx::StaticBoxSizer->new( $range_box, wxVERTICAL );
		$rbz->Add( $d->{selection_radio}, 1, wxTOP, 5 );
		$rbz->Add( $d->{document_radio},  1, wxTOP, 5 );
		$rbz->Add( $d->{all_open_radio},  1, wxTOP, 5 );
		my $range_sizer = Wx::BoxSizer->new(wxVERTICAL);
		$range_sizer->Add( $d->{wrap_box}, 0, wxTOP|wxALIGN_CENTER_HORIZONTAL, 0 );
		$range_sizer->Add( $rbz, 0, wxGROW | wxTOP, 10 );

		my $pad_grid = Wx::FlexGridSizer->new( 4, 2, 0 , 1 );
		$pad_grid->Add( $d->{replace_back}, 0, wxBOTTOM, 5);
		$pad_grid->Add( $d->{replace_fore}, 0, wxBOTTOM, 5);
		$pad_grid->Add( $d->{backward_button}, 0, ,0);
		$pad_grid->Add( $d->{foreward_button}, 0, ,0);
		$pad_grid->Add( $d->{fast_back_button},0, ,0);
		$pad_grid->Add( $d->{fast_fore_button},0, ,0);
		$pad_grid->Add( $d->{first_button},    0, ,0);
		$pad_grid->Add( $d->{last_button},     0, ,0);

		my $pads_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
		$pads_sizer->Add( $option_sizer,0,wxALIGN_LEFT  ,0);
		$pads_sizer->Add( $range_sizer ,1,wxALIGN_CENTER|wxLEFT|wxRIGHT|wxGROW ,20);
		$pads_sizer->Add( $pad_grid    ,0,wxALIGN_RIGHT ,0);

		my $button_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
		$button_sizer->Add( $d->{search_button},  0, wxLEFT, 15 );
		$button_sizer->Add( $d->{replace_button}, 0, wxLEFT, 10 );
		$button_sizer->Add( $d->{confirm_button}, 0, wxLEFT, 10 );
		$button_sizer->AddStretchSpacer;
		$button_sizer->Add( $d->{close_button},   0, wxALIGN_RIGHT|wxRIGHT, 15 );

		my $b_grid = Wx::FlexGridSizer->new( 3, 2, 10, 0 );
		$b_grid->Add($d->{find_label}, 0, wxLEFT | wxRIGHT | wxALIGN_CENTER_VERTICAL | wxALIGN_RIGHT, 10);
		$b_grid->Add($d->{find_input}, 0, wxTOP, 0);
		$b_grid->Add($d->{replace_label}, 0, wxLEFT | wxRIGHT | wxALIGN_CENTER_VERTICAL | wxALIGN_RIGHT, 10);
		$b_grid->Add($d->{replace_input}, 0, wxTOP, 0);
		$b_grid->AddSpacer(5);
		$b_grid->Add($pads_sizer, 1, wxTOP|wxGROW, 5);

		my $d_sizer = Wx::BoxSizer->new(wxVERTICAL);
		$d_sizer->Add($b_grid,          1, wxTOP                            , 15);
		$d_sizer->Add($d->{sep_line},   0, wxTOP | wxALIGN_CENTER_HORIZONTAL | wxGROW,  8);
		$d_sizer->Add($button_sizer,    0, wxTOP | wxBOTTOM | wxGROW        ,  9);

		$d->SetSizer($d_sizer);
		$d->SetAutoLayout(1);
		#$d->Fit;

		# go
		$d->Show(1);
		return $d;
	} else {
		my $d = _ref();
		$d->Iconize(0);
		$d->Raise;
		return $d;
	}
}

# end of dialog constuction
##########################
# dialog event functions


# switch back from search in text selection to search in document
# because if once looked in selection the finding is selected and this 
# settings makes no longer sense
sub no_sel_range {
	my $dialog = $Kephra::app{dialog}{search};
	if ( $dialog->{selection_radio}->GetValue ) {
		$dialog->{document_radio}->SetValue(1);
		$Kephra::config{search}{attribute}{in} = 'document';
	}
	#$dialog->Refresh; #$dialog->Layout();
}


# find input function
sub find_input_keyfilter {
	my ( $input, $event ) = @_;
	my $dialog = $Kephra::app{dialog}{search};
	my $wx_frame = $dialog->GetParent;
	my $key_code = $event->GetKeyCode;
	if ($key_code == WXK_RETURN) {
		no_sel_range();
		if    ($event->ControlDown){Kephra::Edit::Search::find_first(); $dialog->Close; } 
		elsif ($event->ShiftDown  ){Kephra::Edit::Search::find_prev() }
		else                       {Kephra::Edit::Search::find_next() }
		return;
	}
	elsif ($key_code == WXK_ESCAPE) { $dialog->Close }
	elsif ($key_code == WXK_TAB){
		if ( $event->ShiftDown ) { $dialog->{close_button}->SetFocus } 
		else                     { $dialog->{replace_input}->SetFocus}
	}
	$event->Skip;
}

my %color = (
	norm_fore => Wx::Colour->new( 0x00, 0x00, 0x55 ),
	norm_back => Wx::Colour->new( 0xff, 0xff, 0xff ),
	alert_fore => Wx::Colour->new( 0xff, 0x33, 0x33 ),
	alert_back => Wx::Colour->new( 0xff, 0xff, 0xff ),
);

sub colour_find_input {
	my $input = $Kephra::app{dialog}{search}{find_input};
	my $pos   = $input->GetInsertionPoint;
	my $found_something = $Kephra::temp{search}{item}{foundpos} > -1
		? 1 : 0;
	return if $Kephra::temp{dialog}{search}{colored} eq $found_something;
	$Kephra::temp{dialog}{search}{colored} = $found_something;
	if ($found_something){
			$input->SetForegroundColour( $color{norm_fore} );
			$input->SetBackgroundColour( $color{norm_back} );
		} else {
			$input->SetForegroundColour( $color{alert_fore} );
			$input->SetBackgroundColour( $color{alert_back} );
	}
	$input->SetInsertionPoint($pos);
	$input->Refresh;
}

sub incremental_search {
	if ( $Kephra::config{search}{attribute}{incremental}
		and not $Kephra::temp{dialog}{search}{control} ) {
		my $input = $Kephra::app{dialog}{search}{find_input};
		Kephra::Edit::Search::set_find_item($input->GetValue);
		Kephra::Edit::Search::first_increment();
	}
}

# replace input function
sub replace_input_keyfilter {
	my ($input, $event) = @_;
	my $dialog = $Kephra::app{dialog}{search};
	my $key_code = $event->GetKeyCode;
	if ($key_code == WXK_RETURN ) {
		if ( $event->ControlDown ) {
			Kephra::Edit::Search::replace_all;
			$dialog->Close;
		} elsif ( $event->AltDown ) { replace_confirm($dialog) }
		else                        { Kephra::Edit::Search::replace_all() }
	}
	if ( $key_code == WXK_ESCAPE) { $dialog->Close }
	elsif ($key_code == WXK_TAB){
		if ( $event->ShiftDown ) { $dialog->{find_input}->SetFocus } 
		else                     { $dialog->{inc_box}->SetFocus }
	}
	$event->Skip;
}

sub replace_all { Kephra::Edit::Search::replace_all() }
sub replace_confirm { Kephra::Edit::Search::replace_confirm() }

sub quit_search_dialog {
	my ( $win, $event ) = @_;
	my $config = $Kephra::config{dialog}{search};
	($config->{position_x}, $config->{position_y} ) = $win->GetPositionXY
		if $config->{save_position} == 1;

	$Kephra::temp{dialog}{search}{active} = 0;
	$Kephra::temp{dialog}{active}--;

	Kephra::API::EventTable::del_own_subscriptions( _ID() );

	$win->Destroy();
}
#######################
1;
