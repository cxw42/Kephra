package Kephra::File::IO;
our $VERSION = '0.16';

use strict;
use warnings;


# read a file into a scintilla buffer, is much faster then open_buffer
sub open_pipe {
	my $file_name  = shift;
	my $edit_panel = Kephra::App::EditPanel::_ref();
	my $err_txt    = Kephra::Config::Localisation::strings->{dialog}{error};
	my $input;
	unless ($file_name) {
		Kephra::Dialog::warning_box( undef,
			"file_read " . $err_txt->{no_param}, $err_txt->{general} );
	} else {
		unless ( -r $file_name ) {
			Kephra::Dialog::warning_box( undef,
				$err_txt->{file_read} . " " . $file_name, $err_txt->{file} );
		} else {
			open my $FILE,'<', $file_name
				or Kephra::Dialog::warning_box( undef,
				$err_txt->{file_read} . " $file_name", $err_txt->{file} );
			binmode $FILE;    #binmode(FILE, ":encoding(cp1252)")
			while ( ( read $FILE, $input, 500000 ) > 0 ) {
				$edit_panel->AddText($input);
			}
			return 1;
		}
	}
}
#use PerlIO::encoding; binmode FH, ":encoding(iso- 8859-1)".

# reading file into buffer variable
sub open_buffer {
	my ($file_name) = (@_);
	my $err_txt = Kephra::Config::Localisation::strings->{dialog}{error};
	my ( $buffer, $input );
	unless ($file_name) {
		Kephra::Dialog::warning_box( undef,
			"file_read " . $err_txt->{no_param},
			$err_txt->{general} );
	} else {
		unless ( -r $file_name ) {
			Kephra::Dialog::warning_box( undef,
				$err_txt->{file_read} . " " . $file_name, $err_txt->{file} );
		} else {
			open my $FILE, '<', $file_name
				or Kephra::Dialog::warning_box( undef,
				$err_txt->{file_read} . " $file_name", $err_txt->{file} );
			binmode $FILE;    #binmode(FILE, ":encoding(cp1252)")
			while ( ( read $FILE, $input, 500000 ) > 0 ) { $buffer .= $input }
		}
	}
	return $buffer;
}

# wite into file from buffer variable
sub write_buffer {
	my ( $file_name, $text ) = @_;
	my $err_txt = Kephra::Config::Localisation::strings->{dialog}{error};
	# check if there is a name or if file that you overwrite is locked
	if ( not $file_name or (-e $file_name and not -w $file_name) ) {
		Kephra::Dialog::warning_box( undef,
			"file_write " . $err_txt->{'no_param'}, $err_txt->{general} );
	} else {
		open my $FILE, '>', $file_name
			or Kephra::Dialog::warning_box( undef,
			$err_txt->{file_write} . " $file_name", $err_txt->{file} );
		binmode $FILE;
		print $FILE $text;
	}
}


sub get_age {
	my $file = shift;
	return unless -e $file;
	return $^T - (-M $file) * 86400;
}

1;
