package Kephra::App::ToolBar;
use strict;
use warnings;

our $VERSION = '0.05';

# central lib for gui toolbars
# storing, fetching, assemble data, creating regular button items

use Wx qw(
	wxITEM_NORMAL wxITEM_CHECK
	wxTB_HORIZONTAL wxTB_DOCKABLE
	wxNullBitmap 
	);
use Wx::Event qw( EVT_TOOL );

sub _ref {
	if (ref $_[1] eq 'Wx::ToolBar') {$Kephra::app{toolbar}{$_[0]}{ref} = $_[1]}
	else                            {$Kephra::app{toolbar}{$_[0]}{ref}}
}
sub _create_empty {
	return Wx::ToolBar->new( Kephra::App::Window::_ref(),
			-1, [-1,-1], [-1,-1], wxTB_HORIZONTAL|wxTB_DOCKABLE );
}

sub create_new{
	my $bar_id  = shift;
	my $bar_def = shift;
	my $bar = _ref($bar_id);
	# destroy old safely when overwrite
	$bar->Destroy if defined $bar;
	_ref ($bar_id, _create_empty());
	create($bar_id, $bar_def);
}

sub create {
	my $bar_id  = shift;
	my $bar_def = shift;
	eval_data($bar_id, assemble_data_from_def($bar_def));
}

sub assemble_data_from_def {
	my $bar_def = shift;
	return unless ref $bar_def eq 'ARRAY';

	my @tbds = (); # toolbar data structure
	my $cmd_data;
#
	for my $item_def (@$bar_def){
		# undef means null string
		$item_def = '' unless defined $item_def;
		my %item;

		# skipping commented lines
		next if substr($item_def, -1) eq '#';

		# recursive call for submenus 
		if (ref $item_def eq 'HASH'){} 

		# "parsing" item data
		($item{type}, $item{id}, $item{size}) = split / /, $item_def;
		
		# skip separators
		if (not defined $item{type} or $item{type} eq 'separator'){
			$item{type} = '';
		# handle regular toolbar buttons
		} elsif( substr( $item{type}, -4) eq 'item' ) {
			$cmd_data = Kephra::API::CommandList::get_cmd_properties( $item{id} );
			# skipping when command call is missing
			next unless ref $cmd_data and exists $cmd_data->{call};
			for ('call','enable','enable_event','state', 'state_event','label',
				'help','icon'){
				$item{$_} = $cmd_data->{$_} if $cmd_data->{$_}
			}
			#$item{type} = 'item'if not $cmd_data->{state} and $item{type} eq 'checkitem';
		}
		push @tbds, \%item;
	}
	return \@tbds;
}

sub eval_data {
	my $bar_id   = shift;
	my $bar_data = shift;
	my $bar      = _ref($bar_id);
	return $bar unless ref $bar_data eq 'ARRAY';

	my $win = Kephra::App::Window::_ref();
	my $item_kind;
	my @rest_items = ();
	my $bar_item_id = exists $Kephra::app{toolbar}{$bar_id}{item_id}
		? $Kephra::app{toolbar}{$bar_id}{item_id}
		: $Kephra::app{GUI}{masterID}++ * 100;
	$Kephra::app{toolbar}{$bar_id}{item_id} = $bar_item_id;
	my $respond = $Kephra::config{app}{toolbar}{all}{responsive};

	for my $item_data (@$bar_data){
		if (not $item_data->{type} or $item_data->{type} eq 'separator'){
			$bar->AddSeparator;
		} elsif (ref $item_data->{icon} eq 'Wx::Bitmap'){
			if ($item_data->{type} eq 'checkitem'){
				$item_kind = wxITEM_CHECK
			} elsif ($item_data->{type} eq 'item'){
				$item_kind = wxITEM_NORMAL 
			} else { next }
			my $item_id = $bar_item_id++;
			my $tool = $bar->AddTool(
				$item_id, '', $item_data->{icon}, wxNullBitmap, 
				$item_kind, $item_data->{label}, $item_data->{help}
			);
			EVT_TOOL ($win, $item_id, $item_data->{call});
			if (ref $item_data->{enable} eq 'CODE' and $respond){
				$tool->Enable( $item_data->{enable}() );
				for my $event (split /,/, $item_data->{enable_event}){
					Kephra::API::EventTable::add_call ( 
						$event, 'tool_enable_'.$item_id, sub{
							$bar->EnableTool( $item_id, $item_data->{enable}() )
					} );
				}
			}
			if (ref $item_data->{state} eq 'CODE'
				and $item_data->{type} eq 'checkitem'){
				$bar->ToggleTool( $item_id, $item_data->{state}() );
				for my $event (split /,/, $item_data->{state_event}){
					Kephra::API::EventTable::add_call (
						$event, 'tool_state_'.$item_id, sub{
							$bar->ToggleTool( $item_id, $item_data->{state}() )
					} );
				}
			}
		} else {
			$item_data->{pos} = $bar_item_id % 100 + @rest_items;
			push @rest_items, $item_data;
		}
	}
	$bar->Realize;
	$bar->SetRows(1);
	_ref($bar_id, $bar);

	return \@rest_items;
}

sub destroy {
	my $bar = _ref( shift );
	return unless $bar;
	$bar->Destroy;
}

1;
