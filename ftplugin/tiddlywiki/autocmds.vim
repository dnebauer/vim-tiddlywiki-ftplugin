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
" @plugin(name) can be configured to automatically update the tiddler's
" modification time (in the metadata "modified" field) when the file is
" changed and saved. While disabled by default, it can be enabled with the
" |g:tiddlywiki_autoupdate| variable.
"
" The autocmd responsible for this behaviour can be found in the
" "tiddlywiki" autocmd group (see |autocmd-groups|) and can be viewed (see
" |autocmd-list|).

" }}}1

" Autocommands

" Autoupdate modification time when a changed file is saved    {{{1

""
" @setting g:tiddlywiki_autoupdate
" If this variable is present and set to a true value, automatic updating of
" the tiddler's modification time is enabled. For more information see the
" @function(tiddlywiki#updateModTime) function and @section(autocmds) section.

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

