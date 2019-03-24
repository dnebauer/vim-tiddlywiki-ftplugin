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

" TWConvertTidToDivTiddler - convert tid style file to tiddler    {{{1

" s:completeTiddlerField(arg, line, pos)    {{{2

""
" @private
" Custom command completion for tiddler field names, accepting the required
" arguments of {arg}, {line}, and {pos} although they are not used (see
" |:command-completion-customlist|). Returns a |List| of system field names:
" * title
" * tags
" * creator
" * created
" * modifier
" * modified
function! s:completeTiddlerField(arg, line, pos)
    let l:args = ['title', 'tags', 'creator', 'created',
                \ 'modifier', 'modified']
    return filter(l:args, {idx, val -> val =~ a:arg})
endfunction
" }}}2

""
" Calls @function(tiddlywiki#convertTidToDivTiddler) to convert a "tid" style
" file to a "tiddler" style file and then open it. Accepts optional metadata
" [field] names as arguments.
command -buffer -nargs=* -complete=customlist,s:completeTiddlerField
            \ TWConvertTidToDivTiddler
            \ call tiddlywiki#convertTidToDivTiddler(<f-args>)

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
