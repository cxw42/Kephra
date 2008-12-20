package Kephra::File;
our $VERSION = '0.42';

use strict;
use warnings;

########################################################
# file save events, drag n drop files, file menu calls #
########################################################

use Wx qw(wxYES wxNO wxCANCEL);

###############
# file events #
###############

sub savepoint_left {
	$Kephra::temp{document}{modified}++
		unless $Kephra::temp{current_doc}{modified};
	$Kephra::temp{current_doc}{modified} = 1;
	Kephra::App::TabBar::refresh_current_label()
		if $Kephra::config{app}{tabbar}{info_symbol};
	Kephra::API::EventTable::trigger('document.savepoint');
}
sub savepoint_reached {
	$Kephra::temp{document}{modified}-- 
		if $Kephra::temp{current_doc}{modified};
	$Kephra::temp{current_doc}{modified} = 0;
	Kephra::App::TabBar::refresh_current_label();
	Kephra::API::EventTable::trigger('document.savepoint');
}

sub can_save     { $Kephra::temp{current_doc}{modified} }
sub can_save_all { $Kephra::temp{document}{modified} }

sub changed_notify_check {
	my $current_doc = Kephra::Document::current_nr();
	for my $file_nr ( @{ Kephra::Document::all_nr() } ) {
		my $path = Kephra::Document::get_file_path($file_nr);
		my $last_check = Kephra::Document::get_tmp_value('did_notify', $file_nr);
		next unless $path;
		if (not -e $path) {
			next if defined $last_check and $last_check eq 'ignore';
			Kephra::Document::Change::to_number( $file_nr );
			Kephra::Dialog::notify_file_deleted( $file_nr );
			next;
		}
		my $last_change = Kephra::Document::get_tmp_value('file_changed', $file_nr);
		my $current_age= Kephra::File::IO::get_age($path);
		if ( $last_change != $current_age) {
			next if defined $last_check
				and ( $last_check eq 'ignore' or $last_check >= $current_age);
			Kephra::Document::Change::to_number( $file_nr );
			Kephra::Document::get_tmp_value
				('did_notify', _remember_save_moment($path), $file_nr);
			Kephra::Dialog::notify_file_changed( $file_nr, $current_age );
		}
	}
	Kephra::Document::Change::to_number($current_doc) 
		unless $current_doc == Kephra::Document::current_nr();
}

sub _remember_save_moment {
	my ($path, $doc_nr) = @_;
	return unless -e $path;
	my $age = Kephra::File::IO::get_age($path);
	Kephra::Document::set_tmp_value( 'file_changed', $age, $doc_nr);
	return $age;
}

###############
# drag n drop #
###############

# add all currently dnd-held files
sub add_dropped {
	my ($ep, $event) = @_;
	-d $_ ? add_dir($_) : Kephra::Document::Internal::add($_) for $event->GetFiles;
}

# add all files of an dnd-held dir
sub add_dir{
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
		} else { Kephra::Document::Internal::add($path) }
	}
}

###################
# file menu calls #
###################

sub new {
	my $doc_nr = Kephra::Document::Internal::new_if_allowed('new');
	Kephra::Document::Internal::reset();
	Kephra::Document::set_current_nr( $doc_nr );
}

sub add { &Kephra::Document::Internal::add }

sub open {
	# buttons dont freeze while computing
	Kephra::App::_ref()->Yield();

	# file selector dialog
	my $files = Kephra::Dialog::get_files_open( Kephra::App::Window::_ref(),
		$Kephra::localisation{dialog}{file}{open},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all}
	);
	# opening selected files
	if (ref $files eq 'ARRAY') { Kephra::Document::Internal::add($_) for @$files }
}

sub open_all_of_dir{
	my $dir = Kephra::Dialog::get_dir(
		$Kephra::localisation{dialog}{file}{open_dir}, 
		$Kephra::config{file}{current}{directory}
	);
	add_dir( $dir );
}

sub reload { reload_current(@_) } # alias
sub reload_current {
	my $file_path = Kephra::Document::get_file_path();
	my $nr = Kephra::Document::current_nr();
	if ($file_path and -e $file_path){
		my $ep = Kephra::App::EditPanel::_ref();
		Kephra::Document::Internal::save_properties();
		$ep->BeginUndoAction;
		$ep->SetText("");
		Kephra::File::IO::open_pipe( $file_path );
		$ep->EndUndoAction;
		$ep->SetSavePoint;
		Kephra::Document::Internal::eval_properties();
		Kephra::App::EditPanel::Margin::autosize_line_number()
			if ($Kephra::config{editpanel}{margin}{linenumber}{autosize}
			and $Kephra::config{editpanel}{margin}{linenumber}{width} );
		_remember_save_moment($file_path);
	} else {}
}


sub reload_all { 
	Kephra::Document::do_with_all( sub { reload_current() } )
}


sub insert {
	my $insertfilename = Kephra::Dialog::get_file_open( Kephra::App::Window::_ref(),
		$Kephra::localisation{dialog}{file}{insert},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all}
	);
	if ( -e $insertfilename ) {
		my $ep = Kephra::App::EditPanel::_ref();
		my $text = Kephra::File::IO::open_buffer($insertfilename);
		$ep->InsertText( $ep->GetCurrentPos, $text );
	}
}

sub save         { save_current(@_) }
sub save_current {
	my ($ctrl, $event) = @_;
	my $ep = Kephra::App::EditPanel::_ref();
	my $file_name   = Kephra::Document::get_file_path();
	my $save_config = $Kephra::config{file}{save};
	if ( $ep->GetModify == 1 or $save_config->{unchanged} ) {
		if ( $file_name and -e $file_name ) {
			if (not -w $file_name ) {
				my $err_msg = $Kephra::localisation{dialog}{error};
				Kephra::Dialog::warning_box( Kephra::App::Window::_ref(),
					$err_msg->{write_protected}."\n".$err_msg->{write_protected2},
					$err_msg->{file} );
				save_as();
			} else {
				rename $file_name, $file_name . '~'
					if $Kephra::config{file}{save}{tilde_backup} == 1;
				Kephra::File::IO::write_buffer( $file_name, $ep->GetText );
				# reloads the needed configs if the file was a config file
				Kephra::Config::Global::eval_config_file($file_name)
					if $save_config->{reload_config} == 1
					and Kephra::Document::_get_attribute('config_file');
				_remember_save_moment($file_name);
				$ep->SetSavePoint;
			}
		} else { save_as() }
	}
}


sub save_as {
	my $file_name = Kephra::Dialog::get_file_save(
		Kephra::App::Window::_ref(),
		$Kephra::localisation{dialog}{file}{save_as},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all}
	);
	if (    $file_name
	    and Kephra::Document::Internal::check_b4_overwite($file_name) ) {

		my $ep = Kephra::App::EditPanel::_ref();
		my $oldname = Kephra::Document::get_file_path();
		$Kephra::temp{document}{loaded}++ if defined $oldname and $oldname;

		Kephra::Document::set_file_path($file_name);
		Kephra::File::IO::write_buffer($file_name, $ep->GetText );
		$ep->SetSavePoint();
		Kephra::Document::SyntaxMode::change_to('auto');
		Kephra::Document::Internal::save_properties();
		$Kephra::config{file}{current}{directory} = 
			$Kephra::temp{current_do}{directory};
		_remember_save_moment($file_name);
		Kephra::API::EventTable::trigger('document.list');
	}
}


sub save_copy_as {
	my $file_name = Kephra::Dialog::get_file_save( Kephra::App::Window::_ref(),
		$Kephra::localisation{dialog}{file}{save_copy_as},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all} );
	Kephra::File::IO::write_buffer
		( $file_name, Kephra::App::EditPanel::_ref()->GetText )
		if $file_name and Kephra::Document::Internal::check_b4_overwite($file_name);
}


sub rename {
	my $new_path_name = Kephra::Dialog::get_file_save( Kephra::App::Window::_ref(),
		$Kephra::localisation{dialog}{file}{rename},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all} );
	if ($new_path_name){
		my $old_path_name = Kephra::Document::get_file_path();
		rename $old_path_name, $new_path_name if $old_path_name;
		Kephra::Document::set_file_path($new_path_name);
		Kephra::Document::SyntaxMode::change_to('auto');
		$Kephra::config{file}{current}{directory} = 
			$Kephra::temp{current_doc}{directory};
		Kephra::API::EventTable::trigger('document.list');
		_remember_save_moment($new_path_name);
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
	my $cdoc_nr = Kephra::Document::current_nr();
	for my $doc_nr  ( @{ Kephra::Document::all_nr()} ) {
		$need_save_other = 1 if $doc_nr != $cdoc_nr
						and Kephra::Document::Internal::get_tmp_value('name', $doc_nr)
						and Kephra::Document::Internal::get_tmp_value('modified', $doc_nr);
	}
	if ($need_save_other) {
		Kephra::Document::do_with_all( sub {
			my $file = shift;
			save_current() if $file->{modified} and $file->{name};
		} );
	} elsif (can_save() and Kephra::Document::get_file_path()) {
		save_current();
	}
}

sub print {
	require Wx::Print;
	my ( $frame, $event ) = @_;
	my $ep       = Kephra::App::EditPanel::_ref();
	my $printer  = Wx::Printer->new;
	my $printout = Wx::Printout->new(
		"$Kephra::NAME $Kephra::VERSION : " . Kephra::Document::file_name()
	);
	#$ep->FormatRange(doDraw,startPos,endPos,draw,target,renderRect,pageRect);
	#$printer->Print( $frame, $printout, 1 );

	$printout->Destroy;
}

sub close { close_current(@_) }
sub close_current {
	my ( $frame, $event ) = @_;
	my $ep           = Kephra::App::EditPanel::_ref();
	my $config       = $Kephra::config{file}{save};
	my $save_answer  = wxNO;

	# save text if options demand it
	if ($ep->GetModify == 1 or $config->{unchanged} eq 1) {
		if ($ep->GetTextLength > 0 or $config->{empty} eq 1) {
			if ($config->{b4_close} eq 'ask' or $config->{b4_close} eq '2'){
				my $l10n = $Kephra::localisation{dialog}{file};
				$save_answer = Kephra::Dialog::get_confirm_3( 
					Kephra::App::Window::_ref(),
					$l10n->{save_current}, $l10n->{close_unsaved} );
			}
			return if $save_answer == wxCANCEL;
			if ($save_answer == wxYES or $config->{b4_close} eq '1')
				{ save_current() }
			else{ savepoint_reached() if $ep->GetModify }
		}
	}

	# proceed
	close_unsaved($frame, $event);
}


sub close_other {
	my $doc_nr = Kephra::Document::current_nr();
	Kephra::Document::Change::to_number(0);
	$_ != $doc_nr ? close_current() : Kephra::Document::Change::to_number(1)
		for @{ Kephra::Document::all_nr() };
}

sub close_all { close_current() for @{ Kephra::Document::all_nr() } }

sub close_unsaved         {&close_current_unsaved}
sub close_current_unsaved {
	my ( $frame, $event ) = @_;
	my $ep           = Kephra::App::EditPanel::_ref();
	my $close_tab_nr = Kephra::Document::current_nr();
	my $path         = Kephra::Document::get_file_path();

	# empty last document
	if ( $Kephra::temp{document}{buffer} == 1 ) {
		$Kephra::temp{file}{current}{loaded} = 0;
		Kephra::Document::Internal::reset();
	}

	# close document
	elsif ( $Kephra::temp{document}{buffer} > 1 ) {
		# select to which file nr to jump
		my $new_tab_nr = $close_tab_nr + 1;
		if ( defined $Kephra::document{open}[$new_tab_nr] ) {
			Kephra::Document::Change::to_number($new_tab_nr);
			$Kephra::document{current_nr}--;
		} else {
			$new_tab_nr -= 2;
			Kephra::Document::Change::to_number($new_tab_nr);
		}
		$Kephra::temp{document}{buffer}--;
		$Kephra::temp{document}{loaded}--
			if ( $Kephra::document{open}[$close_tab_nr]{file_path} );
		Kephra::App::TabBar::delete_tab($close_tab_nr);

		# release file data of closed file
		if (ref $Kephra::document{open} eq 'ARRAY' ) {
			splice @{$Kephra::document{open}}, $close_tab_nr, 1;
			splice @{$Kephra::temp{document}{open}}, $close_tab_nr, 1;
		}

		#set correct internal pointer to new current file
		Kephra::Document::set_current_nr( Kephra::Document::current_nr() );
		Kephra::App::TabBar::refresh_all_label();
	}
	#
	Kephra::App::EditPanel::Margin::reset_line_number_width();
	Kephra::API::EventTable::trigger('document.list');
	#remember filepath in history
	Kephra::File::History::add( $path );
}

sub close_all_unsaved { close_unsaved() for @{ Kephra::Document::all_nr() } }

sub close_other_unsaved {
	my $doc_nr = Kephra::Document::current_nr();
	Kephra::Document::Change::to_number(0);
	$_ != $doc_nr ? close_unsaved() : Kephra::Document::Change::to_number(1)
		for @{ Kephra::Document::all_nr() };
}

1;