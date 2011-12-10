
function! FFopenselectedfile()

  let l:rootdirectory = b:rootdirectory

  " Save current pattern
  1s/ *$//
  let g:FFoldpattern = getline(1)

  let oldreg = @h
  let @h = ""
  %g/^ *>/normal "HY
  let l:files = split(@h, "\n")
  let @h = oldreg

  bd

  for line in l:files
    let path = l:rootdirectory . strpart(line, 3)

    let foundopen = 0

    " If the file is already open just focus on it
    let bufnum = bufnr(path)
    if bufnum != -1
      for l:i in range(tabpagenr('$'))
        let bufidx = index(tabpagebuflist(l:i + 1), bufnum)
        if bufidx != -1
          " Tab found. Now, try to focus on the file
          exe (l:i + 1) . "tabnext"
          for noinfinityloop in range(100)
            if bufnr("%") == bufnum | break | endif
            wincmd w " Next buffer
          endfor
          let foundopen = 1
          break
        end
      endfor
    end

    " The file is not open yet. Open in a new tab or reuse the current buffer if empty
    if foundopen == 0
      exe (FFHcurrentbufferisempty() ? 'e ' : 'tabnew ') . fnameescape(fnamemodify(path, ':.'))
    end
  endfor
endfunction

function! FFfixselection()
  let oldpos = getpos(".")

  if search("^>") > 0
    if getline(".")[1] == ">"
      normal 0lr |
    else
      normal 0lr>
    endif
  endif

  call setpos('.', oldpos)
endfunction

function! FFmoveselection(offset)
  let oldpos = getpos(".")
  let oldreg = @h

  " Restore hidden lines
  if len(b:hiddenlines) > 0
    let @h = b:hiddenlines
    let b:hiddenlines = ""

    normal gg"hp
  end

  if search("^>") > 0
    s/^>/ /
    exe "normal " . max([2, line(".") + a:offset]) . "G"
    normal 0r>

    " Ensure the selected file is visible
    let winoffset = line(".") - winheight(".")
    if winoffset > 0
      exe 'normal 2G"h' . winoffset . 'dd'
      let b:hiddenlines = @h
    end
  endif

  let @h = oldreg
  call setpos('.', oldpos)
endfunction

