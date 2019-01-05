" Control statements    {{{1
set encoding=utf-8
scriptencoding utf-8

if exists('b:disable_tiddlywiki') && b:disable_tiddlywiki | finish | endif
if exists('b:loaded_tiddlywiki_autocmds') | finish | endif
let b:loaded_tiddlywiki_autocmds = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

" Documentation    {{{1
" - vimdoc does not automatically generate autocmds section

""
" @section Autocommands, autocmds
" This plugin is configured to automatically update the tiddler's modification
" time (in the metadata "modified" field) when the file is changed and saved.
" This feature can be disabled by users with the |g:tiddlywiki_autoupdate|
" variable.
"
" The autocmd responsible for this behaviour can be found in the
" "tiddlywiki" autocmd group (see |autocmd-groups|) and can be viewed (see
" |autocmd-list|).

" }}}1

" Autocommands

" Autoupdate modification time when a changed file is saved    {{{1

""
" @setting g:tiddlywiki_autoupdate
" If present and set to a true value, this enable automatic updating of the
" tiddler's modification time. For more information see
" @function(tiddlywiki#updateModTime) and @section(autocmds).

function! s:autoupdate_mod_time()
    if &modified
        call tiddlywiki#updateModTime()
    endif
endfunction

if exists('g:tiddlywiki_autoupdate') && g:tiddlywiki_autoupdate
    augroup tiddlywiki
        au BufWrite, *.tid call <SID>autoupdate_mod_time()
    augroup END
endif
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :

