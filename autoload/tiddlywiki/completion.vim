
" Main completefunc body
function! tiddlywiki#completion#UserFunc(findstart, base)
  if a:findstart 
    return tiddlywiki#completion#FindStart()
  else
    return tiddlywiki#completion#ListCandidates(a:base)
  endif
endfunction


function! tiddlywiki#completion#FindStart()
  let line = getline('.')
  let start = col('.') - 1

  while (start > 0) && 
        \ ((line[start - 1] =~ '\a') || (line[start - 1] == '[')) &&
        \ (strpart(line, start, 2) != '[[')
    let start -= 1
  endwhile

  if strpart(line, start, 2) == '[['
    echom "FindStart: found <" . strpart(line, start, (col('.') - start)) . ">"
    return start
  elseif match(line[start], '\v[A-Z]') == 0
    echom "FindStart: found <" . strpart(line, start, (col('.') - start)) . ">"
    return start
  else
    echom "FindStart: NOTfound <" . strpart(line, start, (col('.') - start)) . ">"
    return -3
  endif
endfunction


function! tiddlywiki#completion#ListCandidates(base)
  if strpart(a:base, 0, 2) == '[['
    let baseStr = strpart(a:base, 2)
    let withBrackets = 1
  else
    let baseStr = a:base
    let withBrackets = 0
  endif

  echom "baseStr = <" . baseStr . ">, withBrackets=" . withBrackets
  let candidates = tiddlywiki#completion#FindTiddlers(baseStr, !withBrackets)
  echom "candidates = "
  echom candidates
  let words = []

  for candidate in candidates
    let replacement = candidate
    if withBrackets
      let replacement = '[[' . candidate . ']]'
    endif

    call add(words, {'abbr': candidate, 'word': replacement })
  endfor

  echom "words = "
  echom words
  return words
endfunction


" Completion func for tiddler names
function! tiddlywiki#completion#FindTiddlers(prefix, wordsOnly)
  let dir = tiddlywiki#TiddlyWikiDir()
  let fqns = globpath(dir, a:prefix . '*.tid', 1, 1)
  let files = map(fqns, 'strpart(v:val, strridx(v:val, "/") +1)')
  let names = map(files, 'strpart(v:val, 0, strridx(v:val, "."))')

  echom "wordsOnly= " . a:wordsOnly . ", names = "
  echom names
  if a:wordsOnly
    echom "filtering"
    call filter(names, 'v:val =~# ' ."'" . '\v^(\u(\l|\d)+)+$' . "'")
    return names
  else
    return names
  endif
endfunction
