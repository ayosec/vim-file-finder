
function! FFchangesort()
  let g:FFsort = FFHcyclenext(keys(g:FFsortmethods), g:FFsort)
  call FFrefreshcontent()
endfunction

function! FFsortbyname(a, b)
  if a:a > a:b
    return 1
  elseif a:a < a:b
    return -1
  endif
  return 0
endfunction

function! s:indexforsorting(list, item)
  let idx = index(a:list, a:item)
  return idx == -1 ? len(a:list) + 1 : idx
endfunction

function! FFsortbyoldfiles(a, b)
  return s:indexforsorting(b:recentfiles, a:a) - s:indexforsorting(b:recentfiles, a:b)
endfunction

function! FFsortbymtime(a, b)
  let va = getftime(a:a)
  let vb = getftime(a:b)
  if va == -1 && vb != -1
    return 1
  elseif vb == -1 && va != -1
    return -1
  endif
  return vb - va
endfunction
