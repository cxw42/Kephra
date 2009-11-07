package Kephra::File::History;
our $VERSION = '0.04';

use strict;
use warnings;

my @session;

# internal Module API
sub _config{ $Kephra::config{file}{history} }
sub _get {
	my $history = _config->{path};
	if (ref $history eq 'ARRAY') {                            $history }
	elsif (defined $history)     { my @history = ($history); \@history }
	else                         { my @history = ();         \@history }
}
sub _set { _config->{path} = shift }

# external Appwide API
sub init {
	Kephra::API::EventTable::add_call( 
		'document.list', 'file_history', sub {
			my @history = @{ _get() };
			my $path = Kephra::Document::Data::get_file_path();
			return unless $path;
			my @uniq = grep { $_ ne $path } @history;
			_set(\@uniq);
	} );
}

sub get {
	delete_gone();
	_get();
}

sub add {
	my $file    = shift;
	my @history = @{ _get() };
	my $length  = _config->{length};
	return unless defined $file;
	my %seen;
	unshift @history, $file;
	my @uniq = grep { !$seen{$_}++ } @history;
	pop @uniq while @uniq > $length;
	_set(\@uniq);
}

sub delete_gone {
	my @exist = grep { -e $_ } @{ _get() };
	_set(\@exist);
}

1;