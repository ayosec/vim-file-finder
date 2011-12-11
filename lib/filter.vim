
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

" Implementation for limit:N
function! g:filefinder_match_limit(filename, argument)
  if line("$") > a:argument
    throw "STOP"
  endif
  return 1
endfunction


" Implementation for git:param
" param can be
"  .   files tracked by Git
"  M   files with modifications
function! g:filefinder_match_git(filename, argument)
  let fullfilename = b:rootdirectory . a:filename

  if a:argument == "." || a:argument == ""
    if !exists("b:gitfiles")
      let b:gitfiles = s:ReadFilesFromGit("git ls-tree HEAD --full-name -r --name-only %root" )
    endif

    return index(b:gitfiles, fullfilename) != -1

  elseif tolower(a:argument) == "m"
    if !exists("b:gitmodifiedfiles")
      let b:gitfiles = s:ReadFilesFromGit("git diff HEAD --name-only")
    end

    return index(b:gitfiles, fullfilename) != -1
  else
    throw "Unknown value for git param"
  endif
endfunction

function! s:ReadFilesFromGit(command)
  let gitroot = system("git rev-parse --show-toplevel")[ : -2 ] . "/"
  let command = substitute(a:command, "%root", gitroot, "g")
  return map(split(system(command), "\n"), 'gitroot . v:val')
endfunction

" Implementation for grep:param

function! g:filefinder_match_grep(filename, argument)
  for line in readfile(b:rootdirectory . a:filename)
    if line =~? a:argument
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


