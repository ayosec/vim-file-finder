
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

