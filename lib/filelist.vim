
function! FFrefreshcontent()
  let b:prevpattern = ""

  call FFgeneratefilelist()
  call FFupdatecontent()
endfunction


function! FFgeneratefilelist()
  " Sort them
  let l:files = split(system("rg --files --hidden --glob='!.git'"), "\n")

  if len(files) < 1000
    call sort(files, g:FFsort)
  endif

  let b:foundfiles = l:files
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

