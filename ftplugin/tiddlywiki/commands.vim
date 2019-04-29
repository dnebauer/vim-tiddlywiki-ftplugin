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

" TWAddCanonicalUri        - add canonical uri metadata field     {{{1

""
" Calls @function(tiddlywiki#addCanonicalUri) to select an external image and
" add a corresponding "_canonical_uri" metadata field to the top of the
" tiddler (or replace an existing one). The wiki [root] directory is provided
" as an absolute path while the [images] subdirectory is relative to the wiki
" root directory, under which it must be located. The user is able to manually
" select either or both directory manually if not specified in the command
" call.
"
" When specifying the directories on the command line the easiest method is to
" use directory completion to enter the absolute images directory path, and then add
" spacing just after the wiki root directory. In that way the first argument
" becomes the wiki root directory and the second argument becomes the images
" directory path relative to the wiki root directory. Take particular care
" when the directory paths themselves contain spaces. 
command -buffer -nargs=* -complete=dir TWAddCanonicalUri
            \ call tiddlywiki#addCanonicalUri(<f-args>)

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

" TWUniquifyDataTiddler    - add unique numeric prefixes    {{{1

""
" Calls @function(tiddlywiki#uniquefyDataTiddler) to add a unique numeric
" prefix to each line (row) of a dictionary data tiddler. Each line gets the
" prefix "X: " where "X" is an incrementing integer starting at 1 on the first
" line.
command -buffer TWUniquifyDataTiddler call tiddlywiki#uniquefyDataTiddler()

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
