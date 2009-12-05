package Kephra::Config::Default::ContextMenus;
our $VERSION = '0.02';

use strict;
use warnings;

sub get {
	return {
		'editpanel_contextmenu' => [
			'item edit-changes-undo',
			'item edit-changes-redo',
			'',
			'item edit-paste',
			'item select-document',
			'',
			'item goto-last-edit',
			'item view-dialog-find',
			'',
			'item file-save-current',
			'item file-open',
			'',
			'item file-close-current',
		],
		'textselection_contextmenu' => [
			'item edit-copy',
			'item edit-paste',
			'item edit-replace',
			'item edit-cut',
			'item edit-delete',
			'',
			'item find-selection',
			'item replace-selection',
			'item tool-note-selection',
			'',
			'item edit-selection-convert-uppercase',
			'item edit-selection-convert-lowercase',
		],
		'searchbar_contextmenu' => [
			'checkitem search-attribute-incremental-switch',
			'checkitem search-attribute-autowrap-switch',
			'',
			'checkitem search-attribute-regex-switch',
			'checkitem search-attribute-match-whole-word-switch',
			'checkitem search-attribute-match-word-begin-switch',
			'checkitem search-attribute-match-case-switch',
			'',
			'radioitem search-range-selection',
			'radioitem search-range-document',
			'radioitem search-range-open-docs',
		],
		'status_syntaxstyle_contextmenu' => [
			'radioitem document-syntaxmode-c',
			'radioitem document-syntaxmode-conf',
			'radioitem document-syntaxmode-css',
			'radioitem document-syntaxmode-html',
			'radioitem document-syntaxmode-js',
			'radioitem document-syntaxmode-perl',
			'radioitem document-syntaxmode-xml',
			'radioitem document-syntaxmode-yaml',
			'',
			'item document-syntaxmode-auto',
			'checkitem document-syntaxmode-none',
		],
		'status_whitespace_contextmenu' => [
			'checkitem document-auto-indention',
			'checkitem document-brace-indention',
			'',
			'checkitem view-editpanel-whitespace',
			{'menu document_tab_width' => [
				'checkitem document-tabs-width-1',
				'checkitem document-tabs-width-2',
				'checkitem document-tabs-width-3',
				'checkitem document-tabs-width-4',
				'checkitem document-tabs-width-5',
				'checkitem document-tabs-width-6',
				'checkitem document-tabs-width-8',
			],},
			{'menu document_convert' => [
				'item edit-document-convert-tabs2spaces',
				'item edit-document-convert-spaces2tabs',
				'',
				'item edit-document-convert-indent2spaces',
				'item edit-document-convert-indent2tabs',
				'',
				'item edit-document-format-del-trailing-whitespace',
			],},
			'',
			'radioitem document-tabs-soft',
			'radioitem document-tabs-hard',
		],
		'status_lineendchar_contextmenu' => [
			'checkitem view-editpanel-EOL',
			'',
			'item document-EOL-auto',
			'',
			'radioitem document-EOL-lf',
			'radioitem document-EOL-cr',
			'radioitem document-EOL-cr+lf',
		],
		'status_info_contexmenu' => [
			'radioitem view-statusbar-info-none',
			'radioitem view-statusbar-info-length',
			'radioitem view-statusbar-info-date',
		]
	}
}

1;
