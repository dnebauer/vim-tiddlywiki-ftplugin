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

" s:completeTiddlerField(arg, line, pos)    {{{1

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
    " find any args already in cmdline
    let l:cmdline_parts = split(a:line)
    let l:args_for_removal = []
    for l:part in l:cmdline_parts
        if count(l:args, l:part)
            call add(l:args_for_removal, l:part)
        endif
    endfor
    " remove those args from possible return list
    for l:arg in l:args_for_removal
        let l:arg_index = index(l:args, l:arg)
        call remove(l:args, l:arg_index)
    endfor
    " return possible matches among remaining args
    return filter(l:args, {idx, val -> val =~ a:arg})
endfunction
" }}}1

" TWConvertTidToDivTiddler - convert tid-style file to tiddler    {{{1

""
" Calls @function(tiddlywiki#convertTidToDivTiddler) to convert a "tid" style
" file to a "div.tiddler" style file and then open it. Accepts optional
" metadata [field] names as arguments.
command -buffer -nargs=* -complete=customlist,s:completeTiddlerField
            \ TWConvertTidToDivTiddler
            \ call tiddlywiki#convertTidToDivTiddler(<f-args>)

" TWInitialiseTiddler      - insert tiddler metadata fields    {{{1

""
" Calls @function(tiddlywiki#initialiseTiddler) to insert metadata fields
" "created", "modified", "tags", "title" and "type" at the head of the file.
command -buffer TWInitialiseTiddler call tiddlywiki#initialiseTiddler()

" TWTiddlify               - convert to tid-style file    {{{1

""
" Calls @function(tiddlywiki#tiddlify) to convert a file to a "tid" tiddler
" file. Accepts optional metadata [field] names as arguments.
command -buffer -nargs=* -complete=customlist,s:completeTiddlerField
            \ TWTiddlify call tiddlywiki#tiddlify(<f-args>)

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
