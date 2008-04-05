package Kephra::File;
$VERSION = '0.37';

########################################################
# file save events, drag n drop files, file menu calls #
########################################################

use strict;
use Wx qw(wxYES wxNO wxCANCEL);
use Wx::Print;

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
	my $current_doc = Kephra::Document::_get_current_nr();
	for my $file_nr ( 0 .. Kephra::Document::_get_last_nr() ) {
		my $path = Kephra::Document::get_attribute('file_path', $file_nr);
		next unless $path;
		my $remembered = Kephra::Document::get_tmp_value('file_changed', $file_nr);
		unless ( _file_age($path) == $remembered ) {
			Kephra::Document::Change::to_number( $file_nr );
			_remember_save_moment($path);
			Kephra::Dialog::notify_file_change( $file_nr );
		}
	}
	Kephra::Document::Change::to_number($current_doc) 
		unless $current_doc == Kephra::Document::_get_current_nr();
}

sub _remember_save_moment {
	my $path = shift;
	Kephra::Document::set_tmp_value( 'file_changed', _file_age($path) );
}

sub _file_age {
	my $file = shift;
	return unless -e $file;
	return $^T - (-M $file) * 86400;
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
	Kephra::Document::_set_current_nr( $doc_nr );
}

sub add { &Kephra::Document::Internal::add }

sub open {
	# buttons dont freeze while computing
	Kephra::App::_get()->Yield();

	# file selector dialog
	my $files = Kephra::Dialog::get_files_open( Kephra::App::Window::_get(),
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

sub reload { &reload_current } # alias
sub reload_current {
	my $file_path = Kephra::Document::_get_current_file_path();
	my $nr = Kephra::Document::_get_current_nr();
	if ($file_path and -e $file_path){
		my $ep = Kephra::App::EditPanel::_get();
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
	my $insertfilename = Kephra::Dialog::get_file_open( Kephra::App::Window::_get(),
		$Kephra::localisation{dialog}{file}{insert},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all}
	);
	if ( -e $insertfilename ) {
		my $ep = Kephra::App::EditPanel::_get();
		my $text = Kephra::File::IO::open_buffer($insertfilename);
		$ep->InsertText( $ep->GetCurrentPos, $text );
	}
}

sub save_current {
	my ($ctrl, $event) = @_;
	my $ep = Kephra::App::EditPanel::_get();
	my $file_name   = Kephra::Document::_get_current_file_path();
	my $save_config = $Kephra::config{file}{save};
	if ( $ep->GetModify == 1 or $save_config->{unchanged} ) {
		if ( $file_name and -e $file_name ) {
			if (not -w $file_name ) {
				my $err_msg = $Kephra::localisation{dialog}{error};
				Kephra::Dialog::warning_box( Kephra::App::Window::_get(),
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
					and Kephra::Document::get_attribute('config_file');
				_remember_save_moment($file_name);
				$ep->SetSavePoint;
			}
		} else { save_as() }
	}
}


sub save_as {
	my $file_name = Kephra::Dialog::get_file_save( Kephra::App::Window::_get(),
		$Kephra::localisation{dialog}{file}{save_as},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all}
	);
	if (    length($file_name) > 0
		and Kephra::Document::Internal::check_b4_overwite($file_name) ) {

		my $ep = Kephra::App::EditPanel::_get();
		$Kephra::temp{document}{loaded}++
			if length(Kephra::Document::_get_current_file_path) == 0;

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
	my $file_name = Kephra::Dialog::get_file_save( Kephra::App::Window::_get(),
		$Kephra::localisation{dialog}{file}{save_copy_as},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all} );
	Kephra::File::IO::write_buffer
		( $file_name, Kephra::App::EditPanel::_get()->GetText )
		if $file_name and Kephra::Document::Internal::check_b4_overwite($file_name);
}


sub rename {
	my $new_path_name = Kephra::Dialog::get_file_save( Kephra::App::Window::_get(),
		$Kephra::localisation{dialog}{file}{rename},
		$Kephra::config{file}{current}{directory},
		$Kephra::temp{file}{filterstring}{all} );
	if ($new_path_name){
		my $old_path_name = Kephra::Document::_get_current_file_path();
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
	if ($unsaved == 1 and can_save() ) {
		save_current();
	}
	else {
		Kephra::Document::do_with_all( sub {
			save_current() if shift->{modified};
		} );
	}
}

sub save_all_named {
	my $unsaved = can_save_all();
	return unless $unsaved;
	if ($unsaved == 1 and can_save() ) {
		save_current() if Kephra::Document::_get_current_name();
	}
	else {
		Kephra::Document::do_with_all( sub {
			my $file = shift;
			save_current() if $file->{modified} and $file->{name};
		} );
	}
}

sub print {
	my ( $frame, $event ) = @_;
	my $ep       = Kephra::App::EditPanel::_get();
	my $printer  = Wx::Printer->new;
	my $printout = Wx::Printout->new(
		"$Kephra::NAME $Kephra::VERSION : " .
		Kephra::Document::_get_current_name()
	);
	#$ep->FormatRange(doDraw,startPos,endPos,draw,target,renderRect,pageRect);
	#$printer->Print( $frame, $printout, 1 );

	$printout->Destroy;
}

sub close_current {
	my ( $frame, $event ) = @_;
	my $ep           = Kephra::App::EditPanel::_get();
	my $close_tab_nr = Kephra::Document::_get_current_nr();
	my $path         = Kephra::Document::_get_current_file_path();
	my $config       = $Kephra::config{file}{save};
	my $save_answer  = wxNO;

	# save text if options allow it
	if ($ep->GetModify == 1 or $config->{unchanged} eq 1) {
		if ($ep->GetTextLength > 0 or $config->{empty} eq 1) {
			if ($config->{b4_close} eq 'ask' or $config->{b4_close} eq '2'){
				my $l10n = $Kephra::localisation{dialog}{file};
				$save_answer = Kephra::Dialog::get_confirm_3( Kephra::App::Window::_get(),
					$l10n->{save_current}, $l10n->{close_unsaved} );
			}
			return if $save_answer == wxCANCEL;
			if ($save_answer == wxYES or $config->{b4_close} eq '1')
				{ save_current() }
			else{ savepoint_reached() if $ep->GetModify }
		}
	}

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
		Kephra::Document::_set_current_nr($Kephra::document{current_nr});
		Kephra::App::TabBar::refresh_all_label();
	}
	#
	Kephra::App::EditPanel::Margin::reset_line_number_width();
	Kephra::API::EventTable::trigger('document.list');
	#remember filepath in history
	Kephra::File::History::add( $path );
}


sub close_other {
	my $doc_nr = Kephra::Document::_get_current_nr();
	Kephra::Document::Change::to_number(0);
	$_ != $doc_nr ? close_current() : Kephra::Document::Change::to_number(1)
		for 0 .. Kephra::Document::_get_last_nr();
}


sub close_all { close_current() for 0 .. Kephra::Document::_get_last_nr() }

1;#Kephra::Dialog::msg_box(undef, $file_name, '');