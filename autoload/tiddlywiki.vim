" Vim ftplugin for tiddlywiki tiddlers
" Last change: 2019 Mar 24
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
" @section(mappings), @section(commands) and optional @section(autocmds)
" assist with tiddler metadata.

""
" @setting b:disable_tiddlywiki
" Prevents @plugin(name) loading if set to a true value before it would
" normally load.

""
" @setting g:default_tiddler_tags
" Default tag names to be added when converting a "tid" file to a
" "div.tiddler" file. Tag names specified in tiddler metadata are added to
" these tag names.  For more details see the @command(TWTidToTiddler) command
" and @function(tiddlywiki#convertTidToDivTiddler) function.

""
" @setting g:default_tiddler_creator
" Default creator name to be added when converting a "tid" file to a
" "div.tiddler" file. Any creator name specified in tiddler metadata overrides
" the tag name set in this variable. For more details see the
" @command(TWTidToTiddler) command and
" @function(tiddlywiki#convertTidToDivTiddler) function.

" }}}1

" Script functions

" s:canonicalise(path)    {{{1

""
" @private
" Canonicalise a file or directory {path}. A directory is given a terminal
" slash.
function! s:canonicalise(path) abort
    if empty(a:path) | return '' | endif
    let l:path = simplify(resolve(fnamemodify(a:path, ':p')))
    if isdirectory(l:path) | let l:path .= '/' | endif
    return l:path
endfunction

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

" s:select_dir(initial, prompt)    {{{1

""
" @private
" User selects a directory or, more accurately, a directory path. An {initial}
" directory in which to browse can be provided, as can a user {prompt}.
" @default prompt=Select directory
" @throws BadDir if user selects an invalid directory
" @throws NoDir if user did not select a directory
function! s:select_dir(initial, prompt)
    " set values
    let l:initial = ''
    if !empty(a:initial) && isdirectory(a:initial)
        let l:initial = s:canonicalise(a:initial)
    endif
    let l:prompt = empty(a:prompt) ? 'Select directory' : a:prompt
    let l:ERROR_NoDir = 'ERROR(NoDir): No directory selected'
    let l:ERROR_BadDir = 'ERROR(BadDir): Selected directory is invalid'
    " user selects directory
    if has('prompt')  " gui available
        let l:dir = browsedir(l:prompt, l:initial)
    else  " terminal
        let l:prompt .= ': '
        let l:dir = input(l:prompt, l:initial, 'dir')
    endif
    echo ' '
    " feedback
    if empty(l:dir) | throw l:ERROR_NoDir | endif
    if !isdirectory(l:dir) | throw l:ERROR_BadDir | endif
    return s:canonicalise(l:dir, ':p')
endfunction

" s:select_file(initial, prompt)    {{{1

""
" @private
" User selects a file or, more accurately, a filepath. An {initial} directory
" in which tp browse can be provided, as can a user {prompt}.
" @default prompt=Select file
" @throws BadFile if user selects an invalid filepath
" @throws NoFile if user did not select a file
function! s:select_file(initial, prompt)
    " set values
    let l:initial = ''
    if !empty(a:initial)
                \ && (isdirectory(a:initial) || !empty(glob(a:initial)))
        let l:initial = s:canonicalise(a:initial, ':p')
    endif
    let l:prompt = empty(a:prompt) ? 'Select file' : a:prompt
    let l:ERROR_NoFile = 'ERROR(NoFile): No file selected'
    let l:ERROR_BadFile = 'ERROR(BadFile): Invalid filepath: '
    " user selects file
    if has('prompt')  " gui available
        let l:file = browse(0, l:prompt, l:initial, '')
    else  " terminal
        let l:prompt .= ': '
        let l:file = input(l:prompt, l:initial, 'file')
    endif
    echo ' '
    " feedback
    if empty(l:file) | throw l:ERROR_NoFile | endif
    if empty(glob(l:file)) | throw l:ERROR_BadFile . ': ' . l:file | endif
    return s:canonicalise(l:file, ':p')
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
        throw 'ERROR(BadVarType): Invalid variable type'
    endif
endfunction

" s:title_capitalise(string)    {{{1

""
" @private
" Change text {string} to use title capitalisation. In this style of
" capitalisation, first and last words are capitalised, as are all other words
" except articles, prepositions and conjunctions of fewer than five letters.
"
" The converted text string is returned.
function! s:title_capitalise(string) abort
try
    " variables
    " - articles of speech are not capitalised in title case
    let l:articles = ['a', 'an', 'the']
    " - prepositions are not capitalised in title case
    let l:prepositions = [
                \ 'amid', 'as',   'at',   'atop', 'but',  'by',   'for',
                \ 'from', 'in',   'into', 'mid',  'near', 'next', 'of',
                \ 'off',  'on',   'onto', 'out',  'over', 'per',  'quo',
                \ 'sans', 'than', 'till', 'to',   'up',   'upon', 'v',
                \ 'vs',   'via',  'with'
                \ ]
    " - conjunctions are not capitalised in title case
    let l:conjunctions = [
                \  'and', 'as',   'both', 'but', 'for', 'how',  'if',
                \ 'lest', 'nor',  'once',  'or',  'so', 'than', 'that',
                \ 'till', 'when', 'yet'
                \ ]
    let l:temp = l:articles + l:prepositions + l:conjunctions
    " - merge all words not capitalised in title case
    " - weed out duplicates for aesthetic reasons
    let l:title_lowercase = []
    for l:item in l:temp
        if count(l:title_lowercase, l:item) == 0
            call add(l:title_lowercase, l:item)
        endif
    endfor
    " - splitting of header on word boundaries produces some pseudo-words that
    "   are not actual words, and these should not be capitalised in 'start'
    "   or 'title' case
    let l:pseudowords = ['s']
    unlet l:temp l:articles l:prepositions l:conjunctions l:item
    " check parameters
    if a:string ==? '' | return '' | endif
    " break up string into word fragments
    let l:words = split(a:string, '\<\|\>')
    " process words individually
    let l:index = 0
    let l:last_index = len(l:words) - 1
    let l:first_word = v:true
    let l:last_word = v:false
    for l:word in l:words
        let l:word = tolower(l:word)    " first make all lowercase
        let l:last_word = (l:index == l:last_index)    " check for last word
        if l:first_word
            let l:word = substitute(l:word, "\\w\\+", "\\u\\0", 'g')
        elseif l:last_word
            " beware some psuedo-words must not be capitalised
            if !count(l:pseudowords, l:word)
                let l:word = substitute(l:word, "\\w\\+", "\\u\\0", 'g')
            endif
        else  " word is not first or last
            " capitalise if not in list of words to be kept lowercase
            " and is not a psuedo-word
            if !count(l:title_lowercase, l:word)
                        \ && !count(l:pseudowords, l:word)
                let l:word = substitute(l:word, "\\w\\+", "\\u\\0", 'g')
            endif
        endif
        " negate first word flag after first word is encountered
        if l:first_word && l:word =~# '^\a'
            let l:first_word = v:false
        endif
        " write changed word
        let l:words[l:index] = l:word
        " move to next list item
        let l:index += 1
    endfor
    " return altered header
    return join(l:words, '')
catch
    call s:error(v:exception . ' at ' . v:throwpoint)
endtry
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
        throw 'ERROR(NoDate): Unable to obtain system date'
    endif
    let l:tw_time = l:datetime[0]
    let l:dt_regex = '^\d\{14}$'
    if l:tw_time !~ l:dt_regex
        call s:warn("Invalid date string '" . l:tw_time . "'")
        throw 'ERROR(BadDate): System datetime is invalid'
    endif
    " add on arbitrary millisecond value
    let l:tw_time .= '000'
    return l:tw_time
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
" }}}1

" Public functions

" tiddlywiki#addCanonicalUri([root[, images])    {{{1

""
" @public
" Adds or replaces the metadata line in which the "_canonical_uri" field is
" defined. This field is used when images are stored in a subdirectory of
" the wiki root directory, traditionally "wikiroot/images", and external image
" tiddlers are used to refer to them.
"
" The user can provide the wiki [root] directory and [images] directory, or
" select them manually. The images directory has to be located under the wiki
" root directory, and if specified as a parameter only the portion relative to
" the wiki root directory is given. For example, if the wiki root directory is
" "~/wiki" and the full path to the images directory is
" "~/wiki/output/images", then the images parameter would be given as
" "output/images".
"
" The user selects an image file from the images directory and a corresponding
" metadata line for the canonical uri is inserted at the top of the file, or
" overwrites an existing canonical uri.
"
" An inserted metadata field line may look like:
" >
"     _canonical_uri: images/My Image.png
" <
function! tiddlywiki#addCanonicalUri(...)
    " need wiki root directory (first optional parameter)
    if a:0 > 0 && a:1
        let l:root_dir = s:canonicalise(a:1)
        if !isdirectory(l:root_dir)
            call s:error('Invalid wiki root directory: ' . a:1)
            return
        endif
    else
        let l:prompt = 'Select wiki root directory'
        try   | let l:root_dir = s:select_dir(getcwd(), l:prompt)
        catch | call s:error(s:exception_error(v:exception)) | return
        endtry
    endif
    " need images directory (second optional parameter)
    if a:0 > 1 && a:2
        let l:images_dir = s:canonicalise(l:root_dir . '/' . a:2)
        if !isdirectory(l:images_dir)
            call s:error('Provided relative images directory: ' . a:2)
            call s:error('Invalid derived images directory: ' . l:images_dir)
            return
        endif
    else
        let l:prompt = 'Select images directory'
        try   | let l:images_dir = s:select_dir(l:root_dir, l:prompt)
        catch | call s:error(s:exception_error(v:exception)) | return
        endtry
    endif
    " confirm images dir is descendent of wiki root dir
    if l:root_dir ==# l:images_dir
        call s:error("Can't use wiki root directory as images directory")
        return
    endif
    let l:matchpos = match(l:root_dir, l:images_dir)
    if l:matchpos != -1
        echo 'Wiki root: ' . l:root_dir
        echo 'Image dir: ' . l:images_dir
        call s:error('Wiki root dir must be in path of images dir')
        return
    endif
    " get relative path for images dir
    let l:relative = strpart(l:images_dir,
                \            matchend(l:images_dir, l:root_dir) + 1)
    " select image file
    let l:prompt = 'Select image file'
    try   | let l:image_fp = s:select_file(l:images_dir, l:prompt)
    catch | call s:error(s:exception_error(v:exception)) | return
    endtry
    " check that image file is from images directory
    let l:image_dir = fnamemodify(l:image_fp, ':p:h')
    let l:image_file = fnamemodify(l:image_fp, ':p:t')
    if l:image_dir !=# l:images_dir
        call s:error('Image is not from the specified images directory')
        return
    endif
    " now can construct TW relative path to image
    let l:canonical_uri = l:relative . '/' . l:image_file
    " check for existing _canonical_uri metadata line
    let l:cur_pos = getcurpos()  " remember where we parked
    call setpos('.', [1, 1, 0, 1] )  " first row, first col
    let l:field_line = searchpos('^_canonical_uri: ', 'cnW')[0]
    call setpos('.', l:cur_pos)  " restore original cursor position
    " if _canonical_uri field already exists, check if it has a value
    if l:field_line > 0
        let l:line = getline(l:field_line)
        " know line *must* start with '_canonical_uri:'
        " so look for any content after that point
        if len(l:line) > 15
            let l:value = substitute(strpart(l:line, 15), '^ \+', '', '')
            let l:value = substitute(l:value, ' \+$', '', '')
            if len(l:value > 0)
                if l:value ==# l:canonical_uri
                    call s:warn('This image is already set as canonical uri')
                    return
                endif
                let l:msg = "Overwrite existing canonical uri '"
                            \ . l:value . "'?"
                let l:pick = confirm(l:msg, "&Yes\n&No", 2, 'Question')
                if l:pick != 1
                    return
                endif
            endif
        endif
    endif
    " add or replace _canonical_uri field
    let l:canonical_uri_line = '_canonical_uri: ' . l:canonical_uri
    if l:field_line == 0  " create new line
        call append(0, l:canonical_uri_line)
    else  " replace line
        call setline(l:field_line, l:canonical_uri_line)
    endif
endfunction

" tiddlywiki#convertTidToDivTiddler([field1[, field2[, ...]]])    {{{1

""
" @public
" Converts the contents of the current buffer, assumed to be in the syle of a
" "tid" file, to the style of a "div.tiddler" file, writes the "div.tiddler"
" file to the current directory and opens it in a new buffer. The "tid" and
" "div.tiddler" file styles are described in the "TiddlerFiles" tiddler at
" https://tiddlywiki.com.)
"
" If the current buffer is associated with a file the output "div.tiddler"
" file is given the same base name. If the current buffer is not associated
" with a file the user is prompted to enter one. The output file is given a
" "tiddler" extension.
"
" The "tid" content is assumed to be structured with at least one metadata
" line at the top of the document separated from the tiddler content/text by a
" blank line. Each metadata lines looks like "field: description". The content
" of the tags field is space-separated tag names; tag names containing spaces
" should be enclosed by doubled square brackets, e.g., "[[tag name]]".
" Default tag names set using the @setting(g:default_tiddler_tags) setting are
" added to any tag names defined in tiddler metadata. A default creator name
" can be set using @setting(g:default_tiddler_creator), but this is overridden
" by a creator set in tiddler metadata. If, for some reason, the same field is
" defined multiple times in metadata, the following occurs:
" * for the "tags" field, all field values are concatenated
" * for other fields, the last field value overrides all others.
"
" There is an optional pre-processing step in which lines at the top of the
" file can have field names prepended to them. This is triggered by passing
" [field] names to the function as arguments. Consider, for example, the
" function invocation:
" >
"     call tiddlywiki#convertTidToDivTiddler('title', 'tags')
" <
" This results in "title: " being prepended to the first line in the file and
" "tags: " being prepended to the second line in the file. If a blank line
" occurs before the field name arguments are exhausted, remaining field names
" are ignored.
"
" Because each field value becomes a html attribute value, some characters can
" confuse tiddlywiki's import parser. These characters include double-quotes,
" less-than signs and greater-than signs, which for that reason are silently
" replaced with single quotes, full width less-than signs (unicode code point
" FF1C) and full-width greater-than signs (unicode code point FF1E),
" respectively, during conversion.
" @throws CantEdit if unable to open tiddler file for editing
" @throws NoCreated if unable to set created date
" @throws DeleteFail if error occurs during file deletion
" @throws NoBoundary if no metadata/content boundary located
" @throws NoContent if no content/text in tiddler
" @throws NoFilename if no output filename entered by user
" @throws NoModified if unable to set modified date
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
    " - add created/modified date if absent and creator/modifier set
    if has_key(l:fields, 'creator') && !empty(l:fields.creator)
                \ && !has_key(l:fields, 'created')
        try   | let l:fields.created = s:tw_time()
        catch | call s:error(s:exception_error(v:exception))
                throw 'ERROR(NoCreated): Unable to set created date'
        endtry
    endif
    if has_key(l:fields, 'modifier') && !empty(l:fields.modifier)
                \ && !has_key(l:fields, 'modified')
        try   | let l:fields.modified = s:tw_time()
        catch | call s:error(s:exception_error(v:exception))
                throw 'ERROR(NoModified): Unable to set modified date'
        endtry
    endif
    " - build attributes string and add to div element
    let l:attributes = ''
    "   . these chars confuse the tiddlywiki import parser: '<', '>', and '"'
    for [l:field_name, l:field_value] in items(l:fields)
        if match(l:field_value, '"') > -1  " replace with single quote
            let l:field_value = substitute(l:field_value, '"', '''', 'g')
        endif
        if match(l:field_value, '<') > -1  " replace with unicode ff1c
            let l:field_value = substitute(l:field_value, '<', '＜', 'g')
        endif
        if match(l:field_value, '>') > -1  " replace with unicode ff1e
            let l:field_value = substitute(l:field_value, '>', '＞', 'g')
        endif
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

" tiddlywiki#tiddlify([field1[, field2[, ...]]])    {{{1

""
" @public
" Converts the contents of the current buffer to a basic tiddler. The first
" cluster of lines (up to the first empty line) are assumed to be metadata
" lines.
"
" Each metadata lines looks like "field: description". The content of the tags
" field is space-separated tag names; tag names containing spaces should be
" enclosed by doubled square brackets, e.g., "[[tag name]]".  Default tag
" names set using the @setting(g:default_tiddler_tags) setting are added to
" any tag names defined in tiddler metadata. A default creator name can be set
" using @setting(g:default_tiddler_creator), but this is overridden by a
" creator set in tiddler metadata. If, for some reason, the same field is
" defined multiple times in metadata, the following occurs:
" * for the "tags" field, all field values are concatenated
" * for other fields, the last field value overrides all others.
"
" There is an optional pre-processing step in which lines at the top of the
" file can have field names prepended to them. This is triggered by passing
" [field] names to the function as arguments. Consider, for example, the
" function invocation:
" >
"     call tiddlywiki#tiddlify('title', 'tags')
" <
" This results in "title: " being prepended to the first line in the file and
" "tags: " being prepended to the second line in the file. If a blank line
" occurs before the field name arguments are exhausted, remaining field names
" are ignored.
" @throws NoCreated if unable to set created date
" @throws NoBoundary if no metadata/content boundary located
" @throws NoModified if unable to set modified date
function! tiddlywiki#tiddlify(...)
    " define error messages    {{{2
    let l:ERROR_NoBoundary
                \ = 'ERROR(NoBoundary): No metadata/content boundary located'
    " slurp buffer content into list    {{{2
    let l:tid = getline(1, '$')
    " remove leading empty rows
    let l:leading_blanks = -1
    for l:line in l:tid
        if   l:line =~# '^\s*$' | let l:leading_blanks +=1
        else                    | break
        endif
    endfor
    if l:leading_blanks >=0
        call remove(l:tid, 0, l:leading_blanks)
    endif
    " add field names to metadata (optional)    {{{2
    let l:tid_index = 0
    for l:field in a:000
        let l:line = get(l:tid, l:tid_index, '')
        if empty(l:line) | break | endif |  " ran out of tiddler lines
        let l:line = l:field . ': ' . l:line
        let l:tid[l:tid_index] = l:line
        let l:tid_index += 1
    endfor
    " locate metadata boundary    {{{2
    let l:boundary_index = 0
    for l:line in l:tid
        if l:line =~# '^\s*$' | break | endif
        let l:boundary_index += 1
    endfor
    if l:boundary_index >= len(l:tid) | throw l:ERROR_NoBoundary | endif
    let l:metadata_end = l:boundary_index
    " prepare variables used in metadata processing    {{{2
    let l:fields = {}
    if exists('g:default_tiddler_tags') && !empty(g:default_tiddler_tags)
        let l:fields['tags'] = g:default_tiddler_tags
    endif
    if exists('g:default_tiddler_creator') && !empty(g:default_tiddler_creator)
        let l:fields['creator'] = g:default_tiddler_creator
    endif
    " process existing tiddler metadata    {{{2
    " - fills 'l:fields' dict with field names and values
    let l:list_metadata_end = l:metadata_end - 1
    for l:line in l:tid[0 : l:list_metadata_end]
        let l:field_name = split(l:line, ':')[0]
        let l:match_expr = l:field_name . ':\s*'
        let l:value_start = matchend(l:line, l:match_expr)
        let l:field_value = strpart(l:line, l:value_start)
        " 'title' and 'tags' fields are handled as special cases
        if     l:field_name =~# '^tags$'
            let l:fields['tags'] .=  ' ' . l:field_value
        elseif l:field_name =~# '^title$'
            let l:fields['title'] = s:title_capitalise(l:field_value)
        else
            let l:fields[l:field_name] = l:field_value
        endif
    endfor
    " add metadata fields in some conditions    {{{2
    " - add created/modified date if absent and creator/modifier set
    if has_key(l:fields, 'creator') && !empty(l:fields.creator)
                \ && !has_key(l:fields, 'created')
        try   | let l:fields.created = s:tw_time()
        catch | call s:error(s:exception_error(v:exception))
                throw 'ERROR(NoCreated): Unable to set created date'
        endtry
    endif
    if has_key(l:fields, 'modifier') && !empty(l:fields.modifier)
                \ && !has_key(l:fields, 'modified')
        try   | let l:fields.modified = s:tw_time()
        catch | call s:error(s:exception_error(v:exception))
                throw 'ERROR(NoModified): Unable to set modified date'
        endtry
    endif
    " write metadata to buffer    {{{2
    " - convert fields dict to metadata lines ready for insertion
    let l:metadata = []
    for [l:key, l:value] in items(l:fields)
        call add(l:metadata, l:key . ': ' . l:value)
    endfor
    " - delete existing metadata lines
    execute '1,' . l:metadata_end . 'delete _'
    " - insert replacement lines
    call append(0, l:metadata)    " }}}2
endfunction

" tiddlywiki#uniquefyDataTiddler()    {{{1

""
" @public
" Adds a unique numeric prefix to rows in a dictionary data tiddler. More
" specifically, it adds "X: " to the beginning of each row where "X" is an
" incrementing integer starting at 1 on the first line.
"
" Executes the following vimscript commands:
" >
"   execute 'let n=[0]'
"   execute "%s/^/\\=map(n, 'v:val+1')[0] . ': '/"
" <
" which are the equivalent of the following command executed in
" |Cmdline-mode|:
" >
"   let n=[0] | %s/^/\=map(n, 'v:val+1')[0] . ': '/
" <
" @throws CantUniquify if unable to complete prefix insertion
function! tiddlywiki#uniquefyDataTiddler()
    " define error messages
    let l:ERROR_CantUniquify
                \ = 'ERROR(CantUniquify): Unable to complete '
                \ . 'insertion of prefixes'
    " insert prefixes
    try
        silent execute 'let n=[0]'
        silent execute "%s/^/\\=map(n, 'v:val+1')[0] . ': '/"
    catch
        call s:error(s:exception_error(v:exception))
        throw l:ERROR_CantUniquify
    endtry
endfunction

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
        throw 'ERROR(NoModified): Unable to locate "modified" metadata field'
    endif
    " replace line
    try
        let l:tw_time = s:tw_time()
    catch
        call s:error(s:exception_error(v:exception))
        throw 'ERROR(NoDate): Unable to obtain system date'
    endtry
    let l:new_mod = 'modified: ' . s:tw_time()
    let l:retval = setline(l:line, l:new_mod)
    if l:retval == 1
        call s:warn('Unable to modify "modified" metadata field')
        throw 'ERROR(CantModify): Unable to modify "modified" metadata field'
    endif
    " return to original location
    let l:retval = setpos('.', l:save_cursor)
    if l:retval == -1
        call s:warn('Unable to restore original cursor position')
        throw 'ERROR(CantSetPos): Unable to restore original cursor position'
    endif
endfunction
" }}}1

" Control statements    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo
" }}}1

" vim: set foldmethod=marker :
