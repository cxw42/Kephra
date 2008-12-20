package Kephra::Config::Default::Localisation;
our $VERSION = '0.03';

use strict;
use warnings;

sub get {
	return {
		about => {
			language => 'english',
			iso_code => 'en',
			coding  => 'ASCII',
			purpose => 'embedded emergency localisation',
			version => $VERSION,
		},
		app => {
			general => {
				untitled => 'untitled'
			},
			menu => {
				file => 'File',
				file_open => 'Open',
				file_close => 'Close',
				file_history => 'Recent',
				file_session => 'Session',
				file_insert_templates => 'Templates',
				edit => 'Edit',
				edit_changes => 'History',
				current_line => 'Line',
				selection => 'Selection',
				selection_format => 'Format',
				selection_comment => 'Comment',
				selection_convert => 'Convert',
				search => 'Search',
				search_attributes => 'Attributes',
				find_functions => 'Find Functions',
				replace_functions => 'Replace Functions',
				bookmark_goto => 'Goto Bookmark',
				bookmark_toggle => 'Toggle Bookmark',
				tools => 'Tools',
				document => 'Document',
				document_change => 'Change',
				'&document_list' => 'Select',
				document_syntaxmode => 'Syntaxmode',
				'document_syntaxmode_A-M' => 'A - M',
				'document_syntaxmode_N-Z' => 'N - Z',
				document_syntaxmode_compiled => 'Compiled',
				document_syntaxmode_interpreted => 'Interpreted',
				document_syntaxmode_data_structure => 'Data Structure',
				document_syntaxmode_document => 'Documents',
				document_syntaxmode_web => 'Webprogramming',
				document_syntaxmode_special => 'Special',
				document_tab_width => 'Tab Width',
				document_lineendchar => 'Lineendchars',
				document_readonly => 'Write Protection',
				view => 'View',
				view_bars => 'App Bars',
				view_panel => 'Panel',
				view_contextmenu => 'Context Menus',
				view_editpanel_contexmenu => 'Edit Panel',
				view_textmargin => 'Text Margin',
				config => 'Config',
				config_app_lang => 'Language',
				config_global => 'Global Config File',
				config_interface => 'User Interface',
				config_localisation => 'Localisation',
				'config_syntaxmode_A-M' => 'Syntaxmodes A - M',
				'config_syntaxmode_N-Z' => 'Syntaxmodes N - Z',
				help => 'Help'
			},
			status => {
				chars => 'Chars',
				cloumn => 'Column',
				line => 'Line',
				lines => 'Lines',
				selection => 'Selection',
				soft_tabs => 'soft tabs',
				hard_tabs => 'hard tabs',
				now_is => 'Now is',
				last_change => 'Last change',
				date => 'Date',
				time => 'Time',
			},
		},
		commandlist => {
			label => {
				app => {
					'exit' => 'Exit',
					'exit-unsaved' => 'Exit Without Save',
				},
				file => {
					new => 'New',
					open => 'Open ...',
					'open-dir' => 'Open Dir ...',
					reload => 'Reload',
					'reload-all' => 'Reload All',
					rename => 'Rename ...',
					insert => 'Insert ...',
					close => {
						current => 'Close',
						all => 'Close All',
						other => 'Close Other',
						unsaved => 'Close Unsaved',
						'all-unsaved' => 'Close All Unsaved',
						'other-unsaved' => 'Close Other Unsaved',
					},
					save => {
						current => 'Save',
						all => 'Save All',
						as => 'Save As ...',
						'copy-as' => 'Save Copy ...',
					},
					print => 'Print ...',
					session => {
						open => 'Open ...',
						add => 'Add ...',
						save => 'Save ...',
						import => 'Import ...',
						export => 'Export ...',
						'backup-open' => 'Restore Backup',
						'backup-save' => 'Save Backup',
					},
				},
				'edit' => {
					'changes' => {
						'undo' => 'Undo',
						'redo' => 'Redo',
						'undo-several' => 'Fast Undo',
						'redo-several' => 'Fast Redo',
						'goto-begin' => 'Jump To Begin',
						'goto-end' => 'Jump To End',
						'delete' => 'Clear Records',
					},
					'cut' => 'Cut',
					'copy' => 'Copy',
					'paste' => 'Paste',
					'replace' => 'Replace',
					'delete' => 'Delete',
					'delete-tab' => 'Del Tab',
					'line' => {
						'cut' => 'Cut',
						'copy' => 'Copy',
						duplicate => 'Duplicate',
						'replace' => 'Replace',
						'delete' => 'Delete',
						'delete-left' => 'Delete Left',
						'delete-right' => 'Delete Right',
						'move' => {
							'line-up' => 'Move Line Up',
							'line-down' => 'Move Line Down',
							'page-up' => 'Move Page Up',
							'page-down' => 'Move Page Down',
						},
					},
					'selection' => {
						'convert' => {
							uppercase => 'Uppercase',
							lowercase => 'Lowercase',
							titlecase => 'Titlecase',
							sentencecase => 'Sentencecase',
							spaces2tabs => 'Spaces To Tabs',
							tabs2spaces => 'Tabs To Spaces',
						},
						comment => {
							'add-perl' => 'Add Perl Style Comment',
							'del-perl' => 'Remove Perl Style Comment',
							'toggle-perl' => 'Toggle Perl Style Comment',
							'add-c' => 'Add C Style Comment',
							'del-c' => 'Remove C Style Comment',
							'add-xml' => 'Add XML Style Comment',
							'del-xml' => 'Remove XML Style Comment',
						},
						'format' => {
							'align-on-begin' => 'Align On Begin',
							'block-on-right-margin' => 'Blockformat On Right Margin',
							'block-on-width' => 'Blockformat On Width ...',
							'linewrap-on-right-margin' => 'Linebreaks On Right Margin',
							'linewrap-on-width' => 'Linebreaks On Width ...',
							'indent-char' => 'Indent Space',
							'dedent-char' => 'Dedent Space',
							'indent-tab' => 'Indent Tab',
							'dedent-tab' => 'Dedent Tab',
							'del-trailing-whitespace' => 'Delete Trailing Space',
							'join-lines' => 'Join Lines',
						},
						'move' => {
							'char-left' => 'Move Left',
							'char-right' => 'Move Right',
							'line-up' => 'Move Up',
							'line-down' => 'Move Down',
							'page-up' => 'Move Page Up',
							'page-down' => 'Move Page Down',
						},
					},
					'document' => {
						convert => {
							indent2spaces => 'Indention 2 Whitespace',
							indent2tabs => 'Indention 2 Tab',
							spaces2tabs => 'Spaces 2 Tabs',
							tabs2spaces => 'Tabs 2 Whitespace',
						},
						'format' => {
							'del-trailing-whitespace' => 'Delete Trailing',
						},
					},
				},
				'select' => {
					'document' => 'Select All',
					'to-block-begin' => '',
					'to-block-end' => '',
				},
				'search' => {
					'attribute' => {
						'autowrap-switch' => 'Auto Wrap',
						'incremental-switch' => 'Incremental Search',
						'regex-switch' => 'Regular Expression',
						'match' => {
							'case-switch' => 'Match Case',
							'whole-word-switch' => 'Whole Word only',
							'word-begin-switch' => 'Word Begin',
						},
					},
					'range' => {
						selection => 'Selection',
						document => 'Document',
						'open-docs' => 'Open Documents'
					},
				},
				find => {
					prev => 'Find Previous',
					'next' => 'Find Next',
					first => 'Find First',
					'last' => 'Find Last',
					selection => 'Find Selection',
					'mark-all' => 'Mark all Matches',
				},
				replace => {
					prev => 'Replace Backward',
					'next' => 'Replace Forward',
					all => 'Replace All',
					'with-confirm' => 'Replace With Confirm',
					selection => 'Replace Selection',
				},
				'goto' => {
					'last-edit' => 'Goto Last Edit',
					line => 'Goto Line Number  ...',
				},
				bookmark => {
					'goto' => {
						1 => 1,
						2 => 2,
						3 => 3,
						4 => 4,
						5 => 5,
						6 => 6,
						7 => 7,
						8 => 8,
						9 => 9,
						'0' => 'O',
					},
					toggle => {
						1 => 1,
						2 => 2,
						3 => 3,
						4 => 4,
						5 => 5,
						6 => 6,
						7 => 7,
						8 => 8,
						9 => 9,
						'0' => 'O',
					},
					'delete-all' => 'Delete Bookmarks',
				},
				tool => {
					note => 'Note',
					'run-document' => 'Run',
					'stop-document' => 'Stop',
				},
				document => {
					'auto-indention' => 'Autoindention',
					'brace-indention' => 'Braceindention',
					'brace-light' => 'Bracelight',
					EOL => {
						auto => 'Align',
						'cr+lf' => 'CR+LF (Windows)',
						cr => 'CR (Macintosh)',
						lf => 'LF (Linux)',
					},
					change => {
						back => 'Switch Back',
						prev => 'Previous Tab',
						'next' => 'Next Tab',
					},
					move => {
						left => 'Move Left',
						right => 'Move Right',
					},
					readonly => {
						'as-attr' => 'As Attribute',
						'on' => 'Always On',
						'off' => 'Always Off',
					},
					syntaxmode => {
						auto => 'Autoselect',
						none => 'None',
						ada => 'Ada',
						as => 'Actionscript',
						asm => 'Assembler',
						ave => 'Avennue',
						baan => 'Baan',
						batch => 'Batch',
						c => 'C | C++',
						conf => 'Conf',
						context => 'Context',
						cs => 'C#',
						css => 'CSS',
						diff => 'Diff',
						eiffel => 'Eiffel',
						err => 'Errorlist',
						forth => 'Forth',
						fortran => 'FORTRAN',
						html => 'HTML',
						idl => 'IDL',
						java => 'Java',
						js => 'Javascript',
						latex => 'LaTeX',
						lisp => 'LISP',
						lua => 'Lua',
						make => 'Makefile',
						matlab => 'Matlab',
						nsis => 'NSIS',
						pascal => 'Pascal',
						perl => 'Perl',
						php => 'PHP',
						property => 'Property',
						ps => 'Postscript',
						python => 'Python',
						ruby => 'Ruby',
						scheme => 'Scheme',
						sh => 'UNIX Shell',
						sql => 'SQL',
						tcl => 'TCL',
						tex => 'TeX',
						vb => 'Visual Basic',
						vbs => 'VB Script',
						xml => 'XML',
						yaml => 'YAML',
					},
					tabs => {
						hard => 'Tabs (HT => "hard tabs")',
						soft => 'Spaces (ST => "soft tabs")',
						'use' => 'Use Tabs',
						width => {
							1 => 1,
							2 => 2,
							3 => 3,
							4 => 4,
							5 => 5,
							6 => 6,
							8 => 8,
						},
					},
				},
				view => {
					dialog => {
						config => 'Config Dialog',
						find => 'Search Dialog',
						replace => 'Replace Dialog',
						info => 'About ...',
						keymap => 'Keymap ...',
					},
					documentation => {
						'advanced-tour' => 'Advanced Tour',
						credits => 'Credits',
						'feature-list' => 'Featurelist',
						'navigation-guide' => 'Navigation Guide',
						welcome => 'Welcome',
						'this-version' => 'This Version',
					},
					editpanel => {
						EOL => 'Lineend Marker',
						'caret-line' => 'Caret Line',
						font => 'Font',
						'indention-guide' => 'Indention Guide',
						'line-wrap' => 'Line Wrap',
						'right-margin' => 'Right Margin',
						whitespace => 'Whitespace',
						contextmenu => {
							custom => 'Custom',
							default => 'Default',
							'no' => 'No Menu',
						},
						margin => {
							marker => 'Marker Margin',
							'line-number' => 'Line Number',
							text => {
								0 => '0 px',
								1 => 1,
								2 => 2,
								4 => 4,
								6 => 6,
								8 => 8,
								10 => 10,
								12 => 12,
							},
						},
					},
					panel => {
						notepad => 'Notepad',
						output => 'Output',
					},
					statusbar => 'Statusbar',
					'statusbar-contexmenu' => 'Statuscontext',
					'statusbar-info' => {
						date => 'File Date',
						'length' => 'File Size',
						none => 'Nothing',
					},
					tabbar => 'Tabbar',
					'tabbar-contexmenu' => 'Tabbar',
					toolbar => {
						main => 'Main Toolbar',
						search => 'Searchbar',
						'search-goto' => 'Searchbar',
					},
					'window-stay-on-top' => 'Stay On Top',
				},
				config => {
					'app-lang' => {
						en => 'English',
						de => 'Deutsch',
						cs => 'Cesky',
						nb => 'Norsk',
					},
					file => {
						global => {
							'open' => 'Open',
							reload => 'Reload',
							'load-from' => 'Load From ...',
							'load-backup' => 'Load Backup',
							'load-defaults' => 'Load Defaults',
							merge => 'Merge With ...',
							save => 'Save',
							'save-as' => 'Save As ...',
						},
						interface => {
							commandlist => 'Command List',
							menubar => 'Main Menu',
							contextmenu => 'Contextmenus',
							maintoolbar => 'Main Toolbar',
							searchbar => 'Searchbar',
							statusbar => 'Statusbar',
							toolbar => 'Toolbar',
						},
						localisation => {
							en => 'English',
							de => 'Deutsch',
							cs => 'Cesky',
							nb => 'Norsk',
						},
						syntaxmode => {
							ada => 'Ada',
							as => 'Actionscript',
							asm => 'Assembler',
							ave => 'Avennue',
							baan => 'Baan',
							batch => 'Batch',
							c => 'C | C++',
							conf => 'Conf',
							context => 'Context',
							cs => 'C#',
							css => 'CSS',
							diff => 'Diff',
							eiffel => 'Eiffel',
							err => 'Errorlist',
							forth => 'Forth',
							fortran => 'FORTRAN',
							html => 'HTML',
							idl => 'IDL',
							java => 'Java',
							js => 'Javascript',
							latex => 'LaTeX',
							lisp => 'LISP',
							lua => 'Lua',
							make => 'Makefile',
							matlab =>'Matlab',
							nsis => 'NSIS',
							pascal => 'Pascal',
							perl => 'Perl',
							php => 'PHP',
							property => 'Property',
							ps => 'Postscript',
							python => 'Python',
							ruby => 'Ruby',
							scheme => 'Scheme',
							sh => 'UNIX Shell',
							sql => 'SQL',
							tcl => 'TCL',
							tex => 'TeX',
							vb => 'Visual Basic',
							vbs => 'VB Script',
							xml => 'XML',
							yaml => 'YAML',
						},
						templates => 'Templates',
					},
				},
			},
			help => {
				app => {
					'exit' => 'shut down the application and save settings and files',
					'exit-unsaved' => 'shut down app without saving the open files',
				},
				file => {
					new => 'opens a new empty text',
					'open' => 'display an existing textfile as a new document',
					'open-dir' => 'open all files of this directory',
					reload => 'read file from hard drive and replace content with displayed',
					'reload-all' => 'reload all opened files',
					'rename' => 'change current files name',
					insert => 'insert file content at caret position',
					close => {
						current => 'close current document, if preset the file will be saved',
						all => 'close all open documents',
						other => 'close all open documents but not the current visible',
						unsaved => 'close current document without save it before it',
						'all-unsaved' => 'close all document without save it before it',
						'other-unsaved' => 'unsaved closing of all open docs but not the current visible',
					},
					save =>{
						current => 'save the displayed state of the current file',
						all => 'save all the currently opened files',
						as => 'save current document under different file name',
						'copy-as' => 'save doc with different name, keep current version open',
					},
					'print' => 'print the current document',
					session => {
						'open' => 'restore an once saved file session',
						add => 'add files of a saved file session',
						save => 'save order and properties of this file session',
						import => 'open files session from another editors format',
						export => 'save files session in another editors format',
						'backup-open' => 'restore the backup session',
						'backup-save' => 'remember current files as the backup session',
					},
				},
				edit => {
					changes => {
						undo => 'mache letzte �nderung im Dokument r�ckg�ngig',
						'redo' => 'zuletzt r�ckg�ngig gemachte �nderung wiederholen',
						'undo-several' => 'mache mehrere �nderungen r�ckg�ngig',
						'redo-several' => 'bringe mehrere �nderungen wieder',
						'goto-begin' => 'bringe Zustand vor allen �nderungen zur�ck',
						'goto-end' => 'hole alle gemachte �nderungen wieder',
						'delete' => 'l�sche alle Aufzeichnungen �ber �nderungen',
					},
					cut => 'cut selected text and store it in the clipboard',
					copy => 'copy selected text to the clipboard',
					paste => 'insert text from the clipboard',
					replace => 'replace selected text with the clipboard',
					'delete' => 'delete and forget selected text',
					'line' => {
						cut => 'cut current line and store it in the clipboard',
						copy => 'copy current line to the clipboard',
						duplicate => 'insert below a copy of the current line',
						replace => 'replace current line with the clipboard',
						'delete' => 'delete and forget current line',
						'delete-left' => 'delete left side from textcursor of current line',
						'delete-right' => 'delete right side from textcursor of current line',
						move => {
							'line-up' => 'move current line one line up',
							'line-down' => 'move current line one line down',
							'page-up' => 'move current line one page up',
							'page-down' => 'move current line one page down',
						},
					},
					selection => {
						convert => {
							uppercase => 'turn selected text to uppercase',
							lowercase => 'turn selected text to lowercase',
							titlecase => 'turn first char of every word uppercase',
							sentencecase => 'turn first char of every sentence uppercase',
							spaces2tabs => 'convert groups of whitespace to tabs',
							tabs2spaces => 'depends on current tab width',
						},
						comment => {
							'add-perl' => 'insert \# after every indention',
							'del-perl' => 'remove all \# following the indention',
							'toggle-perl' => 'comment all uncommented lines and vici versa',
							'add-c' => 'surround selection with /* and */',
							'del-c' => 'remove all /* and */ in the selection',
							'add-xml' => 'surround selection with  <!-- and -->',
							'del-xml' => 'remove all <!-- and --> in the selection',
						},
						'format' => {
							'align-on-begin' => 'align line indentions on first line',
							'block-on-right-margin' => 'format to textblock, that not cross right margin',
							'block-on-width' => 'format to textblock with chosen width ...',
							'linewrap-on-right-margin' => 'split lines before right margin',
							'linewrap-on-width' => 'split lines before chosen width ...',
							'indent-char' => 'increase indention of the selected lines by 1',
							'dedent-char' => 'decrease indention of the selected lines by 1',
							'indent-tab' => 'increase indention by current tab size',
							'dedent-tab' => 'decrease indention by current tab size',
							'del-trailing-whitespace' => 'delete whitespace on line endings',
							'join-lines' => 'delete end of line (EOL) symbols',
						},
						move => {
							'char-left' => 'move selection one character left',
							'char-right' => 'move selection one character right',
							'line-up' => 'move selection one line up',
							'line-down' => 'move selection one line down',
							'page-up' => 'move selection one page up',
							'page-down' => 'move selection one page down',
						},
					},
					document => {
						convert => {
							indent2spaces => 'convert tabs between linestart and first word',
							indent2tabs => 'convert spaces between linestart and first word',
							spaces2tabs => 'convert all spaces to tabs in the current doc',
							tabs2spaces => 'convert all tabs to spaces in the current doc',
						},
						'format' => {
							'del-trailing-whitespace' => 'delete all trailing whitespace',
						},
					},
				},
				'select' => {
					document => 'select entire document',
					'to-block-begin' => '',
					'to-block-end' => '',
				},
				search => {
					attribute => {
						'autowrap-switch' => 'Auto Wrap',
						'incremental-switch' => 'Incremental Search',
						'regex-switch' => 'Regular Expression',
						match => {
							'case-switch' => 'Match Case',
							'whole-word-switch' => 'Whole Word only',
							'word-begin-switch' => 'Word Begin',
						},
					},
					'range' => {
						selection => 'search and replace only within selected text',
						document => 'search and replace in whole current document',
						'open-docs' => 'search and replace in all open documents',
					},
				},
				find => {
					prev => 'find the previous match of the textsearch',
					'next' => 'find the next match of the textsearch',
					first => 'find first textsearch match in document',
					'last' => 'find last textsearch match in document',
					selection => 'remember selected text as current search item',
				},
				replace => {
					prev => 'replace selection and find previous match',
					'next' => 'replace selection and find next match',
					all => 'replace all matches in current search range',
					'with-confirm' => 'confirm or reject to replace every particular match',
					selection => 'remember selected text as current replace item',
				},
				'goto' => {
					'last-edit' => 'jump to position of last change in this document',
					line => 'jump to line with chosen number',
				},
				bookmark => {
					'goto' => {
						1 => 'go to bookmark number 1',
						2 => 'go to bookmark number 2',
						3 => 'go to bookmark number 3',
						4 => 'go to bookmark number 4',
						5 => 'go to bookmark number 5',
						6 => 'go to bookmark number 6',
						7 => 'go to bookmark number 7',
						8 => 'go to bookmark number 8',
						9 => 'go to bookmark number 9',
						0 => 'go to bookmark number 0',
					},
					toggle => {
						1 => 'set here or remove (if present) bookmark 1',
						2 => 'set here or remove (if present) bookmark 2',
						3 => 'set here or remove (if present) bookmark 3',
						4 => 'set here or remove (if present) bookmark 4',
						5 => 'set here or remove (if present) bookmark 5',
						6 => 'set here or remove (if present) bookmark 6',
						7 => 'set here or remove (if present) bookmark 7',
						8 => 'set here or remove (if present) bookmark 8',
						9 => 'set here or remove (if present) bookmark 9',
						0 => 'set here or remove (if present) bookmark 0',
					},
					'delete-all' => 'delete all bookmarks',
				},
				tool => {
					note => 'jump to the notepad',
					'run-document' => 'run current programm and show result in output panel',
					'stop-document' => 'stop the current running output panel process',
				},
				document => {
					'auto-indention' => 'indents new line like previous when Enter pressed ',
					'brace-indention' => 'obey right indention after curly braces when press enter',
					'brace-light' => 'highlights associated pairs of braices',
					EOL => {
						auto => 'make all line endings like in first line',
						'cr+lf' => 'line endings for Windows or Dos',
						cr => ' convert line endings to the Mac standart',
						lf => 'convert line endings to the UNIX standart',
					},
					change => {
						back => 'switches to the last used document',
						prev => 'changes the current document one tab to the left',
						next => 'changes the current document one tab to the right',
					},
					move => {
						left => 'move current document in the tabbar one pos to the left',
						right => 'move current document in the tabbar one pos to the right',
					},
					readonly => {
						'as-attr' => 'turns write protection on if file is readonly',
						'on' => 'disables every modification of this document',
						off => 'makes document always editable even if it can\'t be saved',
					},
					syntaxmode => {
						auto => 'select syntaxmode depending on fileending',
						none => 'turn any syntaxmode settings off',
						ada => 'activate language settings for Ada',
						as => 'activate settings for Macromedia Actionscript',
						asm => 'language settings for Assembler',
						ave => 'highlighting and settings for the Avennue language',
						baan => 'language of the Baan ERP systems',
						batch => 'Microsofts classic commandline batch control language',
						c => 'settings for the C / C++ language family',
						conf => 'for Apache Conf styled configuration files',
						context => 'settings for the ConTeXt Tex Macros',
						cs => 'syntaxmode for Microsoft C-Sharp',
						css => 'syntaxmode for Cascading Style Sheet language',
						diff => 'syntaxmode for patch files',
						eiffel => 'Bertrand Meyers objectoriented language Eiffel',
						err => 'syntaxmode for errorcode files',
						forth => 'language of the Forth systems',
						fortran => 'syntaxmode of the FORmula TRANslation language',
						html => 'syntaxmode for the HyperText Markup Language',
						idl => 'syntaxmode of the Interface Definition Language',
						java => 'Settings for Sun\'s Java language',
						js => 'syntaxmode for Javascript',
						latex => 'syntaxmode for the LaTeX Tex macros',
						lisp => 'LISt Prozessor settings',
						lua => 'syntaxmode for the embedding language Lua',
						make => 'highlighting for make tool scripts',
						matlab => 'MATLAB scripting language',
						nsis => 'language of the Nullsoft Scriptable Install System',
						pascal => 'Niklaus Wirth\'s structured language Pascal',
						perl => 'syntaxmode for Larry Walls Perl',
						php => 'Rasmus Lehrdorf PHP Hypertext Prozessors',
						property => 'highlighting for simple config files',
						ps => 'Adobe\'s document desciption language Postscript',
						python => 'Guido van Rossums dynamic language Python',
						ruby => 'Yukihiro "Matz" Matsumoto\'s full objectoriented language',
						scheme => 'syntaxmode of the MIT LISP dialect',
						sh => 'settings for the UNIX Bourne Shell',
						sql => 'Structured Query Language originated from IBM',
						tcl => 'Tool Command Language from John Ousterhout',
						tex => 'Donald E. Knuth macro language for type setting',
						vb => 'settings for Microsoft Visual Basic',
						vbs => 'settings for Microsoft Visual Basic Script',
						xml => 'syntaxmode for the eXtensible Markup Language',
						yaml => 'syntaxmode for Indy\'s YAML Ain\'t Markup Language',
					},
					tabs => {
						hard => 'insert a tab while hitting the tab key',
						soft => 'insert several whitespaces while hitting tab key',
						'use' => 'use tabs (hard tabs) or whitespaces (soft tabs)',
						width => {
							1 => 'set width of tabs to an equal of 1 character',
							2 => 'set width of tabs to an equal of 2 characters',
							3 => 'set width of tabs to an equal of 3 characters',
							4 => 'set width of tabs to an equal of 4 characters',
							5 => 'set width of tabs to an equal of 5 characters',
							6 => 'set width of tabs to an equal of 6 characters',
							8 => 'set width of tabs to an equal of 8 characters',
						},
					},
				},
				view => {
					dialog => {
						config => 'display and change the configuration of the program',
						find => 'open dialog for text search and settings',
						replace => 'open dialog for find and replace text',
						info => 'version numbers, authors, credits, license',
						keymap => 'lists which key kombination triggers which function',
					},
					documentation => {
						'advanced-tour' => 'introduction of unusual but practical features',
						credits => 'list of all involved people',
						'feature-list' => 'thematically sorted description of all functionalities',
						'navigation-guide' => 'explanations of the user interface',
						welcome => 'first steps: how to get help and give feedback',
						'this-version' => 'new features and important changes of the current version',
					},
					editpanel => {
						EOL => 'switch visibility of the end of line marker',
						'caret-line' => 'highlights row where caret(textcursor) is located',
						font => 'change font family, size, style etc.',
						'indention-guide' => 'vertical dotted lines in intervals of tab width',
						'line-wrap' => 'breaks long lines on window edge only visually',
						'right-margin' => 'shows straight vertical line on seleted width',
						whitespace => 'set whitespaces and tabs visible as dots and arrows',
						contextmenu => {
							custom => 'aktivate customizable editpanel context menu',
							default => 'aktivate default scintilla context menu',
							'no' => 'deaktivate all editpanel context menu',
						},
						margin => {
							marker => 'margin for bookmarks, marker, debug steps ...',
							'line-number' => 'sets line numbers visible',
							text => {
								0 => 'set extra margin on both sides of textfield to 0 pixel',
								1 => 'set extra margin on both sides of textfield to 1 pixel',
								2 => 'set extra margin on both sides of textfield to 2 pixel',
								4 => 'set extra margin on both sides of textfield to 4 pixel',
								6 => 'set extra margin on both sides of textfield to 6 pixel',
								8 => 'set extra margin on both sides of textfield to 8 pixel',
								10 => 'set extra margin on both sides of textfield to 10 pixel',
								12 => 'set extra margin on both sides of textfield to 12 pixel',
							},
						},
					},
					panel => {
						notepad => 'switch visibility of the Notepad panel',
						output => 'switch visibility of the Output panel',
					},
					statusbar => 'switch visibility of the statusbar on bottom of the window',
					'statusbar-contexmenu' => 'enable or disable context menus on statusbar',
					'statusbar-info' => {
						date => 'display change date of the current file in statusbar info field',
						'length' => 'display size info of the current file in statusbar info field',
						none => 'display nothing in statusbar info field',
					},
					tabbar => 'switch visibility of the tabbar, toolbar for doc selection',
					'tabbar-contexmenu' => 'enable or disable context menus on tabbar',
					toolbar => {
						main => 'switch visibility of the main toolbar',
						search => 'toolbar with text seach and navigation functions',
						'search-goto' => 'goto searchbar and use find function',
					},
					'window-stay-on-top' => 'application window remains always visible',
				},
				config => {
					'app-lang' => {
						cs => 'change user interface language to czech',
						de => 'change user interface language to german',
						en => 'change user interface language to english',
						nb => 'change user interface language to norwegian',
					},
					file => {
						global => {
							'open' => 'open file with current global configurations',
							reload => 'reload current global configuration file',
							'load-from' => 'load global configs from chosen file',
							'load-backup' => 'load global configs from backup',
							'load-defaults' => 'load default global configs',
							merge => 'merge current global configs with settings in this file',
							save => 'save current global configs into the file we load from',
							'save-as' => 'save current global configs into this file',
						},
						interface => {
							commandlist => 'definition for function calls, key binding, icons',
							menubar => 'open definition file for the menubar',
							contextmenu => 'open definition file for all contextmenu',
							maintoolbar => 'open definition file for the main toolbar',
							searchbar => 'open definition file for the searchbar',
							statusbar => 'open definition file for the statusbar',
							toolbar => 'open default definition file for toolbars',
						},
						localisation => {
							en => 'open english translation of application label texts',
							de => 'open german translation of the application texts',
							cs => 'open czech translation file',
							nb => 'open norwegian translation file',
						},
						syntaxmode => {
							ada => 'open file with settings for the Ada language',
							as => 'open file with Macromedia Actionscript settings',
							asm => 'open file with language settings for Assembler',
							ave => 'open settings for the Avennue language',
							baan => 'language of the Baan ERP systems',
							batch => 'Microsofts classic commandline batch control language',
							c => 'open file with settings for the C / C++  languages',
							conf => 'settings for files in the Apache Conf style',
							context => 'settings for ConTeXt Tex Macros',
							cs => 'open file with syntaxmode for Microsoft C-Sharp',
							css => 'settings for the Cascading Style Sheet language',
							diff => 'syntaxmode for patch files',
							eiffel => 'Bertrand Meyers objectoriented language Eiffel',
							err => 'syntaxmode for errorcode files',
							forth => 'settings for the language of the Forth systems',
							fortran => 'syntaxmode von FORmula TRANslation open',
							html => 'syntaxmode for HyperText Markup Language open',
							idl => 'syntaxmode der Interface Definition Language open',
							java => 'open settings for Sun\'s Java language',
							js => 'open syntaxmode for Javascript',
							latex => 'open syntaxmode for the Tex macros named LaTeX',
							lisp => 'open settings for the almighty LISt Prozessor',
							lua => 'settings for the extension language Lua',
							nsis => ' language of the Nullsoft Scriptable Install System',
							make => 'highlighting for make tool scripts',
							matlab => 'MATLAB scripting language',
							pascal => 'settings for Niklaus Wirth\'s procedural language Pascal',
							perl => 'file with syntaxmode for Larry Walls Perl',
							php => 'Rasmus Lehrdorf PHP Hypertext Prozessor',
							property => 'Highlighting for simple config files',
							ps => 'Adobe document description language Postscript',
							python => 'Guido van Rossums dynamic language Python',
							ruby => 'Yukihiro "Matz" Matsumoto\'s full object oriented Ruby',
							scheme => 'open syntaxmode of the MIT LISP dialect Scheme',
							sh => 'open settings for the UNIX Bourne Shell',
							sql => 'Structured Query Language, originated from IBM',
							tcl => 'Tool Command Language from John Ousterhout',
							tex => 'Donald E. Knuth\'s macro language for typesetting',
							vb => 'open file with settings for Microsoft Visual Basic',
							vbs => 'open file with settings for Microsoft Visual Basic Script',
							xml => 'open settings for die eXtensible Markup Language',
							yaml => 'open settings for Indy\'s YAML Ain\'t Markup Language',
						},
						templates => 'open file with the current template definitions',
					},
				},
			},
		},
		dialog => {
			config_file => {
				load =>'load configuration from the file :',
				save => 'store current program configuration into the file :',
			},
			edit => {
				goto_line_headline => 'goto line',
				goto_line_input => 'choose linenumber :',
				wrap_custom_headline => 'custom word wrapping',
				wrap_width_input => 'choose new line width (maximum number of chars) :',
			},
			error => {
				general => 'Error',
				no_param => 'called without needed parameters',
				file => 'file handling error',
				file_find => "can't find file :",
				file_read => "can't read file :",
				file_write => "can't write file :",
				config_read => "can't read config file :",
				config_parse => 'file has no data :',
				write_protected => 'This file is write protected by the file system.',
				write_protected2 => 'Please unlock this or save this text under an other filename.',
			},
			file => {
				files => 'Files',
				open => 'Open File',
				insert => 'Insert File',
				rename => 'Rename File',
				save_as => 'Save File As',
				save_all => 'Save All',
				save_none => 'Save None',
				save_copy_as => 'Save A Copy Of This File As',
				overwrite => 'Overwrite Existing File !',
				close_unsaved => 'Closing Unsafed File',
				save_current => 'Save Current File ?',
				save_open => 'Save All Open Files ?',
				quit_unsaved => 'Closing Unsafed Files :',
				open_session => 'Open File Session',
				add_session => 'Add File Session',
				save_session => 'Save Current File Session',
				import_session => 'Import File Session',
				export_session => 'Export File Session',
				open_dir => 'Open Files of Directory :',
				file_changed => 'File Changed',
				file_changed_msg => 'The following file has changed :',
				file_deleted => 'File Deleted',
				file_deleted_msg = 'The following file can not be found anymore :',
			},
			general => {
				apply => 'Apply',
				save => 'Save',
				overwrite => 'Overwrite',
				restore => 'Restore',
				cancel => 'Cancel',
				close => 'Close',
				all => 'All',
				select => 'Select',
				selected => 'Selected',
				none => 'None',
				dont_allow => 'Your settings dont allow this.',
			},
			help => {},
			info => {
				title => 'Info about',
				mady_by => 'by',
				licensed => 'licensed under',
				detail => 'see under help > license for credits and',
				more => 'explicit licenses',
				homepage => 'for more info visit',
				contains => 'this version contains',
				and => 'and',
				wrappes => 'which wrappes',
				extra => 'extra Perl Modules',
				dedication => 'Deditcated to all people who ever tried to write an editor.',
			},
			keyboard_map => {
				title => 'Keyboard Map',
			},
			search => {
				title => 'Find and Replace',
				confirm => {
					title => 'Replace With Confirmation',
					text => 'Replace This ?',
				},
				label => {
					search_for => 'Search for :',
					replace_with => 'Replace with :',
					case => 'Match Case',
					word_begin => 'Word Begin',
					whole_word => 'Whole Word Only',
					regex => 'Regular Expression',
					auto_wrap => 'Auto Wrap',
					incremental => 'Incremental Search',
					search_in => 'Search in',
					selection => 'Selection',
					document => 'Current Doc',
					open_documents => 'Open Docs',
					search => 'Find',
					replace_all => 'Replace All',
					with_confirmation => 'With Confirmation',
				},
				hint => {
					match_case => 'differ between UPPER and lower case',
					match_word_begin => 'match only beginnins of words',
					match_whole_word => 'match only whole words',
					match_regex => 'evaluates simple regular expression',
					incremental => 'search as you type',
					auto_wrap => 'jumpes between file endings',
					forward => 'find next',
					backward => 'find previous',
					fast_forward => 'find fast forward',
					fast_backward => 'find fast backward',
					document_start => 'find first in document',
					document_end => 'find last In document',
					replace_forward => 'replace and find next',
					replace_backward => 'replace and find previous',
				},
			},
			settings => {
				title => 'Configuration Dialog',
				panel => {
					general => 'General',
					edit => 'Edit Panel',
					files => 'Files',
				},
			},
		},
		key => {
			back => 'Back',
			esc => 'Esc',
			enter => 'Enter',
			del => 'Del',
			left => 'Left',
			right => 'Right',
			up => 'Up',
			down => 'Down',
			pgup => 'Page Up',
			pgdn => 'Page Down',
			space => 'Space',
			tab => 'Tab',
			meta => {
				alt => 'Alt',
				'shift' => 'Shift',
				ctrl => 'Ctrl',
			},
		},
	}
}

1;
