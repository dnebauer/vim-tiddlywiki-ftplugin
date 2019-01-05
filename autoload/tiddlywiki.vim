" Vim ftplugin for tiddlywiki tiddlers
" Last change: 2019 Jan 5
" Maintainer: David Nebauer
" License: http://www.apache.org/licenses/LICENSE-2.0.txt

" Control statements    {{{1
set encoding=utf-8
scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" Documentation {{{1

""
" @section Introduction, intro
" @order features syntax mappings autocmds
" @stylized tiddlywiki-filetype-plugin
" A filetype plugin for Tiddlywiki tiddlers.
"
" TiddlyWiki (https://tiddlywiki.com) is a non-linear notebook, or wiki. The
" basis of TiddlyWiki is capturing information into the smallest possible
" semantically meaningful units, called "tiddlers", and aggregating them in
" meaningful ways to present narrative stories.
"
" From version 5 of TiddlyWiki each tiddler is stored in its own file, which
" has a "tid" extension. While there are a variety of types of tiddler serving
" different functions, this plugin supports the basic content type of tiddler,
" consisting of metadata followed by content. The metadata is a series of
" key:value pairs, one to a line. The content is a flavour of wikitext markup
" developed for TiddlyWiki (https://tiddlywiki.com/#WikiText).

""
" @section Features, features
" @plugin(name) defines the "tiddlywiki" filetype and provides
" @section(syntax) highlighting, some useful @section(functions) and
" @section(mappings), and an optional @section(autocmds) assist with tiddler
" metadata.

""
" @setting b:disable_tiddlywiki
" Prevents @plugin(name) loading if set to a true value before it would
" normally load.

" }}}1

" Script functions

" s:stringify(variable[, quote])    {{{1

""
" @private
" Convert {variable} to |String| and return the converted string. If [quote]
" is true strings in {variable} will be enclosed in single quotes in the
" output, with internal single quotes doubled. For |Dictionaries| perl-like
" "big-arrow" (" => ") notation is used between keys and values. Consider
" using |string()| instead of this function.
" @default quote=false
" @throws BadVarType if variable type is invalid
function! s:stringify(variable, ...) abort
    " l:Var and l:Item are capitalised because they can be funcrefs
    " and local funcref variables must start with a capital letter
    let l:Var = deepcopy(a:variable)
    " are we quoting string output?
    let l:quoting_strings = (a:0 && a:1)
    " string
    if     type(a:variable) == type('')
        let l:Var = strtrans(l:Var)  " ensure all chars printable
        if l:quoting_strings
            " double all single quotes
            let l:Var = substitute(l:Var, "'", "''", 'g')
            " enclose in single quotes
            let l:Var = "'" . l:Var . "'"
        endif
        return l:Var
    " integer
    elseif type(a:variable) == type(0)
        return printf('%d', a:variable)
    " float
    elseif type(a:variable) == type(0.0)
        return printf('%g', a:variable)
    " List
    elseif type(a:variable) == type([])
        let l:out = []
        for l:Item in l:Var
            call add(l:out, s:stringify(l:Item, v:true))
            unlet l:Item
        endfor
        return '[ ' . join(l:out, ', ') . ' ]'
    " Dictionary
    " - use perl-style 'big arrow' notation
    elseif type(a:variable) == type({})
        let l:out = []
        for l:key in sort(keys(l:Var))
            let l:val = s:stringify(l:Var[l:key], v:true)
            call add(l:out, "'" . l:key . "' => " . l:val)
        endfor
        return '{ ' . join(l:out, ', ') . ' }'
    " Funcref
    elseif type(a:variable) == type(function('tr'))
        return string(l:Var)
    " Boolean
    elseif type(a:variable) == type(v:true)
        return string(l:Var)
    " Null
    elseif a:variable is v:null
        return string(l:Var)
    " have now covered all seven variable types
    else
        call s:warn('invalid variable type')
        throw 'ERROR(BadVarType) Invalid variable type'
    endif
endfunction

" s:exception_error(exception)    {{{1

""
" @private
" Extracts and returns the error message from a Vim exception. Any other
" exception is returned unaltered.
"
" This is useful because vim will not allow Vim errors to be re-thrown. If all
" errors are processed by this function before re-throwing them, there is no
" chance of the re-throw causing this failure.
"
" It also makes the errors a little more easy to read since the Vim context is
" removed. (This context provides little troubleshooting assistance in simple
" scripts.) For that reason this function may usefully be used in processing
" all exceptions before operating on them.
function! s:exception_error(exception) abort
    let l:matches = matchlist(a:exception, '^Vim\%((\a\+)\)\=:\(E\d\+\p\+$\)')
    return (!empty(l:matches) && !empty(l:matches[1])) ? l:matches[1]
                \                                      : a:exception
endfunction

" s:listifyMsg(var)    {{{1

""
" @private
" Convert variable {var} into a |List|. If a List is provided then all list
" items are converted to strings. If a non-List variable is provided it is
" converted to a string and then made into a single-item List. All string
" conversion is done by @function(s:stringify).
function! s:listifyMsg(var) abort
    let l:items = []
    if type(a:var) == type([])
        for l:var in a:var
            call add(l:items, s:stringify(l:var))
        endfor
    else
        call add(l:items, s:stringify(a:var))
    endif
    return l:items
endfunction

" s:error(message)    {{{1

""
" @private
" Display error {message}. A |String| {message} is converted to a
" single-element |List|. Any other type of non-|List| value is stringified by
" @function(s:stringify) and converted to a single-element |List|. If a |List|
" is provided, all elements of the |List| are stringified by
" @function(s:stringify). Once a final |List| has been generated, all elements
" are displayed sequentially using |echomsg|, to ensure they are saved in the
" |message-history|, using error highlighting (see |hl-ErrorMsg|).
function! s:error(message) abort
    " require double quoting of execution string so backslash
    " is interpreted as an escape token
    if mode() ==# 'i' | execute "normal! \<Esc>" | endif
    echohl ErrorMsg
    for l:message in s:listifyMsg(a:message) | echomsg l:message | endfor
    echohl Normal
endfunction

" s:warn(msg)    {{{1

""
" @public
" Display warning {message}. A |String| {message} is converted to a
" single-element |List|. Any other type of non-|List| value is stringified by
" @function(s:stringify) and converted to a single-element |List|. If a |List|
" is provided, all elements of the |List| are stringified by
" @function(s:stringify). Once a final |List| has been generated, all elements
" are displayed sequentially using |echomsg|, to ensure they are saved in the
" |message-history|, using error highlighting (see |hl-ErrorMsg|).
function! s:warn(msg) abort
    if mode() ==# 'i' | execute "normal! \<Esc>" | endif
    echohl WarningMsg
    for l:msg in s:listifyMsg(a:msg) | echomsg l:msg | endfor
    echohl Normal
endfunction

" s:tw_time()    {{{1

""
" @private
" Provides current time in the format required by TiddlyWiki's "modified" and
" "created" metadata fields. This format consists of the following numeric values
" joined together into a single string without any intervening characters,
" whitespace or punctuation:
" * year - four digits
" * month - two digits
" * day - two digits
" * hours - 24-hour notation, two digits
" * minutes - two digits
" * seconds - two digits
" * milliseconds - three digits
"
" In fact, the time provided by this function is rounded to the nearest
" second, i.e., the milliseconds are always "000".
"
" It is assumed the standard posix-compliant unix utility "date", or an
" equivalent, is available.
"
" Returns an integer string of 17 digits.
"
" @throws NoDate if unable to obtain system date
" @throws BadDate if system datetime is invalid
function! s:tw_time()
    let l:cmd = "date -u +'%Y%m%d%H%M%S'"
    let l:datetime = systemlist(l:cmd)
    " checks on returned date
    if v:shell_error
        " l:datetime now contains shell error feedback
        let l:err = ['Unable to obtain system date']
        if !empty(l:datetime)
            call map(l:datetime, '"  " . v:val')
            call extend(l:err, ['Error message:'] + l:datetime)
        endif
        call s:warn(l:err)
        throw 'ERROR(NoDate) Unable to obtain system date'
    endif
    let l:tw_time = l:datetime[0]
    let l:dt_regex = '^\d\{14}$'
    if l:tw_time !~ l:dt_regex
        call s:warn("Invalid date string '" . l:tw_time . "'")
        throw 'ERROR(BadDate) System datetime is invalid'
    endif
    " add on arbitrary millisecond value
    let l:tw_time .= '000'
    return l:tw_time
endfunction
" }}}1

" Public functions

" tiddlywiki#updateModTime()    {{{1

""
" @public
" Updates the "modified" metadata field with the current time.
" @throws NoModified if unable to locate "modified" metadata field
" @throws CantModify if unable to modify "modified" metadata field
" @throws CantSetPos if unable to restore original cursor position
" @throws NoDate if unable to obtain system date
function! tiddlywiki#updateModTime()
    " remember where we parked...
    let l:save_cursor = getcurpos()
    " move to 'modified' metadata field
    let l:line = search('^\s*modified:\s', 'w')
    if l:line == 0
        call s:warn('Cannot locate "modified" metadata field')
        throw 'ERROR(NoModified) Unable to locate "modified" metadata field'
    endif
    " replace line
    try
        let l:tw_time = s:tw_time()
    catch
        call s:error(s:exception_error(v:exception))
        throw 'ERROR(NoDate) Unable to obtain system date'
    endtry
    let l:new_mod = 'modified: ' . s:tw_time()
    let l:retval = setline(l:line, l:new_mod)
    if l:retval == 1
        call s:warn('Unable to modify "modified" metadata field')
        throw 'ERROR(CantModify) Unable to modify "modified" metadata field'
    endif
    " return to original location
    let l:retval = setpos('.', l:save_cursor)
    if l:retval == -1
        call s:warn('Unable to restore original cursor position')
        throw 'ERROR(CantSetPos) Unable to restore original cursor position'
    endif
endfunction

" tiddlywiki#initialiseTiddler()    {{{1

""
" @public
" Insert metadata fields at start of file. More specifically, the following
" metadata fields are inserted:
" * "created: <TIME>"
" * "modified: <TIME>"
" * "tags: "
" * "title: "
" * "type: text/vnd.tiddlywiki"
" followed by an empty line. "<TIME>" is the current time in tiddlywiki
" format.
function! tiddlywiki#initialiseTiddler()
    let l:tw_time = s:tw_time()
    call append(0, 'created: ' . l:tw_time)
    call append(1, 'modified: ' . l:tw_time)
    call append(2, 'tags: ')
    call append(3, 'title: ')
    call append(4, 'type: text/vnd.tiddlywiki')
    call append(5, '')
endfunction
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
