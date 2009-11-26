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
			'item file-close-current#',
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
			'checkitem view-panel-output',
			'checkitem view-panel-notepad',
			'',
			'item view-dialog-find#',
			'item view-dialog-config#',
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
			'textpanel cursor 66',
			'textpanel selection 60',
			'textpanel syntaxmode 50',
			'textpanel codepage 40',
			'textpanel tab 25',
			'textpanel EOL 32',
			'textpanel message -1',
		],
	}
}

1;
