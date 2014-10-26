package Kephra::File::Session;
$VERSION = '0.13';

use strict;

############################################################################
# file session handling
# a session is the total sum of all opened files
############################################################################

sub _get_config { $Kephra::config{file}{session} }

# extern
sub open_file {
	my $file_name = Kephra::Dialog::get_file_open(
		Kephra::App::Window::_get(),
		$Kephra::localisation{dialog}{file}{open_session},
		Kephra::Config::filepath( _get_config->{directory} ),
		$Kephra::temp{file}{filterstring}{config}
	);
	load($file_name);
}

sub load {
	my $file_name = shift;
	if ( -r $file_name ) {
		my %temp_config = %{ Kephra::Config::File::load($file_name) };
		if (%temp_config) {
			Kephra::File::close_all();
			my @load_files = 
				@{Kephra::Config::Tree::_convert_node_2_AoH( \$temp_config{document} )};
			@load_files = @{ &_forget_gone_files( \@load_files ) };
			my $start_nr = $temp_config{current_nr};

			# open remembered files with all properties
			Kephra::Document::Internal::restore( $_ ) for @load_files;

			# how many buffer we currently have and save the last doc?
			my $buffer = $Kephra::temp{document}{buffer};
			Kephra::Document::Internal::eval_properties($buffer-1);

			# selecting starting doc nr
			$start_nr = 0 if (not defined $start_nr) or ($start_nr < 0 );
			$start_nr = $buffer - 1 if $start_nr >= $buffer ;

			# activate the starting document & some afterwork
			Kephra::Edit::Bookmark::restore_all();
			Kephra::App::Window::refresh_title();
			Kephra::App::EditPanel::Margin::reset_line_number_width();
			Kephra::Document::Internal::eval_properties($#load_files);
			Kephra::Document::Change::to_number($start_nr);
			Kephra::Document::_set_previous_nr($start_nr);
		} else {
			Kephra::Dialog::warning_box(undef, $file_name,
			    $Kephra::localisation{dialog}{error}{config_parse});
		}
	}
}

sub add {
	my $file_name = Kephra::Dialog::get_file_open(
		Kephra::App::Window::_get(),
		$Kephra::localisation{dialog}{file}{add_session},
		Kephra::Config::filepath( _get_config->{directory} ),
		$Kephra::temp{file}{filterstring}{config}
	);
	if ( -r $file_name ) {
		my %temp_config = %{ Kephra::Config::File::load($file_name) };
		if (%temp_config) {
			my $current_doc_nr = $Kephra::document{current_nr};
			my $prev_doc_nr    = $Kephra::document{previous_nr};
			#my $start_node = $Kephra::config{file}{current}{session}{node};
			my @load_files = @{ Kephra::Config::Tree::_convert_node_2_AoH(
					\$temp_config{document}
			) };
			@load_files = @{ _forget_gone_files( \@load_files ) };

			# open remembered files with all properties
			Kephra::Document::Internal::save_properties($current_doc_nr);
			Kephra::Document::Internal::restore( \%{ $load_files[$_] } )
				for ( 0 .. $#load_files );

			# make file history like before
			Kephra::Document::Internal::change_pointer($current_doc_nr);
			Kephra::Document::Internal::eval_properties($current_doc_nr);
			_remember_directory($file_name);
		} else {
			Kephra::Dialog::warning_box(undef, $file_name,
			    $Kephra::localisation{dialog}{error}{config_parse});
		}
	}
}

sub save {
	my $config      = _get_config();
	my $config_file = shift ||
		Kephra::Config::filepath( $config->{directory}, _get_config->{file} );
	my %temp_config;
	%temp_config = %{ Kephra::Config::File::load($config_file) }
		if ( -r $config_file );
	undef $temp_config{document};
	Kephra::Config::Tree::_convert_node_2_AoH( \$Kephra::document{open} );
	# sorting out docs without file
	@{ $Kephra::document{open} }
		= @{ _forget_gone_files( \$Kephra::document{open} ) };
	$temp_config{document} = $Kephra::document{open};
	$temp_config{current_nr} = $Kephra::document{current_nr};
	Kephra::Config::File::store( $config_file, \%temp_config );
}

sub save_as {
	my $file_name = Kephra::Dialog::get_file_save( Kephra::App::Window::_get(),
		$Kephra::localisation{dialog}{file}{save_session},
		Kephra::Config::filepath( _get_config->{directory} ),
		$Kephra::temp{file}{filterstring}{config}
	);
	if ( length($file_name) > 0 ) {
		save( $file_name, "files" );
		_remember_directory($file_name);
	}
}

#######################################
# backup session handling
#######################################

sub load_backup {
	my $config = _get_config();
	load( Kephra::Config::filepath( $config->{directory}, $config->{backup} ) );
}

sub save_backup {
	my $config = _get_config();
	save( Kephra::Config::filepath( $config->{directory}, $config->{backup} ) );
}

#######################################
# default session handling
#######################################

sub autosave {
	my $config = _get_config();
	if ( $config->{autosave} eq 'extern' ) {
		save( Kephra::Config::filepath($config->{directory}, $config->{current} ) );
	}
}

sub autoload {
	my $config = _get_config;
	my $intern = $Kephra::temp{document};
	my @load_files;
	my $start_file_nr = $Kephra::document{current_nr} || 0;
	$Kephra::document{current_nr}   = 0;
	$Kephra::temp{document}{changed}= 0;
	$Kephra::temp{document}{loaded} = 0;

	# detect wich files to load
	if ( $config->{autosave} eq 'not' ) { 
	# Do nothing
	} elsif ( $config->{autosave} eq 'intern' ) {
		@load_files = 
			@{Kephra::Config::Tree::_convert_node_2_AoH(\$Kephra::document{open})};
	} elsif ( $config->{autosave} eq 'extern' ) {
		my $file_name = Kephra::Config::filepath
			( $config->{directory}, $config->{current} );
		#my $start_node  = $config;
		my %temp_config = %{ Kephra::Config::File::load($file_name) };
		@load_files = @{
			Kephra::Config::Tree::_convert_node_2_AoH( \$temp_config{document} )
		};
		$start_file_nr = $temp_config{current_nr};
	}

	# delete all exisating doc
	undef $Kephra::document{open};
	# throw gone files
	@load_files = @{ &_forget_gone_files( \@load_files ) };
	# open remembered files with all properties
	if ( $load_files[0]->{file_path} ) {
		Kephra::Document::Internal::restore( $_ ) for @load_files;
	# or make an emty edit panel if no doc remembered
	} else { 
		Kephra::Document::Internal::reset()
	}




	# detect with which file to start
	$start_file_nr = 0 if ( !$start_file_nr or $start_file_nr < 0 );
	$start_file_nr = $intern->{loaded}-1 if 
		$start_file_nr >= $intern->{loaded} and $intern->{loaded};

	Kephra::Edit::Bookmark::restore_all();
	Kephra::App::Window::refresh_title();
	Kephra::App::EditPanel::Margin::reset_line_number_width();
	Kephra::Document::Internal::eval_properties($#load_files);
	Kephra::Document::Change::to_number($start_file_nr);
	Kephra::Document::_set_previous_nr($start_file_nr);
}

sub delete {
	my $save = _get_config()->{autosave};
	delete $Kephra::document{open}
		if $save eq 'not' 
		or $save eq 'extern';
}

###############################################
# other session formats
###############################################

sub import_scite {
	my $win = Kephra::App::Window::_get();
	my $file_name = Kephra::Dialog::get_file_open( $win,
		$Kephra::localisation{dialog}{file}{open_session},
		$Kephra::temp{path}{config},
		$Kephra::temp{file}{filterstring}{scite}
	);
	if ( -r $file_name ) {
		if ( open my $FILE, "<$file_name" ) {
			my @load_files;
			my ( $start_file_nr, $file_nr );
			while (<$FILE>) {
				m/<pos=(-?)(\d+)> (.+)/;
				if ( -e $3 ) {
					$start_file_nr = $file_nr if $1;
					$load_files[$file_nr]{cursor_pos} = $2;
					$load_files[$file_nr++]{file_path}    = $3;
				}
			}
			if (@load_files) {
				&Kephra::File::close_all;
				for (@load_files) {
					Kephra::Document::Internal::add( ${$_}{file_path} );
					Kephra::Edit::_goto_pos( ${$_}{cursor_pos} );
				}
				Kephra::Document::Change::to_number($start_file_nr);
				$Kephra::document{previous_nr} = $start_file_nr;
			} else {
				Kephra::Dialog::warning_box( $win, $file_name,
					$Kephra::localisation{dialog}{error}{config_parse} );
			}
		} else {
			my $err_msg = $Kephra::localisation{dialog}{error};
			Kephra::Dialog::warning_box 
				($win, $err_msg->{file_read}." $file_name", $err_msg->{file});
		}
	}
}

sub export_scite {
	my $win = Kephra::App::Window::_get();
	my $file_name = Kephra::Dialog::get_file_save( $win,
		$Kephra::localisation{dialog}{file}{save_session},
		$Kephra::temp{path}{config},
		$Kephra::temp{file}{filterstring}{scite}
	);
	if ( length($file_name) > 0 ) {
		if ( open my $FILE, ">$file_name" ) {
			my ( $current, $output ) = ( $Kephra::document{current_nr}, );
			for ( 0 .. Kephra::Document::_get_last_nr() ) {
				my %file = %{ $Kephra::document{open}[$_] };
				if ( -e $file{file_path} ) {
					$output .= "<pos=";
					$output .= "-" if $_ == $current;
					$output .= "$file{cursor_pos}> $file{file_path}\n";
				}
			}
			print $FILE $output;
		} else {
			my $err_msg = $Kephra::localisation{dialog}{error};
			Kephra::Dialog::warning_box
				($win, $err_msg->{file_write}." $file_name", $err_msg->{file} );
		}
	}
}

##################################
# intern
##################################

sub _forget_gone_files {
	my @true_files = ();
	my $node       = shift;
	$node = $$node if ref $node eq 'REF' and ref $$node eq 'ARRAY';
	if ( ref $node eq 'ARRAY' ) {
		my @files = @{$node};
		for ( 0 .. $#files ) {
			if ( defined $files[$_]{file_path} and -e $files[$_]{file_path} ) {
				my %file_properties = %{ $files[$_] };
				push( @true_files, \%file_properties );
			}
		}
	}
	return \@true_files;
}

sub _remember_directory {
	my ( $filename, $dir, @dirs ) = shift;
	if ( length($filename) > 0 ) {
		@dirs = split( /\\/, $filename ) if $filename =~ /\\/ ;
		@dirs = split( /\//, $filename ) if $filename =~ /\// ;
		$dir .= "$dirs[$_]/" for 0 .. $#dirs - 1;
		_get_config()->{directory} = $dir if $dir;
	}

}

1;