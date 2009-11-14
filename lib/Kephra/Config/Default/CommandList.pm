package Kephra::Config::Default::CommandList;
our $VERSION = '0.04';

use strict;
use warnings;

sub get {
	return {
		call => {
			app => {
				exit => 'Kephra::App::exit()',
				'exit-unsaved' => 'Kephra::App::exit_unsaved()',
			},
			file => {
				new => 'Kephra::File::new()',
				open => 'Kephra::File::open()',
				'open-dir' => 'Kephra::File::open_all_of_dir()',
				reload => 'Kephra::File::reload_current()',
				'reload-all' => 'Kephra::File::reload_all()',
				insert => 'Kephra::File::insert()',
				save => {
					current => 'Kephra::File::save_current()',
					all => 'Kephra::File::save_all()',
					as => 'Kephra::File::save_as()',
					'copy-as' => 'Kephra::File::save_copy_as()',
				},
				rename => 'Kephra::File::rename()',
				print => 'Kephra::File::print()',
				close => {
					current => 'Kephra::File::close()',
					all => 'Kephra::File::close_all()',
					other => 'Kephra::File::close_other()',
					unsaved => 'Kephra::File::close_unsaved()',
					'all-unsaved' => 'Kephra::File::close_all_unsaved()',
					'other-unsaved' => 'Kephra::File::close_other_unsaved()',
				},
				session => {
					open => 'Kephra::File::Session::restore_from()',
					add => 'Kephra::File::Session::add_from()',
					save => 'Kephra::File::Session::save_as()',
					import => 'Kephra::File::Session::import_scite()',
					export => 'Kephra::File::Session::export_scite()',
					'backup-open' => 'Kephra::File::Session::load_backup()',
					'backup-save' => 'Kephra::File::Session::save_backup()',
				},
			},
			edit => {
				changes => {
					undo => 'Kephra::Edit::History::undo()',
					redo => 'Kephra::Edit::History::redo()',
					'undo-several' => 'Kephra::Edit::History::undo_several()',
					'redo-several' => 'Kephra::Edit::History::redo_several()',
					'goto-begin' => 'Kephra::Edit::History::undo_begin()',
					'goto-end' => 'Kephra::Edit::History::redo_end()',
					delete => 'Kephra::Edit::History::clear_history()',
				},
				cut => 'Kephra::Edit::cut()',
				copy => 'Kephra::Edit::copy()',
				paste => 'Kephra::Edit::paste()',
				replace => 'Kephra::Edit::replace()',
				delete => 'Kephra::Edit::clear()',
				'delete-tab' => 'Kephra::Edit::del_back_tab()',
				line => {
					cut => 'Kephra::Edit::cut_current_line()',
					copy => 'Kephra::Edit::copy_current_line()',
					duplicate => 'Kephra::Edit::double_current_line()',
					replace => 'Kephra::Edit::replace_current_line()',
					delete => 'Kephra::Edit::del_current_line()',
					'delete-left' => 'Kephra::Edit::del_line_left()',
					'delete-right' => 'Kephra::Edit::del_line_right()',
					move => {
						'line-up' => 'Kephra::Edit::selection_move_up()',
						'line-down' => 'Kephra::Edit::selection_move_down()',
						'page-up' => 'Kephra::Edit::selection_move_page_up()',
						'page-down' => 'Kephra::Edit::selection_move_page_down()',
					}
				},
				selection => {
					convert => {
						uppercase => 'Kephra::Edit::Convert::upper_case()',
						lowercase => 'Kephra::Edit::Convert::lower_case()',
						titlecase => 'Kephra::Edit::Convert::title_case()',
						sentencecase => 'Kephra::Edit::Convert::sentence_case()',
						spaces2tabs => 'Kephra::Edit::Convert::spaces2tabs()',
						tabs2spaces => 'Kephra::Edit::Convert::tabs2spaces()',
						spaces2entities => 'Kephra::Edit::Convert::spaces2entities()',
						entities2spaces => 'Kephra::Edit::Convert::entities2spaces()',
						chars2entities => 'Kephra::Edit::Convert::chars2entities()',
						entities2chars => 'Kephra::Edit::Convert::entities2chars()',
					},
					comment => {
						'add-perl' => "Kephra::Edit::Comment::add_block('#')",
						'del-perl' => "Kephra::Edit::Comment::remove_block('#')",
						'toggle-perl' => "Kephra::Edit::Comment::toggle_block('#')",
						'add-c' => "Kephra::Edit::Comment::add_stream( '/*', '*/' )",
						'del-c' => "Kephra::Edit::Comment::remove_stream( '/*', '*/' )",
						'add-xml' => "Kephra::Edit::Comment::add_stream( '<!--', '-->' )",
						'del-xml' => "Kephra::Edit::Comment::remove_stream( '<!--', '-->' )",
					},
					format => {
						'align-on-begin' => 'Kephra::Edit::Format::align_indent()',
						'block-on-right-margin' => 'Kephra::Edit::Format::blockformat_LLI()',
						'block-on-width' => 'Kephra::Edit::Format::blockformat_custom()',
						'linewrap-on-right-margin' => 'Kephra::Edit::Format::linebreak_LLI()',
						'linewrap-on-width' => 'Kephra::Edit::Format::linebreak_custom()',
						'indent-char' => 'Kephra::Edit::Format::indent_space()',
						'dedent-char' => 'Kephra::Edit::Format::dedent_space()',
						'indent-tab' => 'Kephra::Edit::Format::indent_tab()',
						'dedent-tab' => 'Kephra::Edit::Format::dedent_tab()',
						'del-trailing-whitespace' => 'Kephra::Edit::Format::del_trailing_spaces()',
						'join-lines' => 'Kephra::Edit::Format::join_lines()',
					},
					move => {
						'char-left' => 'Kephra::Edit::selection_move_left()',
						'char-right' => 'Kephra::Edit::selection_move_right()',
						'line-up' => 'Kephra::Edit::selection_move_up()',
						'line-down' => 'Kephra::Edit::selection_move_down()',
						'page-up' => 'Kephra::Edit::selection_move_page_up()',
						'page-down' => 'Kephra::Edit::selection_move_page_down()',
					},
				},
				document => {
					convert => {
						indent2spaces => 'Kephra::Document::convert_indent2spaces()',
						indent2tabs => 'Kephra::Document::convert_indent2tabs()',
						spaces2tabs => 'Kephra::Document::convert_spaces2tabs()',
						tabs2spaces => 'Kephra::Document::convert_tabs2spaces()',
					},
					format => {
						'del-trailing-whitespace' => 'Kephra::Document::del_trailing_spaces()',
					},
				},
			},
			select => {
				document => 'Kephra::Edit::Select::document()',
				'to-block-begin' => 'Kephra::Edit::Select::to_block_begin()',
				'to-block-end' => 'Kephra::Edit::Select::to_block_end()',
			},
			search => {
				attribute => {
					'autowrap-switch' => "Kephra::Edit::Search::switch_attribute('auto_wrap')",
					'incremental-switch' => "Kephra::Edit::Search::switch_attribute('incremental')",
					'regex-switch' => "Kephra::Edit::Search::switch_attribute('match_regex')",
					match => {
						'case-switch' => "Kephra::Edit::Search::switch_attribute('match_case')",
						'whole-word-switch' => "Kephra::Edit::Search::switch_attribute('match_whole_word')",
						'word-begin-switch' => "Kephra::Edit::Search::switch_attribute('match_word_begin')",
					},
				},
				range => {
					selection => "Kephra::Edit::Search::set_range('selection')",
					document => "Kephra::Edit::Search::set_range('document')",
					'open-docs' => "Kephra::Edit::Search::set_range('open_docs')",
				},
			},
			find => {
				prev => 'Kephra::Edit::Search::find_prev()',
				next => 'Kephra::Edit::Search::find_next()',
				first => 'Kephra::Edit::Search::find_first()',
				last => 'Kephra::Edit::Search::find_last()',
				selection => 'Kephra::Edit::Search::set_selection_as_find_item()',
			},
			replace => {
				prev => 'Kephra::Edit::Search::replace_back()',
				next => 'Kephra::Edit::Search::replace_fore()',
				all => 'Kephra::Edit::Search::replace_all()',
				'with-confirm' => 'Kephra::Edit::Search::replace_confirm()',
				selection => 'Kephra::Edit::Search::set_selection_as_replace_item()',
			},
			goto => {
				block => {
					down => 'Kephra::Edit::Goto::next_block()',
					up => 'Kephra::Edit::Goto::prev_block()',
				},
				brace => {
					down => 'Kephra::Edit::Goto::next_related_brace()',
					left => 'Kephra::Edit::Goto::prev_brace()',
					right => 'Kephra::Edit::Goto::next_brace()',
					up => 'Kephra::Edit::Goto::prev_related_brace()',
				},
				'last-edit' => 'Kephra::Edit::Goto::last_edit()',
				line => 'Kephra::Edit::Goto::line_nr()',
			},
			bookmark => {
				goto => {
					1 => 'Kephra::Edit::Bookmark::goto_nr(1)',
					2 => 'Kephra::Edit::Bookmark::goto_nr(2)',
					3 => 'Kephra::Edit::Bookmark::goto_nr(3)',
					4 => 'Kephra::Edit::Bookmark::goto_nr(4)',
					5 => 'Kephra::Edit::Bookmark::goto_nr(5)',
					6 => 'Kephra::Edit::Bookmark::goto_nr(6)',
					7 => 'Kephra::Edit::Bookmark::goto_nr(7)',
					8 => 'Kephra::Edit::Bookmark::goto_nr(8)',
					9 => 'Kephra::Edit::Bookmark::goto_nr(9)',
					0 => 'Kephra::Edit::Bookmark::goto_nr(0)',
				},
				toggle => {
					1 => 'Kephra::Edit::Bookmark::toggle_nr(1)',
					2 => 'Kephra::Edit::Bookmark::toggle_nr(2)',
					3 => 'Kephra::Edit::Bookmark::toggle_nr(3)',
					4 => 'Kephra::Edit::Bookmark::toggle_nr(4)',
					5 => 'Kephra::Edit::Bookmark::toggle_nr(5)',
					6 => 'Kephra::Edit::Bookmark::toggle_nr(6)',
					7 => 'Kephra::Edit::Bookmark::toggle_nr(7)',
					8 => 'Kephra::Edit::Bookmark::toggle_nr(8)',
					9 => 'Kephra::Edit::Bookmark::toggle_nr(9)',
					0 => 'Kephra::Edit::Bookmark::toggle_nr(0)',
				},
				'delete-all' => 'Kephra::Edit::Bookmark::delete_all()',
			},
			tool => {
				note => 'Kephra::Plugin::Notepad::note()',
				'note-selection' => 'Kephra::Plugin::Notepad::append_selection()',
				'interpreter-run-document' => 'Kephra::Plugin::Output::run()',
				'interpreter-stop-document' => 'Kephra::Plugin::Output::stop()',
				'output-inc' => 'Kephra::Plugin::Output::display_inc()',
			},
			document => {
				'auto-indention' => 'Kephra::Document::Property::switch_autoindention()',
				'brace-indention' => 'Kephra::Document::Property::switch_braceindention()',
				change => {
					back => 'Kephra::Document::Change::switch_back()',
					prev => 'Kephra::Document::Change::tab_left()',
					next => 'Kephra::Document::Change::tab_right()',
				},
				EOL => {
					'auto' => "Kephra::Document::Property::convert_EOL('auto')",
					'cr+lf' => "Kephra::Document::Property::convert_EOL('cr+lf')",
					cr => "Kephra::Document::Property::convert_EOL('cr')",
					lf => "Kephra::Document::Property::convert_EOL('lf')",
				},
				move => {
					left => 'Kephra::Document::Change::move_left()',
					right => 'Kephra::Document::Change::move_right()',
				},
				readonly => {
					'as-attr' => "Kephra::Document::Property::set_readonly('protect')",
					on => "Kephra::Document::Property::set_readonly('on')",
					off => "Kephra::Document::Property::set_readonly('off')",
				},
				syntaxmode => {
					auto => "Kephra::Document::SyntaxMode::set('auto')",
					none => "Kephra::Document::SyntaxMode::set('none')",
					ada => "Kephra::Document::SyntaxMode::set('ada')",
					as => "Kephra::Document::SyntaxMode::set('as')",
					asm => "Kephra::Document::SyntaxMode::set('asm')",
					ave => "Kephra::Document::SyntaxMode::set('ave')",
					baan => "Kephra::Document::SyntaxMode::set('baan')",
					batch => "Kephra::Document::SyntaxMode::set('batch')",
					c => "Kephra::Document::SyntaxMode::set('cpp')",
					conf => "Kephra::Document::SyntaxMode::set('conf')",
					context => "Kephra::Document::SyntaxMode::set('context')",
					cs => "Kephra::Document::SyntaxMode::set('cs')",
					css => "Kephra::Document::SyntaxMode::set('css')",
					diff => "Kephra::Document::SyntaxMode::set('diff')",
					eiffel => "Kephra::Document::SyntaxMode::set('eiffel')",
					err => "Kephra::Document::SyntaxMode::set('err')",
					forth => "Kephra::Document::SyntaxMode::set('forth')",
					fortran => "Kephra::Document::SyntaxMode::set('fortran')",
					html => "Kephra::Document::SyntaxMode::set('html')",
					idl => "Kephra::Document::SyntaxMode::set('idl')",
					java => "Kephra::Document::SyntaxMode::set('java')",
					js => "Kephra::Document::SyntaxMode::set('js')",
					latex => "Kephra::Document::SyntaxMode::set('latex')",
					lisp => "Kephra::Document::SyntaxMode::set('lisp')",
					lua => "Kephra::Document::SyntaxMode::set('lua')",
					make => "Kephra::Document::SyntaxMode::set('make')",
					matlab => "Kephra::Document::SyntaxMode::set('matlab')",
					nsis => "Kephra::Document::SyntaxMode::set('nsis')",
					pascal => "Kephra::Document::SyntaxMode::set('pascal')",
					perl => "Kephra::Document::SyntaxMode::set('perl')",
					php => "Kephra::Document::SyntaxMode::set('php')",
					property => "Kephra::Document::SyntaxMode::set('property')",
					ps => "Kephra::Document::SyntaxMode::set('ps')",
					python => "Kephra::Document::SyntaxMode::set('python')",
					ruby => "Kephra::Document::SyntaxMode::set('ruby')",
					scheme => "Kephra::Document::SyntaxMode::set('scheme')",
					sh => "Kephra::Document::SyntaxMode::set('sh')",
					sql => "Kephra::Document::SyntaxMode::set('sql')",
					tcl => "Kephra::Document::SyntaxMode::set('tcl')",
					tex => "Kephra::Document::SyntaxMode::set('tex')",
					vb => "Kephra::Document::SyntaxMode::set('vb')",
					vbs => "Kephra::Document::SyntaxMode::set('vbs')",
					xml => "Kephra::Document::SyntaxMode::set('xml')",
					yaml => "Kephra::Document::SyntaxMode::set('yaml')",
				},
				tabs => {
					hard => 'Kephra::Document::Property::set_tabs_hard()',
					soft => 'Kephra::Document::Property::set_tabs_soft()',
					use => 'Kephra::Document::Property::switch_tab_mode()',
					width => {
						1 => 'Kephra::Document::Property::set_tab_size(1)',
						2 => 'Kephra::Document::Property::set_tab_size(2)',
						3 => 'Kephra::Document::Property::set_tab_size(3)',
						4 => 'Kephra::Document::Property::set_tab_size(4)',
						5 => 'Kephra::Document::Property::set_tab_size(5)',
						6 => 'Kephra::Document::Property::set_tab_size(6)',
						8 => 'Kephra::Document::Property::set_tab_size(8)',
					},
				},
			},
			view => {
				dialog => {
					config => 'Kephra::Dialog::config()',
					find => 'Kephra::Dialog::find()',
					replace => 'Kephra::Dialog::replace()',
					info => 'Kephra::Dialog::info()',
					keymap => 'Kephra::Help::keyboard_map()',
				},
				documentation => {
					'advanced-tour' => 'Kephra::Help::advanced_tour()',
					credits => 'Kephra::Help::credits()',
					'feature-list' => 'Kephra::Help::feature_tour()',
					'navigation-guide' => 'Kephra::Help::navigation_guide',
					welcome => 'Kephra::Help::welcome()',
					'this-version' => 'Kephra::Help::version_text()',
				},
				editpanel => {
					EOL => 'Kephra::App::EditPanel::switch_EOL_visibility()',
					'brace-light' => 'Kephra::App::EditPanel::switch_bracelight()',
					'caret-line' => 'Kephra::App::EditPanel::switch_caret_line_visibility()',
					font => 'Kephra::App::EditPanel::change_font()',
					'indention-guide' => 'Kephra::App::EditPanel::switch_indention_guide_visibility()',
					'line-wrap' => 'Kephra::App::EditPanel::switch_autowrap_mode()',
					'right-margin' => 'Kephra::App::EditPanel::switch_LLI_visibility()',
					whitespace => 'Kephra::App::EditPanel::switch_whitespace_visibility()',
					contextmenu => {
						custom => "Kephra::App::ContextMenu::set_editpanel('custom')",
						no => "Kephra::App::ContextMenu::set_editpanel('none')",
						default => "Kephra::App::ContextMenu::set_editpanel('default')",
					},
					margin => {
						'line-number' => 'Kephra::App::EditPanel::Margin::switch_line_number()',
						marker => 'Kephra::App::EditPanel::Margin::switch_marker()',
						'text-fold' => 'Kephra::App::EditPanel::Margin::switch_fold()',
						text => {
							0 => 'Kephra::App::EditPanel::Margin::set_text_width(0)',
							1 => 'Kephra::App::EditPanel::Margin::set_text_width(1)',
							2 => 'Kephra::App::EditPanel::Margin::set_text_width(2)',
							3 => 'Kephra::App::EditPanel::Margin::set_text_width(3)',
							4 => 'Kephra::App::EditPanel::Margin::set_text_width(4)',
							6 => 'Kephra::App::EditPanel::Margin::set_text_width(6)',
							8 => 'Kephra::App::EditPanel::Margin::set_text_width(8)',
							10 => 'Kephra::App::EditPanel::Margin::set_text_width(10)',
							12 => 'Kephra::App::EditPanel::Margin::set_text_width(12)',
						},
					},
					'fold-toggle' => {
						all => 'Kephra::App::EditPanel::Margin::toggle_all()',
						here => 'Kephra::App::EditPanel::Margin::toggle_here()',
						recursively => 'Kephra::App::EditPanel::Margin::toggle_recursively()',
						siblings => 'Kephra::App::EditPanel::Margin::toggle_siblings()',
					},
				},
				panel => {
					notepad => 'Kephra::Plugin::Notepad::switch_visibility()',
					output => 'Kephra::Plugin::Output::switch_visibility()',
				},
				statusbar => 'Kephra::App::StatusBar::switch_visibility()',
				'statusbar-contexmenu' => 'Kephra::App::StatusBar::switch_contextmenu_visibility()',
				'statusbar-info' => {
					date => "Kephra::App::StatusBar::set_info_msg_nr(2)",
					length => "Kephra::App::StatusBar::set_info_msg_nr(1)",
					none => "Kephra::App::StatusBar::set_info_msg_nr('0')",
				},
				tabbar => 'Kephra::App::TabBar::switch_visibility()',
				'tabbar-contexmenu' => 'Kephra::App::TabBar::switch_contextmenu_visibility()',
				toolbar => {
					main => 'Kephra::App::MainToolBar::switch_visibility()',
					'search-goto' => 'Kephra::App::SearchBar::enter_focus()',
					search => 'Kephra::App::SearchBar::switch_visibility()',
				},
				'window-stay-on-top' => 'Kephra::App::Window::switch_on_top_mode()',
				webpage => {
					forum => 'Kephra::Help::forum_site()',
					documentation => 'Kephra::Help::online_documentation()',
				}
			},
			config => {
				file => {
					global => {
						open => 'Kephra::Config::Global::open_current_file()',
						reload => 'Kephra::Config::Global::reload_current()',
						'load-from' => 'Kephra::Config::Global::load_from()',
						'load-backup' => 'Kephra::Config::Global::load_backup_file()',
						'load-defaults' => 'Kephra::Config::Global::load_defaults()',
						merge => 'Kephra::Config::Global::merge_with()',
						save => 'Kephra::Config::Global::save()',
						'save-as' => 'Kephra::Config::Global::save_as()',
					},
					interface => {
						commandlist => "Kephra::Config::Interface::open_file('commandlist')",
						menubar => "Kephra::Config::Interface::open_file('menubar')",
						contextmenu => "Kephra::Config::Interface::open_file('contextmenu')",
						toolbar => "Kephra::Config::Interface::open_file('toolbar')",
						maintoolbar => "Kephra::Config::Interface::open_file('maintoolbar')",
						searchbar => "Kephra::Config::Interface::open_file('searchbar')",
						statusbar => "Kephra::Config::Interface::open_file('statusbar')",
					},
					syntaxmode => {
						ada => "Kephra::Document::SyntaxMode::open_file('ada')",
						as => "Kephra::Document::SyntaxMode::open_file('as')",
						asm => "Kephra::Document::SyntaxMode::open_file('asm')",
						ave => "Kephra::Document::SyntaxMode::open_file('ave')",
						baan => "Kephra::Document::SyntaxMode::open_file('baan')",
						batch => "Kephra::Document::SyntaxMode::open_file('batch')",
						c => "Kephra::Document::SyntaxMode::open_file('cpp')",
						conf => "Kephra::Document::SyntaxMode::open_file('conf')",
						context => "Kephra::Document::SyntaxMode::open_file('context')",
						cs => "Kephra::Document::SyntaxMode::open_file('cs')",
						css => "Kephra::Document::SyntaxMode::open_file('css')",
						diff => "Kephra::Document::SyntaxMode::open_file('diff')",
						eiffel => "Kephra::Document::SyntaxMode::open_file('eiffel')",
						err => "Kephra::Document::SyntaxMode::open_file('err')",
						forth => "Kephra::Document::SyntaxMode::open_file('forth')",
						fortran => "Kephra::Document::SyntaxMode::open_file('fortran')",
						html => "Kephra::Document::SyntaxMode::open_file('html')",
						idl => "Kephra::Document::SyntaxMode::open_file('idl')",
						java => "Kephra::Document::SyntaxMode::open_file('java')",
						js => "Kephra::Document::SyntaxMode::open_file('js')",
						latex => "Kephra::Document::SyntaxMode::open_file('latex')",
						lisp => "Kephra::Document::SyntaxMode::open_file('lisp')",
						lua => "Kephra::Document::SyntaxMode::open_file('lua')",
						make => "Kephra::Document::SyntaxMode::open_file('make')",
						matlab => "Kephra::Document::SyntaxMode::open_file('matlab')",
						nsis => "Kephra::Document::SyntaxMode::open_file('nsis')",
						pascal => "Kephra::Document::SyntaxMode::open_file('pascal')",
						perl => "Kephra::Document::SyntaxMode::open_file('perl')",
						php => "Kephra::Document::SyntaxMode::open_file('php')",
						property => "Kephra::Document::SyntaxMode::open_file('property')",
						ps => "Kephra::Document::SyntaxMode::open_file('ps')",
						python => "Kephra::Document::SyntaxMode::open_file('python')",
						ruby => "Kephra::Document::SyntaxMode::open_file('ruby')",
						scheme => "Kephra::Document::SyntaxMode::open_file('scheme')",
						sh => "Kephra::Document::SyntaxMode::open_file('sh')",
						sql => "Kephra::Document::SyntaxMode::open_file('sql')",
						tcl => "Kephra::Document::SyntaxMode::open_file('tcl')",
						tex => "Kephra::Document::SyntaxMode::open_file('tex')",
						vb => "Kephra::Document::SyntaxMode::open_file('vb')",
						vbs => "Kephra::Document::SyntaxMode::open_file('vbs')",
						xml => "Kephra::Document::SyntaxMode::open_file('xml')",
						yaml => "Kephra::Document::SyntaxMode::open_file('yaml')",
					},
					templates => 'Kephra::Config::Global::open_templates_file()',
				},
			},
		},
		enable => {
			file => {
				'save-current' => 'Kephra::File::can_save()',
				'save-all' => 'Kephra::File::can_save_all()',
			},
			edit => {
				changes => {
					undo => 'Kephra::Edit::History::can_undo()',
					redo => 'Kephra::Edit::History::can_redo()',
					'undo-several' => 'Kephra::Edit::History::can_undo()',
					'redo-several' => 'Kephra::Edit::History::can_redo()',
					'goto-begin' => 'Kephra::Edit::History::can_undo()',
					'goto-end' => 'Kephra::Edit::History::can_redo()',
					delete => 'Kephra::Edit::History::can_undo() or Kephra::Edit::History::can_redo()',
				},
				cut => 'Kephra::Edit::can_copy()',
				copy => 'Kephra::Edit::can_copy()',
				paste => 'Kephra::Edit::can_paste()',
				replace => 'Kephra::Edit::can_copy()',
				delete => 'Kephra::Edit::can_copy()',
				'line-replace' => 'Kephra::Edit::can_paste()',
				selection => {
					move => {
						'char-left' => 'Kephra::Edit::can_copy()',
						'char-right' => 'Kephra::Edit::can_copy()',
						'line-up' => 'Kephra::Edit::can_copy()',
						'line-down' => 'Kephra::Edit::can_copy()',
						'page-up' => 'Kephra::Edit::can_copy()',
						'page-down' => 'Kephra::Edit::can_copy()',
					},
				},
			},
			find => {
				prev => 'Kephra::Edit::Search::item_findable()',
				next => 'Kephra::Edit::Search::item_findable()',
				first => 'Kephra::Edit::Search::item_findable()',
				last => 'Kephra::Edit::Search::item_findable()',
				selection => 'Kephra::Edit::can_copy()',
			},
			replace => {
				prev => 'Kephra::Edit::Search::_exist_find_item()',
				next => 'Kephra::Edit::Search::_exist_find_item()',
				all => 'Kephra::Edit::Search::_exist_find_item()',
				'with-confirm' => 'Kephra::Edit::Search::_exist_find_item()',
				selection => 'Kephra::Edit::can_copy()',
			},
			'tool-interpreter' => {
				'run-document' => '! Kephra::Plugin::Output::is_running()',
				'stop-document' => 'Kephra::Plugin::Output::is_running()',
			},
		},
		enable_event => {
			'file-save-current' => 'document.savepoint',
			'file-save-all' => 'document.savepoint',
			edit => {
				changes => {
					undo => 'document.savepoint',
					redo => 'document.savepoint,document.text.change',
				},
				cut => 'document.text.select',
				copy => 'document.text.select',
				paste => 'document.text.select',
				replace => 'document.text.select',
				delete => 'document.text.select',
			},
			find => {
				prev => 'find.item.changed',
				next => 'find.item.changed',
				first => 'find.item.changed',
				last => 'find.item.changed',
				selection => 'document.text.select',
			},
			replace => {
				prev => 'find.item.changed',
				next => 'find.item.changed',
				all => 'find.item.changed',
				'with-confirm' => 'find.item.changed',
				selection => 'document.text.select',
			},
			'tool-interpreter' => {
				'run-document' => 'plugin.output.run',
				'stop-document' => 'plugin.output.run',
			},
		},
		state => {
			search => {
				attribute => {
					'autowrap-switch' => "Kephra::Edit::Search::get_attribute('auto_wrap');",
					'incremental-switch' => "Kephra::Edit::Search::get_attribute('incremental');",
					'regex-switch' => "Kephra::Edit::Search::get_attribute('match_regex');",
					match => {
						'case-switch' => "Kephra::Edit::Search::get_attribute('match_case');",
						'whole-word-switch' => "Kephra::Edit::Search::get_attribute('match_whole_word');",
						'word-begin-switch' => "Kephra::Edit::Search::get_attribute('match_word_begin');",
					},
				},
				range => {
					selection => "Kephra::Edit::Search::get_range() eq 'selection';",
					document => "Kephra::Edit::Search::get_range() eq 'document';",
					'open-docs' => "Kephra::Edit::Search::get_range() eq 'open_docs';",
				},
			},
			bookmark => {
				goto => {
					1 => 'Kephra::Edit::Bookmark::is_set(1)',
					2 => 'Kephra::Edit::Bookmark::is_set(2)',
					3 => 'Kephra::Edit::Bookmark::is_set(3)',
					4 => 'Kephra::Edit::Bookmark::is_set(4)',
					5 => 'Kephra::Edit::Bookmark::is_set(5)',
					6 => 'Kephra::Edit::Bookmark::is_set(6)',
					7 => 'Kephra::Edit::Bookmark::is_set(7)',
					8 => 'Kephra::Edit::Bookmark::is_set(8)',
					9 => 'Kephra::Edit::Bookmark::is_set(9)',
					0 => 'Kephra::Edit::Bookmark::is_set(0)',
				},
			},
			document => {
				'auto-indention' => 'Kephra::Document::Property::get_autoindention()',
				'brace-indention' => 'Kephra::Document::Property::get_braceindention()',
				EOL => {
					'cr+lf' => "Kephra::Document::Property::get_EOL_mode() eq 'cr+lf'",
					cr => "Kephra::Document::Property::get_EOL_mode() eq 'cr'",
					lf => "Kephra::Document::Property::get_EOL_mode() eq 'lf'",
				},
				readonly => {
					'as-attr' => "Kephra::Document::Property::get_readonly() eq 'protect';",
					on => "Kephra::Document::Property::get_readonly() eq 'on';",
					off => "Kephra::Document::Property::get_readonly() eq 'off';",
				},
				syntaxmode => {
					none => "Kephra::Document::SyntaxMode::_ID() eq 'none';",
					ada => "Kephra::Document::SyntaxMode::_ID() eq 'ada';",
					as => "Kephra::Document::SyntaxMode::_ID() eq 'as';",
					asm => "Kephra::Document::SyntaxMode::_ID() eq 'asm';",
					ave => "Kephra::Document::SyntaxMode::_ID() eq 'ave';",
					baan => "Kephra::Document::SyntaxMode::_ID() eq 'baan';",
					batch => "Kephra::Document::SyntaxMode::_ID() eq 'batch';",
					c => "Kephra::Document::SyntaxMode::_ID() eq 'cpp';",
					conf => "Kephra::Document::SyntaxMode::_ID() eq 'conf';",
					context => "Kephra::Document::SyntaxMode::_ID() eq 'context';",
					cs => "Kephra::Document::SyntaxMode::_ID() eq 'cs';",
					css => "Kephra::Document::SyntaxMode::_ID() eq 'css';",
					diff => "Kephra::Document::SyntaxMode::_ID() eq 'diff';",
					eiffel => "Kephra::Document::SyntaxMode::_ID() eq 'eiffel';",
					err => "Kephra::Document::SyntaxMode::_ID() eq 'err';",
					forth => "Kephra::Document::SyntaxMode::_ID() eq 'forth';",
					fortran => "Kephra::Document::SyntaxMode::_ID() eq 'fortran';",
					html => "Kephra::Document::SyntaxMode::_ID() eq 'html';",
					idl => "Kephra::Document::SyntaxMode::_ID() eq 'idl';",
					java => "Kephra::Document::SyntaxMode::_ID() eq 'java';",
					js => "Kephra::Document::SyntaxMode::_ID() eq 'js';",
					latex => "Kephra::Document::SyntaxMode::_ID() eq 'latex';",
					lisp => "Kephra::Document::SyntaxMode::_ID() eq 'lisp';",
					lua => "Kephra::Document::SyntaxMode::_ID() eq 'lua';",
					make => "Kephra::Document::SyntaxMode::_ID() eq 'make';",
					matlab => "Kephra::Document::SyntaxMode::_ID() eq 'matlab';",
					nsis => "Kephra::Document::SyntaxMode::_ID() eq 'nsis';",
					pascal => "Kephra::Document::SyntaxMode::_ID() eq 'pascal';",
					perl => "Kephra::Document::SyntaxMode::_ID() eq 'perl';",
					php => "Kephra::Document::SyntaxMode::_ID() eq 'php';",
					property => "Kephra::Document::SyntaxMode::_ID() eq 'property';",
					ps => "Kephra::Document::SyntaxMode::_ID() eq 'ps';",
					python => "Kephra::Document::SyntaxMode::_ID() eq 'python';",
					ruby => "Kephra::Document::SyntaxMode::_ID() eq 'ruby';",
					scheme => "Kephra::Document::SyntaxMode::_ID() eq 'scheme';",
					sh => "Kephra::Document::SyntaxMode::_ID() eq 'sh';",
					sql => "Kephra::Document::SyntaxMode::_ID() eq 'sql';",
					tcl => "Kephra::Document::SyntaxMode::_ID() eq 'tcl';",
					tex => "Kephra::Document::SyntaxMode::_ID() eq 'tex';",
					vb => "Kephra::Document::SyntaxMode::_ID() eq 'vb';",
					vbs => "Kephra::Document::SyntaxMode::_ID() eq 'vbs';",
					xml => "Kephra::Document::SyntaxMode::_ID() eq 'xml';",
					yaml => "Kephra::Document::SyntaxMode::_ID() eq 'yaml';",
				},
				tabs => {
					soft => 'Kephra::Document::Property::get_tab_mode() == 0',
					hard => 'Kephra::Document::Property::get_tab_mode() == 1',
					use => 'Kephra::Document::Property::get_tab_mode()',
					width => {
						1 => 'Kephra::Document::Property::get_tab_size() == 1',
						2 => 'Kephra::Document::Property::get_tab_size() == 2',
						3 => 'Kephra::Document::Property::get_tab_size() == 3',
						4 => 'Kephra::Document::Property::get_tab_size() == 4',
						5 => 'Kephra::Document::Property::get_tab_size() == 5',
						6 => 'Kephra::Document::Property::get_tab_size() == 6',
						8 => 'Kephra::Document::Property::get_tab_size() == 8',
					},
				},
			},
			view => {
				editpanel => {
					EOL => 'Kephra::App::EditPanel::EOL_visible();',
					'brace-light' => 'Kephra::App::EditPanel::bracelight_visible()',
					'caret-line' => 'Kephra::App::EditPanel::caret_line_visible()',
					'indention-guide' => 'Kephra::App::EditPanel::indention_guide_visible()',
					'line-wrap' => 'Kephra::App::EditPanel::get_autowrap_mode()',
					'right-margin' => 'Kephra::App::EditPanel::LLI_visible()',
					whitespace => 'Kephra::App::EditPanel::whitespace_visible()',
					contextmenu => {
						custom => "Kephra::App::ContextMenu::get_editpanel() eq 'custom';",
						no => "Kephra::App::ContextMenu::get_editpanel() eq 'none';",
						default => "Kephra::App::ContextMenu::get_editpanel() eq 'default';",
					},
					margin => {
						'line-number' => 'Kephra::App::EditPanel::Margin::line_number_visible()',
						marker => 'Kephra::App::EditPanel::Margin::marker_visible()',
						'text-fold' => 'Kephra::App::EditPanel::Margin::fold_visible()',
						text => {
							0 => 'Kephra::App::EditPanel::Margin::get_text_width() == 0',
							1 => 'Kephra::App::EditPanel::Margin::get_text_width() == 1',
							2 => 'Kephra::App::EditPanel::Margin::get_text_width() == 2',
							3 => 'Kephra::App::EditPanel::Margin::get_text_width() == 3',
							4 => 'Kephra::App::EditPanel::Margin::get_text_width() == 4',
							6 => 'Kephra::App::EditPanel::Margin::get_text_width() == 6',
							8 => 'Kephra::App::EditPanel::Margin::get_text_width() == 8',
							10 => 'Kephra::App::EditPanel::Margin::get_text_width() == 10',
							12 => 'Kephra::App::EditPanel::Margin::get_text_width() == 12',
						},
					},
				},
				panel => {
					notepad => 'Kephra::Plugin::Notepad::get_visibility()',
					output => 'Kephra::Plugin::Output::get_visibility()',
				},
				statusbar => 'Kephra::App::StatusBar::get_visibility()',
				'statusbar-contexmenu' => 'Kephra::App::StatusBar::get_contextmenu_visibility()',
				'statusbar-info' => {
					date => 'Kephra::App::StatusBar::info_msg_nr() == 2',
					length => 'Kephra::App::StatusBar::info_msg_nr() == 1',
					none => 'Kephra::App::StatusBar::info_msg_nr()  == 0',
				},
				tabbar => 'Kephra::App::TabBar::get_visibility()',
				'tabbar-contexmenu' => 'Kephra::App::TabBar::get_contextmenu_visibility()',
				'toolbar-search' => 'Kephra::App::SearchBar::get_visibility()',
				'toolbar-main' => 'Kephra::App::MainToolBar::get_visibility()',
				'window-stay-on-top' => 'Kephra::App::Window::get_on_top_mode()',
			},
		},
		state_event => {
			view => {
				'editpanel-line-wrap' => 'editpanel.autowrap',
				'window-stay-on-top' => 'app.window.ontop',
			},
		},
		icon => {
			'app-exit' => 'app-exit.xpm',
			file => {
				new => 'file-new.xpm',
				open => 'file-open.xpm',
				'save-current' => 'file-save.xpm',
				'save-all' => 'file-save-all.xpm',
				print => 'file-print.xpm',
				'close-current' => 'file-close.xpm',
			},
			edit => {
				changes => {
					undo => 'edit-undo.xpm',
					redo => 'edit-redo.xpm',
				},
				cut => 'edit-cut.xpm',
				copy => 'edit-copy.xpm',
				paste => 'edit-paste.xpm',
				replace => 'edit-replace.xpm',
				delete => 'edit-delete.xpm',
			},
			find => {
				prev => 'find-previous.xpm',
				next => 'find-next.xpm',
			},
			goto => {
				'last-edit' => 'goto-last-edit.xpm',
				line => 'goto-last-edit.xpm',
			},
			view => {
				dialog => {
					config => 'config-preferences.xpm',
					find => 'find-start.xpm',
					info => 'help-info.xpm',
					keymap => 'help-keyboard.xpm',
					replace => 'find-start.xpm',
				},
				'editpanel-line-wrap' => 'line-wrap.xpm',
				'panel-notepad' => 'note.xpm',
				'panel-output' => 'console.xpm',
				'toolbar-search' => 'edit-delete.xpm',
				'window-stay-on-top' => 'stay-on-top.xpm',
			},
			#has_ending' => '1
			#path' => 'interface/icon/set/jenne/
			#type' => 'xpm
			#use_path' => '1
			#use_file_type' => '1
		},
		key => {
			'app-exit' => 'alt+q',
			file => {
				new => 'ctrl+n',
				open => 'ctrl+o',
				reload => 'ctrl+shift+o',
				'reload-all' => 'ctrl+alt+o',
				insert => 'ctrl+shift+i',
				'save-current' => 'ctrl+s',
				'save-all' => 'ctrl+alt+s',
				'save-as' => 'ctrl+shift+s',
				'save-copy-as' => 'alt+shift+s',
				rename => 'ctrl+alt+shift+s',
				print => 'ctrl+p',
				close => {
					current => 'ctrl+q',
					other => 'ctrl+shift+q',
				},
			},
			edit => {
				changes => {
					undo => 'ctrl+z',
					redo => 'ctrl+shift+z',
					'undo-several' => 'alt+z',
					'redo-several' => 'alt+shift+z',
					'goto-begin' => 'ctrl+alt+z',
					'goto-end' => 'ctrl+alt+shift+z',
				},
				cut => 'ctrl+x',
				copy => 'ctrl+c',
				paste => 'ctrl+v',
				replace => 'ctrl+w',
				delete => 'del',
				'delete-tab' => 'shift+back',
				line => {
					cut => 'ctrl+shift+x',
					copy => 'ctrl+shift+c',
					duplicate => 'ctrl+shift+d',
					replace => 'ctrl+shift+w',
					delete => 'ctrl+shift+del',
					'delete-left' => 'ctrl+shift+l',
					'delete-right' => 'ctrl+shift+r',
					move => {
						'line-up' => 'ctrl+alt+up',
						'line-down' => 'ctrl+alt+down',
						'page-up' => 'ctrl+alt+pgup',
						'page-down' => 'ctrl+alt+pgdn',
					},
				},
				selection => {
					comment => {
						'add-perl' => 'ctrl+k',
						'del-perl' => 'ctrl+shift+k',
						'add-xml' => 'ctrl+h',
						'del-xml' => 'ctrl+shift+h',
					},
					format => {
						'block-on-right-margin' => 'ctrl+shift+b',
						'dedent-char' => 'ctrl+shift+space',
						'dedent-tab' => 'ctrl+shift+tab',
						'indent-char' => 'ctrl+space',
						'indent-tab' => 'ctrl+tab',
						'join-lines' => 'ctrl+shift+j',
					},
					move => {
						'char-left' => 'ctrl+alt+left',
						'char-right' => 'ctrl+alt+right',
						'line-up' => 'ctrl+alt+up',
						'line-down' => 'ctrl+alt+down',
						'page-up' => 'ctrl+alt+pgup',
						'page-down' => 'ctrl+alt+pgdn',
					},
				},
			},
			select => {
				document => 'ctrl+a',
				'to-block-begin' => 'alt+shift+pgup',
				'to-block-end' => 'alt+shift+pgdn',
			},
			find => {
				prev => 'shift+f3',
				next => 'f3',
				first => 'ctrl+alt+f3',
				last => 'ctrl+alt+shift+f3',
				selection => 'ctrl+f3',
			},
			replace => {
				prev => 'alt+shift+f3',
				next => 'alt+f3',
				all => 'ctrl+alt+r',
				'with-confirm' => 'ctrl+alt+shift+r',
				selection => 'ctrl+shift+f3',
			},
			goto => {
				block => {
					down => 'alt+pgdn',
					up => 'alt+pgup',
				},
				brace => {
					down => 'alt+down',
					left => 'alt+left',
					right => 'alt+right',
					up => 'alt+up',
				},
				'last-edit' => 'ctrl+shift+g',
				line => 'ctrl+g',
			},
			bookmark => {
				goto => {
					1 => 'ctrl+1',
					2 => 'ctrl+2',
					3 => 'ctrl+3',
					4 => 'ctrl+4',
					5 => 'ctrl+5',
					6 => 'ctrl+6',
					7 => 'ctrl+7',
					8 => 'ctrl+8',
					9 => 'ctrl+9',
					0 => 'ctrl+0',
				},
				toggle => {
					1 => 'ctrl+shift+1',
					2 => 'ctrl+shift+2',
					3 => 'ctrl+shift+3',
					4 => 'ctrl+shift+4',
					5 => 'ctrl+shift+5',
					6 => 'ctrl+shift+6',
					7 => 'ctrl+shift+7',
					8 => 'ctrl+shift+8',
					9 => 'ctrl+shift+9',
					0 => 'ctrl+shift+0',
				},
			},
			tool => {
				note => 'f4',
				note-selection => 'shift+f4',
				'interpreter-run-document' => 'f5',
				'interpreter-stop-document' => 'shift+f5',
			},
			document => {
				change => {
					back => 'ctrl+shift+back',
					prev => 'ctrl+pgup',
					next => 'ctrl+pgdn',
				},
				move => {
					left => 'ctrl+shift+pgup',
					right => 'ctrl+shift+pgdn',
				},
			},
			view => {
				toolbar => {
					'search-goto' => 'ctrl+f',
				},
				dialog => {
					config => 'alt+shift+c',
					find => 'ctrl+shift+f',
					replace => 'ctrl+r',
					info => 'alt+shift+i',
					keymap => 'alt+shift+k',
				},
				'editpanel-fold-toggle' => {
					all => 'alt+shift+plus',
					here => 'alt+minus',
					recursively => 'alt+shift+minus',
					siblings => 'alt+plus',
				},
				'panel-notepad' => 'ctrl+f4',
				'panel-output' => 'ctrl+f5',
				'window-stay-on-top' => 'ctrl+t',
			},
		},
	},
}

1;
