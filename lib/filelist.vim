
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
  let l:files = split(globpath(b:rootdirectory, "**"), "\n")
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

  " Force the cursor to stay in the first line
  if line(".") > 1
    normal gg
  end

  let l:currentpattern = getline(1)

  " Ensure spaces at the EOL
  if l:currentpattern[len(l:currentpattern) - 1] != ' '
    let l:currentpattern .= " "
    call setline(1, l:currentpattern)
  endif

  " Avoid to update the list if the pattern is unmodified
  if b:prevpattern == l:currentpattern
    return
  endif

  " New state
  let b:prevpattern = l:currentpattern
  let b:hiddenlines = ""

  " Erase old results, if any
  let oldpos = getpos(".")
  silent! 2,$d

  " Search the files with the new pattern
  let succeed = 1
  try
    for item in b:foundfiles
      if {g:FFfilter}(l:currentpattern, item)
        let prefix = (bufnr(b:rootdirectory . item) == -1) ? "   " : " + "
        call append(line("$"), prefix . item)
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

  " Ensure the cursor is always in the first line
  let oldpos[1] = 1
  call setpos('.', oldpos)
  startinsert
endfunction

