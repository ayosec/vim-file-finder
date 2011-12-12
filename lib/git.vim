
" Implementation for git:param.
" Valid values can be seen in the body of FFcomplete_git()

function! FFmatch_git(filename, argument)
  let fullfilename = b:rootdirectory . a:filename

  if a:argument == "tracked" || a:argument == ""
    if !exists("b:gitfiles")
      let b:gitfiles = s:ReadFilesFromGit("git ls-files" )
    endif

    return index(b:gitfiles, fullfilename) != -1

  elseif a:argument == "untracked" || a:argument == ""
    if !exists("b:gituntrackedfiles")
      let b:gituntrackedfiles = s:ReadFilesFromGit("git ls-files -o" )
    endif

    return index(b:gituntrackedfiles, fullfilename) != -1

  elseif tolower(a:argument) == "modified"
    if !exists("b:gitmodifiedfiles")
      let b:gitmodifiedfiles = s:ReadFilesFromGit("git diff HEAD --name-only")
    end

    return index(b:gitmodifiedfiles, fullfilename) != -1
  else
    throw "Unknown value for git param"
  endif
endfunction

function! s:ReadFilesFromGit(command)
  let gitroot = system("git rev-parse --show-toplevel")[ : -2 ] . "/"
  return map(split(system("cd " . gitroot . " && " . a:command), "\n"), 'gitroot . v:val')
endfunction

function! FFcomplete_git()
  if !exists("s:gitparamvalues")
    let s:gitparamvalues = []
    call add(s:gitparamvalues, { "word": "modified", "menu": "Files with modifications" })
    call add(s:gitparamvalues, { "word": "tracked", "menu": "Tracked files" })
    call add(s:gitparamvalues, { "word": "untracked", "menu": "Ignored files" })
  endif
  return s:gitparamvalues
endfunction

