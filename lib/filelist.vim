
function! FFrefreshcontent()
  let b:prevpattern = ""

  call FFgeneratefilelist()
  call FFupdatecontent()
endfunction


function! FFgeneratefilelist()
  " Generate file list. Exclude directories.
  " Use wildignore to exclude files
  let b:foundfiles = []

  " Sort them
  let l:files = split(system("rg --files -0"), "\0")

  call sort(files, g:FFsort)

  for item in l:files
    if isdirectory(item) == 0
      if stridx(item, b:rootdirectory) == 0
        let item = strpart(item, len(b:rootdirectory))
      endif
      call add(b:foundfiles, item)
    endif
  endfor
endfunction

function! FFupdatecontent()

  " Remove any possible ':' prefix
  silen! 1s/\(^\| \):/\1/g

  " Read the current pattern, and remove
  " - The mark used to restore the cursor (b:marktorestorecursor)
  " - Any possible comment (after the ## marks)
  let l:currentpattern = substitute(getline(1), b:marktorestorecursor, "", "")
  let l:currentpattern = substitute(l:currentpattern, '##.*', "", "")

  " New state
  let b:hiddenlines = ""

  " Erase old results, if any
  silent! 2,$d

  " Search the files with the new pattern
  let succeed = 1
  try
    for item in b:foundfiles
      if {g:FFfilter}(l:currentpattern, item)
        let prefix = (bufnr(b:rootdirectory . item) == -1) ? "   " : " + "
        call append(line("$"), prefix . item)

        if line("$") > 100
          throw "STOP"
        endif
      endif
    endfor
  catch /STOP/
    " Just stop
  catch
    call setline(2, '!' . v:exception)
    silent! 3,$d

    let succeed = 0
  endtry

  " Cache the size to show it in the statusline
  let b:resultslength = line("$") - 1

  if succeed && line("$") > 1
    normal 2G0r>
  endif

  call FFrestorecursor()
endfunction

