package Kephra::File::IO;
our $VERSION = '0.18';

use strict;
use warnings;

# linux/darwin: latin12utf8, eol2nl
sub lin_enc_buf {
	my $buffer=$_[0]||return;
	eval {
		use Encode::Guess ();
		my $enc = Encode::Guess::guess_encoding($buffer,qw/latin1/);
		if (ref($enc)) { $buffer = $enc->decode($buffer) }
	};
	$buffer=~s/\r\n/\n/sgo; $buffer=~s/\r/\n/sgo;
	return $buffer;
}
sub lin_load_file {
	if (-e $_[0] and open (my $FH,'<',$_[0])) {
		return lin_enc_buf(join('',<$FH>));
	}
}

# read a file into a scintilla buffer, is much faster then open_buffer
sub open_pipe {
	my $file = shift;
	my $ep   = shift || Kephra::App::EditPanel::_ref();
	my $err_txt    = Kephra::Config::Localisation::strings->{dialog}{error};
	my $input;
	unless ($file) {
		Kephra::Dialog::warning_box( undef,
			"file_read " . $err_txt->{no_param}, $err_txt->{general} );
	} else {
		unless ( -r $file ) {
			Kephra::Dialog::warning_box
				( undef, $err_txt->{file_read} . " " . $file, $err_txt->{file} );
		} else {
			open my $FH,'<', $file
				or Kephra::Dialog::warning_box
					(undef, $err_txt->{file_read} . " $file", $err_txt->{file});
			if ($^O=~/(?:linux|darwin)/i) {
				$input=join('',<$FH>);
				$input=&lin_enc_buf($input);
				$ep->AddText($input);
			}
			else {
				binmode $FH;    #binmode(FILE, ":encoding(cp1252)")
				$ep->AddText($input) while ( read $FH, $input, 500000 ) > 0;
			}
			return 1;
		}
	}
}#use PerlIO::encoding; binmode($FH, ":encoding(cp1252)") ":encoding(iso- 8859-1)

# reading file into buffer variable
sub open_buffer {
	my ($file)  = (@_);
	my $err_txt = Kephra::Config::Localisation::strings->{dialog}{error};
	my ($buffer, $input);
	unless ($file) {
		Kephra::Dialog::warning_box
			( undef, "file_read " . $err_txt->{no_param}, $err_txt->{general} );
	} else {
		unless ( -r $file ) {
			Kephra::Dialog::warning_box( undef,
				$err_txt->{file_read} . " " . $file, $err_txt->{file} );
		} else {
			open my $FH, '<', $file
				or Kephra::Dialog::warning_box
					(undef, $err_txt->{file_read} . " $file", $err_txt->{file});
			if ($^O=~/(?:linux|darwin)/i) {
				$buffer=join('',<$FH>);
				$buffer=&lin_enc_buf($buffer);
			}
			else {
				binmode $FH;    #binmode(FILE, ":encoding(cp1252)")
				$buffer .= $input while ( read $FH, $input, 500000 ) > 0;
			}
		}
	}
	return $buffer;
}

# wite into file from buffer variable
sub write_buffer {
	my ($file, $text) = @_;
	my $err_txt = Kephra::Config::Localisation::strings->{dialog}{error};
	# check if there is a name or if file that you overwrite is locked
	if ( not $file or (-e $file and not -w $file) ) {
		Kephra::Dialog::warning_box( undef,
			"file_write " . $err_txt->{'no_param'}, $err_txt->{general} );
	} else {
		open my $FH, '>', $file
			or Kephra::Dialog::warning_box( undef,
			$err_txt->{file_write} . " $file", $err_txt->{file} );
		binmode $FH;
		print $FH $text;
	}
}


sub get_age {
	my $file = shift;
	return (stat $file)[9] if -e $file;
}

1;
