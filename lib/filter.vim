
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
        if g:filefinder_match_{operator}(a:filename, argument) == 0
          return 0
        end
      endif
    endif
  endfor
  return 1
endfunction

function! g:filefinder_match_limit(filename, argument)
  if(line("$") > a:argument)
    throw "STOP"
  endif
  return 1
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


