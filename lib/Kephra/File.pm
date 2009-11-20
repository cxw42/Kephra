package Kephra::File;
our $VERSION = '0.44';

use strict;
use warnings;

=pod
=head1 NAME

Kephra::File - App side of IO functions

=head1 DESCRIPTION

file menu calls

drag n drop files

file save events
 
=cut


sub _dialog_l18n { Kephra::Config::Localisation::strings()->{dialog} }
#
# file events #
#
sub savepoint_left {
	my $doc_nr = shift;
	$doc_nr = Kephra::Document::Data::current_nr() if not defined $doc_nr or ref $doc_nr;
	Kephra::Document::Data::inc_value('modified')
		unless Kephra::Document::Data::get_attribute('modified', $doc_nr);
	Kephra::Document::Data::set_attribute('modified', 1, $doc_nr);
	Kephra::App::TabBar::refresh_label($doc_nr)
		if $Kephra::config{app}{tabbar}{info_symbol};
	Kephra::EventTable::trigger('document.savepoint');
}
sub savepoint_reached {
	my $doc_nr = shift;
	$doc_nr = Kephra::Document::Data::current_nr() if not defined $doc_nr or ref $doc_nr;
	Kephra::Document::Data::dec_value('modified')
		if Kephra::Document::Data::get_attribute('modified', $doc_nr);
	Kephra::Document::Data::set_attribute('modified', 0, $doc_nr);
	Kephra::App::TabBar::refresh_label($doc_nr);
	Kephra::EventTable::trigger('document.savepoint');
}

sub can_save     { Kephra::Document::Data::attr('modified') }
sub can_save_all { Kephra::Document::Data::get_value('modified') }

sub changed_notify_check {
	my $current_doc = Kephra::Document::Data::current_nr();
	for my $file_nr ( @{ Kephra::Document::Data::all_nr() } ) {
		my $file = Kephra::Document::Data::get_file_path($file_nr);
		my $last_check = Kephra::Document::Data::get_attribute
			('did_notify', $file_nr);
		next unless $file;
		if (not -e $file) {
			next if defined $last_check and $last_check eq 'ignore';
			Kephra::Document::Change::to_number( $file_nr );
			Kephra::Dialog::notify_file_deleted( $file_nr );
			next;
		}
		my $last_change = Kephra::Document::Data::get_attribute('file_changed', $file_nr);
		my $current_age = Kephra::File::IO::get_age($file);
		if ( $last_change != $current_age) {
			next if defined $last_check
				and ( $last_check eq 'ignore' or $last_check >= $current_age);
			Kephra::Document::Change::to_number( $file_nr );
			Kephra::Document::Data::set_attribute
				('did_notify', _remember_save_moment($file_nr), $file_nr);
			Kephra::Dialog::notify_file_changed( $file_nr, $current_age );
		}
	}
	Kephra::Document::Change::to_number($current_doc) 
		unless $current_doc == Kephra::Document::Data::current_nr();
}

sub _remember_save_moment {
	my ($doc_nr) = shift || Kephra::Document::Data::current_nr();
	my $path = Kephra::Document::Data::get_file_path($doc_nr) || shift;
	return unless defined $path and -e $path;
	my $age = Kephra::File::IO::get_age($path);
	Kephra::Document::Data::set_attribute('file_changed', $age, $doc_nr);
	return $age;
}

sub check_b4_overwite {
	my $file = shift;
	$file = Kephra::Document::Data::get_file_path() unless $file;
	my $allow = $Kephra::config{file}{save}{overwrite};
	if ( -e $file ) {
		my $frame = Kephra::App::Window::_ref();
		my $label = Kephra::Config::Localisation::strings()->{dialog};
		if ( $allow eq 'ask' ) {
			my $answer = Kephra::Dialog::get_confirm_2( $frame,
				"$label->{general}{overwrite} $file ?",
				$label->{file}{overwrite},
				-1, -1
			);
			return 1 if $answer == &Wx::wxYES;
			return 0 if $answer == &Wx::wxNO;
		} else {
			Kephra::Dialog::info_box( $frame,
				$label->{general}{dont_allow},
				$label->{file}{overwrite}
			) unless $allow;
			return $allow;
		}
	} else { return -1 }
}
#
# drag n drop
#
sub add_dropped { # add all currently dnd-held files
	my ($ep, $event) = @_;
	-d $_ ? add_dir($_) : Kephra::Document::add($_) for $event->GetFiles;
}

sub add_dir{ # add all files of an dnd-held dir
	my $dir = shift;
	return until -d $dir;
	opendir (my $DH, $dir);
	my @dir_items = readdir($DH);
	closedir($DH);
	my $path;
	my $recursive = $Kephra::config{file}{open}{dir_recursive};

	foreach (@dir_items) {
		$path = "$dir/$_";
		if (-d $path) {
			next if not $recursive or $_ eq '.' or $_ eq '..';
			add_dir($path);
		} else { Kephra::Document::add($path) }
	}
}

#
# file menu calls
#
sub new  { Kephra::Document::new() }
sub open {
	# buttons dont freeze while computing
	Kephra::App::_ref()->Yield();

	# file selector dialog
	my $files = Kephra::Dialog::get_files_open( Kephra::App::Window::_ref(),
		_dialog_l18n()->{file}{open},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all}
	);
	# opening selected files
	if (ref $files eq 'ARRAY') { Kephra::Document::add($_) for @$files }
}

sub open_all_of_dir {
	my $dir = Kephra::Dialog::get_dir(
		_dialog_l18n()->{file}{open_dir}, $Kephra::config{file}{current}{directory}
	);
	add_dir( $dir );
}

sub reload          { reload_current(@_) } # alias
sub reload_current  {
	my $file_path = Kephra::Document::Data::get_file_path();
	my $doc_nr = Kephra::Document::Data::current_nr();
	if ($file_path and -e $file_path){
		my $ep = Kephra::App::EditPanel::_ref();
		Kephra::Document::Data::update_attributes($doc_nr);
		$ep->BeginUndoAction;
		$ep->SetText("");
		Kephra::File::IO::open_pipe( $file_path );
		$ep->EndUndoAction;
		$ep->SetSavePoint;
		_remember_save_moment();
		Kephra::Document::Data::evaluate_attributes();
		Kephra::App::EditPanel::Margin::autosize_line_number()
			if ($Kephra::config{editpanel}{margin}{linenumber}{autosize}
			and $Kephra::config{editpanel}{margin}{linenumber}{width} );
		Kephra::Document::Data::evaluate_attributes($doc_nr);
	} else {
	}
}
sub reload_all      { Kephra::Document::do_with_all( sub { reload_current() } ) }

sub insert {
	my $insertfilename = Kephra::Dialog::get_file_open( 
		Kephra::App::Window::_ref(),
		_dialog_l18n()->{file}{insert},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all}
	);
	if ( -e $insertfilename ) {
		my $ep = Kephra::App::EditPanel::_ref();
		my $text = Kephra::File::IO::open_buffer($insertfilename);
		$ep->InsertText( $ep->GetCurrentPos, $text );
	}
}
#
sub _save_nr {
	my $nr = shift;
	$nr = Kephra::Document::Data::current_nr() unless defined $nr;
	my $ep = Kephra::Document::Data::_ep( $nr );
	my $file = Kephra::Document::Data::get_file_path($nr);
	return until defined $nr and $ep and -e $file;
	my $save_config = $Kephra::config{file}{save};
	return unless $ep->GetModify == 1 or $save_config->{unchanged};
	rename $file, $file . '~' if $save_config->{tilde_backup} == 1;
	Kephra::File::IO::write_buffer( $file, $ep->GetText );
	$ep->SetSavePoint;
	_remember_save_moment($nr);
}
sub save         { save_current(@_) }
sub save_current {
	my ($ctrl, $event) = @_;
	my $ep = Kephra::App::EditPanel::_ref();
	my $file = Kephra::Document::Data::get_file_path();
	my $save_config = $Kephra::config{file}{save};
	if ( $ep->GetModify == 1 or $save_config->{unchanged} ) {
		if ( $file and -e $file ) {
			if (not -w $file ) {
				my $err_msg = _dialog_l18n()->{error};
				Kephra::Dialog::warning_box( Kephra::App::Window::_ref(),
					$err_msg->{write_protected}."\n".$err_msg->{write_protected2},
					$err_msg->{file} );
				save_as();
			} else {
				_save_nr();
				Kephra::Config::Global::eval_config_file($file)
					if $save_config->{reload_config} == 1
					and Kephra::Document::Data::get_attribute('config_file');
			}
		} else { save_as() }
	}
}

sub save_as {
	my $file = Kephra::Dialog::get_file_save(
		Kephra::App::Window::_ref(),
		_dialog_l18n()->{file}{save_as},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all}
	);
	if ( $file and check_b4_overwite($file) ) {
		my $ep = Kephra::App::EditPanel::_ref();
		my $oldname = Kephra::Document::Data::get_file_path();
		Kephra::Document::Data::inc_value('loaded') unless $oldname;
		Kephra::Document::Data::update_attributes();
		Kephra::Document::Data::set_file_path($file);
		Kephra::File::IO::write_buffer($file, $ep->GetText );
		$ep->SetSavePoint();
		Kephra::Document::SyntaxMode::set('auto');
		Kephra::App::Window::refresh_title();
		Kephra::App::TabBar::refresh_current_label();
		Kephra::App::StatusBar::refresh_all_cells();
		$Kephra::config{file}{current}{directory} = 
			Kephra::Document::Data::get_attribute('directory');
		_remember_save_moment( );
		Kephra::EventTable::trigger('document.list');
	}
}


sub save_copy_as {
	my $file = Kephra::Dialog::get_file_save(
		Kephra::App::Window::_ref(),
		_dialog_l18n()->{file}{save_copy_as},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all}
	);
	Kephra::File::IO::write_buffer
		( $file, Kephra::App::EditPanel::_ref()->GetText )
		if $file and check_b4_overwite($file);
}


sub rename   {
	my $new_path_name = Kephra::Dialog::get_file_save(
		Kephra::App::Window::_ref(),
		_dialog_l18n()->{file}{rename},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all} );
	if ($new_path_name){
		my $old_path_name = Kephra::Document::Data::get_file_path();
		rename $old_path_name, $new_path_name if $old_path_name;
		Kephra::Document::Data::set_file_path($new_path_name);
		Kephra::Document::SyntaxMode::set('auto');
		$Kephra::config{file}{current}{directory} = 
			Kephra::Document::Data::get_attribute('directory');
		Kephra::EventTable::trigger('document.list');
		_remember_save_moment();
	}
}


sub save_all {
	my $unsaved = can_save_all();
	return unless $unsaved;
	# save surrent if its the only
	if ($unsaved == 1 and can_save() ) {
		save_current();
	}
	#
	else {
		Kephra::Document::do_with_all( sub {
			save_current() if shift->{modified};
		} );
	}
}

sub save_all_named {
	my $unsaved = can_save_all();
	return unless $unsaved;
	my $need_save_other;
	my $cdoc_nr = Kephra::Document::Data::current_nr();
	for my $doc_nr  ( @{ Kephra::Document::Data::all_nr()} ) {
		my ($name, $mod) = @{Kephra::Document::Data::attributes(['file_name', 'modified'], $doc_nr) };
		$need_save_other = 1 if $doc_nr != $cdoc_nr and $name and $mod;
	}
	if ($need_save_other) {
		Kephra::Document::do_with_all( sub {
			my $file = shift;
			save_current() if $file->{modified} and $file->{file_name};
		} );
	} elsif (can_save() and Kephra::Document::Data::get_file_path()) {
		save_current();
	}
}

sub print {
	require Wx::Print;
	my ( $frame, $event ) = @_;
	my $ep       = Kephra::App::EditPanel::_ref();
	my $printer  = Wx::Printer->new;
	my $printout = Wx::Printout->new(
		"$Kephra::NAME $Kephra::VERSION : " . Kephra::Document::Data::file_name()
	);
	#$ep->FormatRange(doDraw,startPos,endPos,draw,target,renderRect,pageRect);
	#$printer->Print( $frame, $printout, 1 );

	$printout->Destroy;
}

sub close { close_current() }
sub close_current { close_nr( Kephra::Document::Data::current_nr() ) }
sub close_nr {
	my $doc_nr     = shift;
	my $ep         = Kephra::Document::Data::_ep($doc_nr);
	my $config     = $Kephra::config{file}{save};
	my $save_answer= &Wx::wxNO;

	# save text if options demand it
	if ($ep->GetModify == 1 or $config->{unchanged} eq 1) {
		if ($ep->GetTextLength > 0 or $config->{empty} eq 1) {
			if ($config->{b4_close} eq 'ask' or $config->{b4_close} eq '2'){
				my $l10n = _dialog_l18n()->{file};
				$save_answer = Kephra::Dialog::get_confirm_3( 
					Kephra::App::Window::_ref(),
					$l10n->{save_current}, $l10n->{close_unsaved} );
			}
			return if $save_answer == &Wx::wxCANCEL;
			if ($save_answer == &Wx::wxYES or $config->{b4_close} eq '1')
				{ _save_nr($doc_nr) }
			else{ savepoint_reached($doc_nr) if $ep->GetModify }
		}
	}

	# proceed
	close_nr_unsaved($doc_nr);
}

sub close_other   {
	my $doc_nr = Kephra::Document::Data::current_nr();
	Kephra::Document::Change::to_number(0);
	$_ != $doc_nr ? close_current() : Kephra::Document::Change::to_number(1)
		for @{ Kephra::Document::Data::all_nr() };
}

sub close_all     { close_current($_) for @{ Kephra::Document::Data::all_nr() } }
sub close_unsaved { close_current_unsaved() }
sub close_current_unsaved { close_nr_unsaved( Kephra::Document::Data::current_nr()) }
sub close_nr_unsaved {
	my $close_nr = shift;
	my $current  = Kephra::Document::Data::current_nr();
	my $ep       = Kephra::Document::Data::_ep($close_nr);
	my $file     = Kephra::Document::Data::get_file_path($close_nr);
	my $buffer   = Kephra::Document::Data::get_value('buffer');

	# empty last document
	if ( $buffer == 1 ) {
		Kephra::Document::Data::set_value('loaded', 0);
		Kephra::Document::reset(0);
	}
	# close document
	elsif ( $buffer > 1 ) {
		# select to which file nr to jump
		my $close_last = $close_nr == Kephra::Document::Data::last_nr();
		my $switch     = $close_nr == $current; 
		Kephra::Document::Data::dec_value('buffer');
		Kephra::Document::Data::dec_value('loaded')
			if Kephra::Document::Data::get_file_path( $close_nr );
		if ($switch){
			$close_last
				? Kephra::Document::Change::to_number( $close_nr - 1 )
				: Kephra::Document::Change::to_number( $close_nr + 1 );
		}
		Kephra::App::TabBar::delete_tab_by_doc_nr( $close_nr );
		Kephra::Document::Data::delete_slot( $close_nr );
		Kephra::Document::Data::set_current_nr( $close_nr ) unless $close_last and $switch;
	}
	Kephra::App::EditPanel::gets_focus();
	Kephra::App::EditPanel::Margin::reset_line_number_width();
	Kephra::EventTable::trigger('document.list');
	# remember filepath in history
	Kephra::File::History::add( $file );
}

sub close_all_unsaved { close_current_unsaved() for @{ Kephra::Document::Data::all_nr() } }
sub close_other_unsaved {
	my $doc_nr = Kephra::Document::Data::current_nr();
	Kephra::Document::Change::to_number(0);
	$_ != $doc_nr ? close_unsaved() : Kephra::Document::Change::to_number(1)
		for @{ Kephra::Document::Data::all_nr() };
}

1;