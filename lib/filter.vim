
function! FFchangefilter()
  let g:FFfilter =  FFHcyclenext(keys(g:FFfiltermethods), g:FFfilter)
  call FFrefreshcontent()
endfunction

function! FFfiltermatchwithpatterns(currentpattern, filename)
  for pattern in split(a:currentpattern, "  *")
    if pattern[0] == '-'
      if match(a:filename, pattern[1:]) >= 0
        return 0
      endif
    else
      let sepidx = stridx(pattern, ":")
      if sepidx == -1
        if match(a:filename, pattern) == -1
          return 0
        endif
      else
        let operator = strpart(pattern, 0, sepidx)
        let argument = strpart(pattern, sepidx + 1)
        if FFmatch_{operator}(a:filename, argument) == 0
          return 0
        end
      endif
    endif
  endfor
  return 1
endfunction

" Implementation for limit:N
function! FFmatch_limit(filename, argument)
  if line("$") > a:argument
    throw "STOP"
  endif
  return 1
endfunction

" Implementation for grep:param

function! FFmatch_grep(filename, argument)
  for line in readfile(b:rootdirectory . a:filename)
    if line =~? a:argument
      return 1
    end
  endfor
endfunction

" Implementation for mgrep:param

function! FFmatch_mgrep(filename, argument)
  for line in readfile(b:rootdirectory . a:filename)
    if line =~# a:argument
      return 1
    end
  endfor
endfunction

" Implementation for mtime:param
" Values are in the format Nt, where N is a integer value and t a time unit.
" Valid time units are 'm' for minutes, 'h' for hours and 'd' for days
function! FFmatch_mtime(filename, argument)

  if a:argument == ""
    return 1
  end

  if !exists("b:cachedbasetime")
    let b:cachedbasetime = {}
  endif

  if !has_key(b:cachedbasetime, a:argument)
    let found = matchlist(a:argument, '\(\d\+\)\([mhd]\)')
    if len(found) == 0
      throw 'The ' . a:argument . ' is not recognized as a time value. It has to match \d+[mhd]'
    end

    let time = str2nr(found[1], 10)
    let unit = found[2]

    let basetime = 0
    if unit == 'm'
      let basetime = time * 60
    elseif unit == 'h'
      let basetime = time * 3600
    elseif unit == 'd'
      let basetime = time * 86400
    endif

    let b:cachedbasetime[a:argument] = basetime
  endif

  return getftime(b:rootdirectory . a:filename) >= (localtime() - b:cachedbasetime[a:argument])

endfunction

function! FFcomplete_mtime()
  if !exists("s:mtimeparamvalues")
    let s:mtimeparamvalues = []
    call add(s:mtimeparamvalues, { 'word': '30m', 'menu': '(30 minutes)' })
    call add(s:mtimeparamvalues, { 'word':  '4h', 'menu': '(4 hours)' })
    call add(s:mtimeparamvalues, { 'word':  '2d', 'menu': '(2 days)' })
    call add(s:mtimeparamvalues, { 'word':  '7d', 'menu': '(7 days)' })
    call add(s:mtimeparamvalues, { 'word': '15d', 'menu': '(15 days)' })
  endif
  return s:mtimeparamvalues
endfunction



function! FFfiltermatchwithletters(currentpattern, filename)
  let pattern = substitute(a:currentpattern, "[[:space:]]*", "", "g")
  let patternlen = len(pattern)
  let filename = a:filename
  let l:i = 0
  let lastidx = 0
  while l:i < patternlen
    let lastidx = match(filename, '\c' . pattern[l:i], lastidx) + 1

    if lastidx == 0
      return 0
    endif

    let l:i += 1
  endwhile
  return 1
endfunction

