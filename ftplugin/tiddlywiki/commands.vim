" Control statements    {{{1
set encoding=utf-8
scriptencoding utf-8

if exists('b:disable_tiddlywiki') && b:disable_tiddlywiki | finish | endif
if exists('b:loaded_tiddlywiki_commands') | finish | endif
let b:loaded_tiddlywiki_commands = 1

let s:save_cpo = &cpoptions
set cpoptions&vim
" }}}1

" Commands

" TWInitialiseTiddler      - insert tiddler metadata fields    {{{1

""
" Calls @function(tiddlywiki#initialiseTiddler) to insert metadata fields
" "created", "modified", "tags", "title" and "type" at the head of the file.
command -buffer TWInitialiseTiddler call tiddlywiki#initialiseTiddler()

" TWUpdateModificationTime - update modification timestamp    {{{1

""
" Calls @function(tiddlywiki#updateModTime) to update the timestamp in the
" "modified" metadata field.
command -buffer TWUpdateModificationTime call tiddlywiki#updateModTime()
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
