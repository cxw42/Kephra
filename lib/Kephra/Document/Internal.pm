package Kephra::Document::Internal;
our $VERSION = '0.12';

use strict;
use warnings;

use Wx qw(wxYES wxNO);


sub attributes  { $Kephra::document{open}       } 
sub temp_data   { $Kephra::temp{document}{open} }
sub count       { @{ attributes() }             }

sub last_nr     { $#{ $Kephra::document{open} } }
sub previous_nr { 
	if (defined $_[0]) { $Kephra::document{previous_nr} = validate_nr($_[0]) }
	else               { $Kephra::document{previous_nr} }
}
sub current_nr { 
	if (defined $_[0]) {
		my $nr = shift;
		return if $nr < 0 or $nr > count();
		$Kephra::document{current_nr} = $nr;
		$Kephra::document{current}    = attributes()->[$nr];
		$Kephra::temp{current_doc}    = temp_data()->[$nr];
	} else { $Kephra::document{current_nr} }
}
sub get_current_nr { current_nr() }
sub set_current_nr { current_nr(@_) if @_ }
sub all_nr         { [ 0 .. last_nr() ]   }

sub validate_nr { 
	my $nr = shift;
	if (defined $nr) {
		$nr = int $nr;
		if (exists temp_data()->[$nr]) {
			return $nr;
		} else {
			if ($nr < 0) { return 0 }
			else         { return count()-1 }
		}
	} else { 
		return current_nr()
	}
}

####################################################################

sub get_attribute {
	my $attr = shift or return;
	return unless $attr;
	my $nr = validate_nr(shift);
	my $docs = attributes();
	return unless ref $docs eq 'ARRAY';
	$docs->[ $nr ]{$attr};
}

sub set_attribute {
	my $attr = shift;
	my $value = shift;
	return unless $value;
	my $nr = validate_nr(shift);
	attributes()->[ $nr ]{$attr} = $value
}

sub get_tmp_value {
	my $name = shift;
	return unless $name;
	my $nr = validate_nr(shift);
	my $tmp_data = $Kephra::temp{document}{open};
	$tmp_data->[ $nr ]{$name} if ref $tmp_data->[ $nr ] eq 'HASH';
}

sub set_tmp_value {
	my $name = shift;
	my $value = shift;
	return unless $value;
	my $nr = validate_nr(shift);
	$Kephra::temp{document}{open}[ $nr ]{$name} = $value
}

####################################################################

sub get_file_path { get_attribute('file_path', $_[0]) }
sub set_file_path {
	my ( $file_path, $doc_nr ) = @_;
	$doc_nr = validate_nr($doc_nr);
	set_attribute('file_path', $file_path, $doc_nr);
	dissect_path( $file_path, $doc_nr );
	Kephra::App::TabBar::refresh_label($doc_nr);
	Kephra::App::Window::refresh_title();
}

sub dissect_path {
	my ($file_path, $doc_nr) = @_;
	$doc_nr = validate_nr($doc_nr);
	my $doc_data = temp_data()->[$doc_nr];
	my ($volume, $directories, $file) = File::Spec->splitpath( $file_path );
	$directories = $volume.$directories if $volume;
	$doc_data->{directory} = $directories;
	$doc_data->{name}      = $file;

	if ( length($file) > 0 ) {
		my @filenameparts = split /\./, $file ;
		$doc_data->{ending} = pop @filenameparts if @filenameparts > 1;
		$doc_data->{firstname} = join '.', @filenameparts;
	}
}
####################################################################

# create a new document if settings allow it
sub new_if_allowed {
	# new(empty), add(open) restore(open session)
	my $mode = shift;
	my $ep  = Kephra::App::EditPanel::_ref();
	my $file_name = get_file_path();
	my $old_doc_nr= current_nr();
	my $doc_nr    = $Kephra::temp{document}{buffer};
	my $config    = $Kephra::config{file}{open};

	# check settings
	# in single doc mode close previous doc first
	if ( $config->{single_doc} == 1 ) {
		Kephra::File::close_current();
		return 0;
	}
	unless ( $mode eq 'new' ) {
		if ($ep->GetText eq '' 
		and $ep->GetModify == 0 
		and ( !$file_name or !-e $file_name ) ){
			return $old_doc_nr
				if ($config->{into_empty_doc} == 1)
				or ($config->{into_only_empty_doc} == 1
					and $Kephra::temp{document}{buffer} == 1 );
		}
	}

	# still there? ok now we make a new document
	temp_data()->[$doc_nr]{pointer}= $ep->CreateDocument;
	$Kephra::temp{document}{buffer}++;

	change_pointer($doc_nr);
	Kephra::App::TabBar::add_tab();
	Kephra::App::TabBar::set_current_page($doc_nr);
	return $doc_nr;
}


# restore once opened file from his settings
sub restore {
	my %file_settings = %{ shift; };
	my $file_name = $file_settings{file_path};
	my $attr = attributes();
	if ( -e $file_name ) {

		# open only text files and empty files
		return if !-z $file_name and -B $file_name
			and ( $Kephra::config{file}{open}{only_text} == 1 );
		# check if file is already open and goto this already opened
		if ( $Kephra::config{file}{open}{each_once} == 1 ){
			for (  0 .. last_nr() ) {
				return if $attr->[$_]{file_path} eq $file_name;
			}
		}

		my $doc_nr = new_if_allowed('restore');
		load_in_current_buffer($file_name);
		%{ $attr->[$doc_nr] } = %file_settings;
		set_file_path($file_name, $doc_nr);
		Kephra::App::TabBar::refresh_label();
	}
}


# add newly opened file
sub add {
	my $file_name = shift;
	$file_name = Kephra::Config::standartize_path_slashes( $file_name );
	my $old_nr = current_nr();
	if ( defined $file_name and -e $file_name ) {

		# open only text files and empty files
		return if ( !-z $file_name and -B $file_name
			and $Kephra::config{file}{open}{only_text} == 1 );

		# check if file is already open and goto this already opened
		if ( $Kephra::config{file}{open}{each_once} == 1){
			for (  0 .. last_nr() ) {
				my $path = Kephra::Document::nr_from_file_path($_);
				if ($path and $path eq $file_name ){
					Kephra::Document::Change::to_number($_);
					return;
				}
			}
		}
		save_properties();
		my $doc_nr = new_if_allowed('add');
		reset_tmp_data($doc_nr);
		reset_properties($doc_nr, $file_name);
		previous_nr($old_nr);
		current_nr($doc_nr);
		load_in_current_buffer($file_name);
		eval_properties($doc_nr);
		Kephra::App::Window::refresh_title();
		Kephra::App::EditPanel::Margin::autosize_line_number();
		Kephra::API::EventTable::trigger('document.list');
	}

}


sub load_in_current_buffer {
	my $file_name  = shift || '';
	my $edit_panel = Kephra::App::EditPanel::_ref();
	$edit_panel->ClearAll();
	Kephra::File::IO::open_pipe($file_name);
	$edit_panel->EmptyUndoBuffer;
	$edit_panel->SetSavePoint;
	Kephra::File::_remember_save_moment($file_name);
	$Kephra::temp{document}{loaded}++;
	#if ($Kephra::config{editpanel}{scroll_width} eq 'auto'){}
}


sub check_b4_overwite {
	my $filename = shift;
	$filename = Kephra::Document::_get_current_file_path() unless defined $filename;
	my $allow = $Kephra::config{file}{save}{overwrite};
	if ( -e $filename ) {
		my $frame = &Kephra::App::Window::_ref();
		my $label = $Kephra::localisation{dialog};
		if ( $allow eq 'ask' ) {
			my $answer = Kephra::Dialog::get_confirm_2( $frame,
				"$label->{general}{overwrite} $filename ?",
				$label->{file}{overwrite},
				-1, -1
			);
			return 1 if $answer == wxYES;
			return 0 if $answer == wxNO;
		} else {
			Kephra::Dialog::info_box( $frame,
				$label->{general}{dont_allow},
				$label->{file}{overwrite}
			) unless $allow;
			return $allow;
		}
	} else { return -1 }
}

# make document empty and reset all document properties to default
sub reset {
	my $doc_nr = validate_nr(shift);
	my $edit_panel = Kephra::App::EditPanel::_ref();
	Kephra::Document::set_readonly(0);
	$edit_panel->ClearAll;
	$edit_panel->EmptyUndoBuffer;
	$edit_panel->SetSavePoint;
	reset_tmp_data($doc_nr);
	reset_properties($doc_nr);
	eval_properties($doc_nr);
	Kephra::App::StatusBar::update_all();
}

# set the config default to the selected document
sub reset_properties {
	my ($doc_nr, $file_name) = @_;
	$doc_nr = validate_nr($doc_nr);
	$file_name = Kephra::Document::get_file_path($doc_nr)
		unless defined $file_name;
	my $default = $Kephra::config{file}{defaultsettings};
	my $doc_attr = $Kephra::document{open}[$doc_nr] = {
		'codepage' => $default->{codepage},
		'edit_pos' => -1,
		'file_path'=> $file_name,
		'readonly' => $default->{readonly},
		'syntaxmode'=>$default->{syntaxmode},
		'tab_size' => $default->{tab_size},
		'tab_use'  => $default->{tab_use},
	};
	$doc_attr->{cursor_pos} = $default->{cursor_pos} ? $default->{cursor_pos} : 0;
	if ($file_name and ( -e $file_name )) 
		 {$doc_attr->{EOL} = $default->{EOL_open}}
	else {$doc_attr->{EOL} = $default->{EOL_new} }

	set_file_path($file_name);
}

sub reset_tmp_data {
	my $doc_nr = validate_nr(shift);
	my $data   = temp_data();
	my $pointer = $data->[$doc_nr]{pointer};
	$data ->[$doc_nr] = {
		'pointer'    => $pointer,
	};
}


sub eval_properties {
	my $doc_nr = validate_nr(shift);
	my $doc_attr = attributes()->[$doc_nr];
	my $doc_data = temp_data()->[$doc_nr];
	my $ep = Kephra::App::EditPanel::_ref();

	$doc_attr->{syntaxmode} = "none" unless $doc_attr->{syntaxmode};
	Kephra::Document::SyntaxMode::change_to( $doc_attr->{syntaxmode} );
	Kephra::Document::set_EOL_mode( $doc_attr->{EOL} );
	Kephra::Document::set_tab_mode( $doc_attr->{tab_use} );
	Kephra::Document::set_tab_size( $doc_attr->{tab_size} );
	Kephra::Document::set_readonly( $doc_attr->{readonly} );

	# setting selection and caret position
	if ($doc_data->{selstart} and $doc_data->{selstart}) {
		$doc_attr->{cursor_pos} < $doc_data->{selend}
			? $ep->SetSelection( $doc_data->{selend},$doc_data->{selstart})
			: $ep->SetSelection( $doc_data->{selstart},$doc_data->{selend});
	} else { $ep->GotoPos( $doc_attr->{cursor_pos} ) 
	}
	if ($Kephra::config{file}{open}{in_current_dir}){
		$Kephra::config{file}{current}{directory} = $doc_data->{directory}
			if $doc_data->{directory};
	} else { $Kephra::config{file}{current}{directory} = '' }
	Kephra::Edit::_let_caret_visible();
	Kephra::App::StatusBar::refresh_cursor();
	Kephra::App::EditPanel::set_word_chars();
	Kephra::App::EditPanel::paint_bracelight()
		if $Kephra::config{editpanel}{indicator}{bracelight}{visible};
	Wx::Window::SetFocus($ep) unless $Kephra::temp{dialog}{control};
}


sub save_properties {
	my $doc_nr = validate_nr(shift);
	my $doc_attr = attributes()->[$doc_nr];
	my $doc_data = temp_data()->[$doc_nr];
	my $ep = Kephra::App::EditPanel::_ref();

	$doc_attr->{cursor_pos}= $ep->GetCurrentPos;
	$doc_data->{selstart}  = $ep->GetSelectionStart;
	$doc_data->{selend}    = $ep->GetSelectionEnd;
}

sub change_pointer {
	my $newtab = validate_nr(shift);
	my $oldtab  = current_nr();
	my $docsdata = temp_data();
	my $ep      = Kephra::App::EditPanel::_ref();
	$ep->AddRefDocument( $docsdata->[$oldtab]{pointer} );
	$ep->SetDocPointer( $docsdata->[$newtab]{pointer} );
	$ep->ReleaseDocument( $docsdata->[$newtab]{pointer} );
	set_current_nr($newtab);
}

sub do_with_all {
	my $code = shift;
	return unless ref $code eq 'CODE';
	my $nr = current_nr();
	my $docs = temp_data();
	save_properties();
	for ( @{ all_nr() } ) {
		change_pointer($_);
		&$code( $docs->[$_] );
	}
	change_pointer($nr);
	eval_properties($nr);
}

# various helper

1;
