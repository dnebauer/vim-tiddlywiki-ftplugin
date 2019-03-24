" Control statements    {{{1
set encoding=utf-8
scriptencoding utf-8

if exists('b:disable_tiddlywiki') && b:disable_tiddlywiki | finish | endif
if exists('b:loaded_tiddlywiki_mappings') | finish | endif
let b:loaded_tiddlywiki_mappings = 1
if exists('g:no_plugin_maps') && g:no_plugin_maps | finish | endif
if exists('g:no_tiddlywiki_maps') && g:no_tiddlywiki_maps | finish | endif

""
" @setting g:no_tiddlywiki_maps
" Prevents loading of plugin mappings if set to a true value. (See also
" discussion of "g:no_plugin_maps" in @section(mappings).)

let s:save_cpo = &cpoptions
set cpoptions&vim

" Documentation    {{{1
" - vimdoc does not automatically generate mappings section

""
" @section Mappings, mappings
" The following mappings are provided for |Normal-mode|:
"
" <Leader>ti
"   * initialise tiddler file
"   * calls @function(tiddlywiki#initialiseTiddler)
"
" <Leader>tm
"   * update modification timestamp
"   * calls @function(tiddlywiki#updateModTime)
"
" @plugin(name) adheres to the convention that plugin mappings are not loaded
" if either of the variables "g:no_plugin_maps" or
" @setting(g:no_tiddlywiki_maps) is set to a true value.

" }}}1

" Mappings

" \ti - initialise tiddler file    {{{1

""
" Calls @function(tiddlywiki#initialiseTiddler) from |Normal-mode| to insert
" standard metatdata fields at the head of the file.
if !hasmapto('<Plug>TWTTN')
    nmap <buffer> <unique> <LocalLeader>ti <Plug>TWTTN
endif
nmap <buffer> <unique> <Plug>TWTTN :call tiddlywiki#initialiseTiddler()<CR>

" \tm - update modification timestamp    {{{1

""
" Calls @function(tiddlywiki#updateModTime) from |Normal-mode| to update the
" timestamp in the metadata "modified" field.
if !hasmapto('<Plug>TWTMN')
    nmap <buffer> <unique> <LocalLeader>tm <Plug>TWTMN
endif
nmap <buffer> <unique> <Plug>TWTMN :call tiddlywiki#updateModTime()<CR>
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :

