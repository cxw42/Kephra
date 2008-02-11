package Kephra::File::History;
$VERSION = '0.02';

use strict;

# internal Module API
sub _get_config{ $Kephra::config{file}{history} }
sub _get {
 my $history = _get_config->{path};
	if (ref $history eq 'ARRAY'){
		return $history;
	} elsif (defined $history){
		my @history = ($history);
		return \@history;
	} else {
		my @history = ();
		return \@history;
	}
}
sub _set { _get_config->{path} = shift; }

# external Appwide API
sub init {
	Kephra::API::EventTable::add_call( 
		'document.list', 'file_history', sub {
			my @history = @{ _get() };
			my $path = Kephra::Document::_get_current_file_path();
			my @uniq = grep { $_ ne $path } @history;
			_set(\@uniq);
	} );
}

sub get {
	delete_gone();
	_get();
}

sub add {
 my $name    = shift;
 my @history = @{ _get() };
 my $length  = _get_config->{length};
	return unless defined $name;
 my %seen;
	unshift @history, $name;
 my @uniq = grep { !$seen{$_}++ } @history;
	pop @uniq while @uniq > $length;
	_set(\@uniq);
}

sub delete_gone {
 my @exist = grep { -e $_ } @{ _get() };
	_set(\@exist);
}