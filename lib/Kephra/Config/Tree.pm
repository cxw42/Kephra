package Kephra::Config::Tree;
$VERSION = '0.02';

# verbose config hash ops

use strict;

sub get_subtree { &subtree }
sub subtree {
	my $config = shift;
	return unless ref $config;
	my $path = shift;
	for (split '/', $path) {
		$config = $config->{$_} if defined $config->{$_};
	}
	return $config;
}

my %copy = (
	''     => sub {          $_[0]    },
	SCALAR => sub {       \${$_[0]}   },
	REF    => sub { \copy( ${$_[0]} ) },
	ARRAY  => sub { [map {copy($_)} @{$_[0]} ] },
	HASH   => sub { my %copy = map { copy($_) } %{$_[0]}; \%copy; },
);

my %merge = (
	''     => sub { $_[0] },
	SCALAR => sub { \${$_[0]} },
	REF    => sub { \merge( ${$_[0]}, ${$_[1]} ) },
	ARRAY  => sub { [map { copy($_) } ( @{$_[0]}, @{$_[1]} ) ] },
	HASH   => sub {
		my %copy = map 
			{ $_, merge( $_[0]{$_}, $_[1]{$_} ) } 
			(keys %{$_[0]}, keys %{$_[1]} );
		\%copy;
	},
);

my %update = (
	''     => sub { $_[0] ? $_[0] : $_[1] },
	SCALAR => sub { \( ${$_[0]} ? ${$_[0]} : ${$_[1]} ) },
	REF    => sub { \update( ${$_[0]}, ${$_[1]} ) },
	ARRAY  => sub { [map { copy($_) } ( @{$_[0]}, @{$_[1]} ) ] },
	HASH   => sub {
		my %copy = map 
			{ $_, merge( $_[0]{$_}, $_[1]{$_} ) } 
			(keys %{$_[0]}, keys %{$_[1]} );
		\%copy;
	},
);

my %diff = (
	''     => sub {    $_[0] if $_[0] ne $_[1] },
	SCALAR => sub { \${$_[0]} if  ${$_[0]} ne ${$_[1]} },
	REF    => sub { \diff( ${$_[0]}, ${$_[1]} ) },
	ARRAY  => sub { [map {copy($_)} ( @{$_[0]}, @{$_[1]} ) ] },
	HASH   => sub {
		my %copy = map { copy($_) } %{$_[0]};
		\%copy;
	},
);

sub copy { $copy{ ref $_[0] }( $_[0] ) }
sub merge {
	my ($lref, $rref) = (ref $_[0], ref $_[1]);
	$lref eq $rref
		? $merge{ $lref }( $_[0], $_[1] )
		: defined $_[0]
			? $copy{ $lref }( $_[0] )
			: $copy{ $rref }( $_[1] )
	;
}
sub update {
	my ($lref, $rref) = (ref $_[0], ref $_[1]);
	$lref eq $rref
		? $update{ $lref }( $_[0], $_[1] )
		: $copy{ $rref }( $_[1] )
	;
}
sub diff {
	my ($lref, $rref) = (ref $_[0], ref $_[1]);
	$lref eq $rref
		? $diff{ $lref }( $_[0], $_[1] )
		: $copy{ $rref }( $_[0] )
	;
}

#############################
# single node manipulation
#############################

sub _convert_node_2_AoH {
	my $node = shift;
	if (ref $$node eq 'ARRAY') {
		return $$node;
	} elsif (ref $$node eq 'HASH') {
		my %temp_hash = %{$$node};
		push( my @temp_array, \%temp_hash );
		return $$node = \@temp_array;
	} elsif (not ref $$node) {
		my @temp_array = ();
		return $$node = \@temp_array;
	}
}

sub _convert_node_2_AoS {
	my $node = shift;
	if (ref $$node eq 'ARRAY') {
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