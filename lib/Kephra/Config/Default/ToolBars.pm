package Kephra::Config::Default::ToolBars;
use strict;
use warnings;

our $VERSION = '0.01';

sub get {
	return {
		main_toolbar => [
			'item file-new',
			'item file-open',
			'item file-print#', 
			'item file-close#',
			'item file-save-all',
			'item file-save',
			'',
			'item edit-changes-undo',
			'item edit-changes-redo',
			'',
			'item edit-cut',
			'item edit-copy',
			'item edit-paste',
			'item edit-replace',
			'item edit-delete',
			'',
			'checkitem view-editpanel-line-wrap',
			'checkitem view-window-stay-on-top',
			'',
			'item view-dialog-find#',
			'item view-dialog-config',
			'item view-dialog-keymap#',
		],
		searchbar => [
			'item view-toolbar-search',
			'combobox find 180',
			'item find-mark-all#',
			'item find-prev',
			'item find-next',
			'',
			'item goto-last-edit',
			'',
			'item goto-line',
			'item view-dialog-find',
		],
		statusbar => [
			'textpanel cursor_pos 150',
			'textpanel percent_pos_selection 150',
			'textpanel syntax_mode 100',
			'textpanel tab_mode 50',
			'textpanel eol_mode 80',
			'textpanel info -1',
		],
	}
}

1;
