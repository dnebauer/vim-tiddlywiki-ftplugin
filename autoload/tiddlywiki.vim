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
" @section(syntax) highlighting, some useful @section(functions),
" @section(mappings), @section(commands) and an optional @section(autocmds)
" assist with tiddler metadata.

""
" @setting b:disable_tiddlywiki
" Prevents @plugin(name) loading if set to a true value before it would
" normally load.

""
" @setting g:default_tiddler_tags
" Default tag names to be added when converting a "tid" file to a "tiddler"
" file. Tag names specified in tiddler metadata are added to these tag names.
" For more details see the @command(TWTidToTiddler) command and
" @function(tiddlywiki#convertTidToDivTiddler) function.

""
" @setting g:default_tiddler_creator
" Default creator name to be added when converting a "tid" file to a "tiddler"
" file. Any creator name specified in tiddler metadata overrides the tag name
" set in this variable. For more details see the @command(TWTidToTiddler)
" command and @function(tiddlywiki#convertTidToDivTiddler) function.

" }}}1

" Script functions

" s:confirm(question)    {{{1

""
" @private
" Asks user a {question} to be answered with a 'y' or 'n'.
function! s:confirm(question) abort
    echohl Question
    echomsg a:question
    echohl None
    let l:char = nr2char(getchar())
    echon l:char
    return (l:char ==? 'y')
endfunction

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
" @private
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

" tiddlywiki#convertTidToDivTiddler([field1[, field2[, ...]]])    {{{1

""
" @public
" Converts the contents of the current buffer, assumed to be in the syle of a
" "tid" file, to the style of a "tiddler" file, writes the "tiddler" file to
" the current directory and opens it in a new buffer. The "tid" and "tiddler"
" file styles are described in the "TiddlerFiles" tiddler at
" https://tiddlywiki.com.)
"
" If the current buffer is associated with a file the output "tiddler" is
" given the same base name. If the current buffer is not associated with a
" file the user is prompted to enter one. The output file is given a "tiddler"
" extension.
"
" The "tid" content is assumed to be structured with at least one metadata
" line at the top of the document separated from the tiddler content/text by a
" blank line. Each metadata lines looks like "field: description". The
" content of the tags field is space-separated tag names; tag names containing
" spaces should be enclosed by doubled square brackets, e.g., "[[tag name]]".
" Default tag names set using the @setting(g:default_tiddler_tags) setting are added
" to any tag names defined in tiddler metadata. A default creator name can be
" set using @setting(g:default_tiddler_creator), but this is overridden by a
" creator set in tiddler metadata. If, for some reason, there the same field
" is defined multiple times in metadata, the following occurs:
" * for the "tags" field, all field valules are concatenated
" * for other fields, the last field value overrides all others.
"
" There is an optional pre-processing step in which lines at the top of the
" file can have field names prepended to them. This is triggered by passing
" [field] names to the function as arguments. Consider, for example, the
" function invocation:>
" "call tiddlywiki#convertTidToDivTiddler('title', 'tags')"
" <This results in "title: " being prepended to the first line in the file and
" "tags: " being prepended to the second line in the file. If a blank line
" occurs before the field name arguments are exhausted, remaining field names
" are ignored.
" @throws CantEdit if unable to open tiddler file for editing
" @throws DeleteFail if error occurs during file deletion
" @throws NoBoundary if no metadata/content boundary located
" @throws NoContent if no content/text in tiddler
" @throws NoFilename if no output filename entered by user
" @throws WriteFail if error occurs during file write
function! tiddlywiki#convertTidToDivTiddler(...)
    " define error messages    {{{2
    let l:ERROR_DeleteFail
                \ = 'ERROR(DeleteFail): Vim reports file deletion failed'
    let l:ERROR_NoBoundary
                \ = 'ERROR(NoBoundary): No metadata/content boundary located'
    let l:ERROR_NoContent = 'ERROR(NoContent): No content/text in tiddler'
    let l:ERROR_NoFilename = 'ERROR(NoFilename): No output filename provided'
    let l:ERROR_WriteFail = 'ERROR(WriteFail): Vim reports file write failed'
    " slurp buffer content into list    {{{2
    let l:tid = getline(1, '$')
    " add field names to metadata (optional)    {{{2
    let l:tid_index = 0
    for l:field in a:000
        let l:line = get(l:tid, l:tid_index, '')
        if empty(l:line) | break | endif |  " ran out of tiddler lines
        let l:line = l:field . ': ' . l:line
        let l:tid[l:tid_index] = l:line
        let l:tid_index += 1
    endfor
    " prepare to process tiddler    {{{2
    " - remove leading empty rows
    let l:leading_blanks = -1
    for l:line in l:tid
        if   l:line =~# '^\s*$' | let l:leading_blanks +=1
        else                    | break
        endif
    endfor
    if l:leading_blanks >=0
        call remove(l:tid, 0, l:leading_blanks)
    endif
    " - locate boundary line between metadata and content/text
    let l:boundary_index = 0
    for l:line in l:tid
        if l:line =~# '^\s*$' | break | endif
        let l:boundary_index += 1
    endfor
    if l:boundary_index >= len(l:tid) | throw l:ERROR_NoBoundary | endif
    let l:metadata_end = l:boundary_index - 1
    let l:content_begin = l:boundary_index + 1
    " - prepare variables
    let l:tiddler = []
    let l:fields = {}
    if exists('g:default_tiddler_tags') && !empty(g:default_tiddler_tags)
        let l:fields['tags'] = g:default_tiddler_tags
    endif
    if exists('g:default_tiddler_creator') && !empty(g:default_tiddler_creator)
        let l:fields['creator'] = g:default_tiddler_creator
    endif
    " process tiddler metadata    {{{2
    for l:line in l:tid[0 : l:metadata_end]
        let l:field_name = split(l:line, ':')[0]
        let l:match_expr = l:field_name . ':\s*'
        let l:value_start = matchend(l:line, l:match_expr)
        let l:field_value = strpart(l:line, l:value_start)
        " the 'tags' field is handled as a special case
        if l:field_name =~# '^tags$'
            let l:tags = l:fields['tags'] . ' ' . l:field_value
            let l:fields['tags'] = l:tags
        else
            let l:fields[l:field_name] = l:field_value
        endif
    endfor
    let l:attributes = ''
    for [l:field_name, l:field_value] in items(l:fields)
        let l:attributes .= ' ' . l:field_name . '="' . l:field_value . '"'
    endfor
    let l:div = '<div' . l:attributes . '>'
    call add(l:tiddler, l:div)
    " process tiddler content/text    {{{2
    let l:content = l:tid[l:content_begin :]
    if len(l:content) == 0 | throw l:ERROR_NoContent | endif
    let l:content[0] = '<pre>' . l:content[0]
    let l:content[-1] = l:content[-1] . '</pre>'
    call extend(l:tiddler, l:content)
    call add(l:tiddler, '</div>')
    " get output filename    {{{2
    if empty(bufname('%'))  " no file associated with buffer
        echohl Question
        let l:tiddler_fname
                    \ = input('Enter output file base name: ', '', 'file')
        echohl None
        if empty(l:tiddler_fname) | throw l:ERROR_NoFilename | endif
        if fnamemodify(l:tiddler_fname, ':e') !~# '^tiddler$'
            let l:tiddler_fname .= '.tiddler'
        endif
    else  " file associated with buffer
        let l:bufname = bufname('%')
        if fnamemodify(l:bufname, ':e') =~# '^tid$'
            let l:tiddler_base = fnamemodify(l:bufname, ':r')
        else
            let l:tiddler_base = l:bufname
        endif
        let l:tiddler_fname = l:tiddler_base . '.tiddler'
    endif
    " handle if output file already exists    {{{2
    if !empty(glob(l:tiddler_fname))
        call s:warn('Output file "' . l:tiddler_fname . '" already exists')
        if s:confirm('Overwrite it? [y/N] ')
            try   | let l:delete = delete(l:tiddler_fname)
            catch | throw 'ERROR(DeleteFail): '
                        \ . s:exception_error(v:exception)
            endtry
            if l:delete == -1 | throw l:ERROR_DeleteFail | endif
        else
            echo 'Aborting'
            return
        endif
    endif
    " write output file    {{{2
    try   | let l:write = writefile(l:tiddler, l:tiddler_fname, 's')
    catch | throw 'ERROR(WriteFail): ' . s:exception_error(v:exception)
    endtry
    if l:write == -1 | throw l:ERROR_WriteFail | endif
    " open output file in new buffer    {{{2
    " - update to prevent unsaved changes interfering with edit command
    update
    try   | execute 'edit!' l:tiddler_fname
    catch | throw 'ERROR(CantEdit): ' . s:exception_error(v:exception)
    endtry    " }}}2
endfunction
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
