
" FileFinder helpers

function! FFHcurrentbufferisempty()
  return empty(bufname("%")) && !getbufvar("%", "&modified")
endfunction

function! FFHcyclenext(list, item)
  let idx = index(a:list, a:item) + 1
  return a:list[idx >= len(a:list) ? 0 : idx]
endfunction

