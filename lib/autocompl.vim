
function! FFcompletecolon()
  " Find the param name, if any
  let curline = getline('.')
  let pos = col('.') - 3
  let param = ""

  while pos >= 0 && curline[pos] =~ '\a'
    let param = curline[pos] . param
    let pos = pos - 1
  endwhile

  if param == ""
    return ""
  endif

  " Find FFcomplete_{param} function.
  " If the function is not found, or any error is thrown, ignore them
  let items = []
  silent! let items = FFcomplete_{param}()
  if len(items) > 0
    call complete(col("."), items)
  endif

  return ""
endfunction

function! FFcomplete_limit()
  return ["5", "10", "20", "50", "100"]
endfunction
