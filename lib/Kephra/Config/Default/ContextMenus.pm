package Kephra::Config::Default::ContextMenus;
our $VERSION = '0.01';

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
		'document_syntaxstyle_contextmenu' => [
			'checkitem document-syntaxmode-c',
			'checkitem document-syntaxmode-conf',
			'checkitem document-syntaxmode-css',
			'checkitem document-syntaxmode-html',
			'checkitem document-syntaxmode-js',
			'checkitem document-syntaxmode-perl',
			'checkitem document-syntaxmode-xml',
			'checkitem document-syntaxmode-yaml',
			'',
			'item document-syntaxmode-auto',
			'checkitem document-syntaxmode-none',
		],
		'document_whitespace_contextmenu' => [
			'item edit-document-format-del-trailing-whitespace',
			'',
			'checkitem document-auto-indention',
			'',
			'item edit-document-convert-indent2spaces',
			'item edit-document-convert-indent2tabs',
			'',
			'item edit-document-convert-tabs2spaces',
			'item edit-document-convert-spaces2tabs',
			'',
			'checkitem document-tabs-soft',
			'checkitem document-tabs-hard',
		],
		'document_lineendchar_contextmenu' => [
			'checkitem view-editpanel-EOL',
			'',
			'item document-EOL-auto',
			'',
			'checkitem document-EOL-lf',
			'checkitem document-EOL-cr',
			'checkitem document-EOL-cr+lf',
		],
		'document_info_contexmenu' => [
			'radioitem view-statusbar-info-none',
			'radioitem view-statusbar-info-length',
			'radioitem view-statusbar-info-date',
		]
	}
}

1;
