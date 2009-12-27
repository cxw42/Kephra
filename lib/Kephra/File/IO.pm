package Kephra::File::IO;
our $VERSION = '0.18';

use strict;
use warnings;

# linux/darwin: latin12utf8, eol2nl
sub lin_enc_buf {
	#my $buffer=$_[0]||return;
	#eval {
		#use Encode::Guess ();
		#my $enc = Encode::Guess::guess_encoding($buffer,qw/latin1/);
		#if (ref($enc)) { $buffer = $enc->decode($buffer) }
	#};
	#$buffer=~s/\r\n/\n/sgo; $buffer=~s/\r/\n/sgo;
	#return $buffer;
#}
#sub lin_load_file {
	#if (-e $_[0] and open (my $FH,'<',$_[0])) {
		#return lin_enc_buf(join('',<$FH>));
	#}
}

# read a file into a scintilla buffer, is much faster then open_buffer
sub open_buffer {
	my $doc_nr = shift;
	my $file   = shift || Kephra::Document::Data::get_file_path($doc_nr);
	my $ep     = shift || Kephra::Document::Data::_ep($doc_nr);
	my $err_txt= Kephra::Config::Localisation::strings->{dialog}{error};
	my $input;
	unless ($file) {
		Kephra::Dialog::warning_box("file_read " . $err_txt->{no_param}, $err_txt->{general} );
	} else {
		unless ( -r $file ) {
			Kephra::Dialog::warning_box( $err_txt->{file_read} . " " . $file, $err_txt->{file} );
		} else {
			my $did_open = open my $FH,'<', $file;
			unless ($did_open){
				Kephra::Dialog::warning_box($err_txt->{file_read} . " $file", $err_txt->{file});
				return 0;
			}
			my $codepage = Kephra::Document::Data::get_attribute('codepage', $doc_nr);
			if ($codepage eq 'auto'){
				binmode $FH;
				read $FH, my $probe, 1000;
				my $enc = Encode::Guess::guess_encoding( $probe );
				seek $FH, 0, 0;
				$codepage = $enc =~ /utf8/ ? 'utf8' : '8bit';
				Kephra::Document::Data::set_attribute('codepage', $codepage, $doc_nr);
			}
			binmode $FH, $codepage eq 'utf8' ? ":utf8" : ":raw"; # ":encoding(utf8)"
			Kephra::EventTable::freeze('document.text.change');
			$ep->AddText( do { local $/; <$FH> } );
			Kephra::EventTable::thaw('document.text.change');
			return 1;
		}
	}
	return 0;
}
			#if ($^O=~/(?:linux|darwin)/i) {
				#$input = join('',<$FH>); $input = &lin_enc_buf($input); $ep->AddText($input);
			#} else { } binmode(FILE, ":encoding(cp1252)")

# wite into file from buffer variable
sub write_buffer {
	my $doc_nr = shift || Kephra::Document::Data::current_nr();
	my $file   = shift || Kephra::Document::Data::get_file_path($doc_nr);
	my $ep     = shift || Kephra::Document::Data::_ep($doc_nr);
	my $err_txt = Kephra::Config::Localisation::strings->{dialog}{error};
	# check if there is a name or if file that you overwrite is locked
	if ( not $file or (-e $file and not -w $file) ) {
		Kephra::Dialog::warning_box
			("file_write " . $err_txt->{'no_param'}, $err_txt->{general} );
	} else {
		my $codepage = Kephra::Document::Data::get_attribute('codepage', $doc_nr);
		my $did_open = open my $FH, '>', $file;
		unless ($did_open){
			Kephra::Dialog::warning_box($err_txt->{file_write} . " $file", $err_txt->{file} );
			return 0;
		}
		binmode $FH, $codepage eq 'utf8' ? ":utf8" : ":raw"; # ":encoding(utf8)"
		print $FH $ep->GetText();
	}
}


sub get_age {
	my $file = shift;
	return (stat $file)[9] if -e $file;
}

1;
