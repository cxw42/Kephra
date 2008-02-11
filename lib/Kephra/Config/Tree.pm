package Kephra::Config::Tree;
$VERSION = '0.02';

# verbose config hash ops

use strict;


sub get_subtree{
	my $config = shift;
	my $path = shift;
	for (split '/', $path) {
		$config = $config->{$_} if defined $config->{$_};
	}
	return $config;
}
# -NI
sub diff {
	my $new = shift;
	my $old = shift;
	return my $diff;
}

sub merge {
	my $new = shift;
	my $old = shift;
	require Hash::Merge;
	Hash::Merge::set_behavior('LEFT_PRECEDENT');
	Hash::Merge::merge($new, $old);
}

# -NI
sub update {
	my $new = shift;
	my $old = shift;

}


# single node manipulation
sub _convert_node_2_AoH {
	my $node = shift;
	if ( ref $$node eq 'ARRAY'  ) {
		return $$node;
	} elsif ( ref $$node eq 'HASH' ) {
		my %temp_hash = %{$$node};
		push( my @temp_array, \%temp_hash );
		return $$node = \@temp_array;
	} elsif ( ref $$node eq '' ) {
		my @temp_array = ();
		return $$node = \@temp_array;
	}
}

sub _convert_node_2_AoS {
	my $node = shift;
	if ( 'ARRAY'  eq ref $$node ) {
		return $$node;
	} elsif ( 'SCALAR' eq ref $node )  {
		if ($$node) {
			my $temp = $$node;
			push( my @temp_array, $temp );
			return $$node = \@temp_array;
		} else {
			my @temp_array = ();
			return $$node = \@temp_array;
		}
	}
}

1;