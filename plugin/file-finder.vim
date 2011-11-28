" Vim File Finder
" Maintainer:  Ayose Cazorla <ayosec@gmail.com>
" Last Change: 2011 Nov 28

if !exists("g:filefinder_ignore")
  let g:filefinder_ignore = ['/\.git/]', '\.\(class\|png\|jar\)$']
end

function! OpenFileFinder()

  if !empty(bufname("%")) || getbufvar("%", "&modified")
    tabnew
  end

  let b:prevpattern = ""

  " Root directory. Ensure the name is finished with an slash
  let b:rootdirectory = getcwd()
  if b:rootdirectory[len(b:rootdirectory) - 1] != "/"
    let b:rootdirectory .= "/"
  endif


  " Generate file list
  let b:foundfiles = []
  let ignorepattern = join(map(copy(g:filefinder_ignore), '''\('' . v:val . ''\)'''), '\|')
  for item in split(globpath(b:rootdirectory, "**"), "\n")
    if isdirectory(item) == 0
      if stridx(item, b:rootdirectory) == 0
        let item = strpart(item, len(b:rootdirectory))
      endif

      if match(item, ignorepattern) == -1
        call add(b:foundfiles, item)
      end
    endif
  endfor

  " Dialog-like buffer
  file \<File\ selector\>
  setlocal statusline=%!FFStatusLine()
  setlocal laststatus=2
  setlocal buftype=nowrite
  setlocal bufhidden=delete
  setlocal noswapfile
  setlocal ignorecase

  " Colors
  setlocal cursorline
  syn region SelectedFile start='>' end='$'
  hi CursorLine cterm=NONE ctermbg=darkgray ctermfg=white guibg=darkgray guifg=white
  hi SelectedFile cterm=NONE ctermbg=blue ctermfg=white guibg=blue guifg=white

  " Timer to update the file list.
  " The timer is a trick using the CursorHoldI event and a fake key combination
  inoremap <buffer> \\ <C-o>:call FFUpdateContent()<Cr>
  setlocal updatetime=20
  au CursorHoldI <buffer> call feedkeys("\\\\")
  "au CursorHold <buffer> :bd

  " Key bindings to manage the file list
  inoremap <buffer> <Cr> <Esc>:call FFOpenSelectedFile()<Cr>
  inoremap <buffer> <Up> <C-o>:call FFMoveSelection(-1)<Cr>
  inoremap <buffer> <Down> <C-o>:call FFMoveSelection(1)<Cr>

  " Don't keep the buffer if the focus is lost or <C-c> is pressed
  inoremap <buffer> <C-c> <Esc>:bd<Cr>
  nnoremap <buffer> <C-c> :bd<Cr>
  au BufLeave <buffer> :bd
  "au InsertLeave <buffer> :bd

  " Append blank spaces to the EOL to make easier to restore the cursor position after update the buffer content
  1s/$/ /

  " Time to find files!
  startinsert

endfunction

function! FFStatusLine()
  return "Showing " . (getpos("$")[1] - 1) . " files of " . len(b:foundfiles) . " in " . b:rootdirectory
endfunction

function! FFUpdateContent()

  " Avoid update the list if the pattern is unmodified
  let l:currentpattern = getline(1)

  " Ensure spaces at the EOL
  if l:currentpattern[len(l:currentpattern) - 1] != ' '
    let l:currentpattern .= " "
    call setline(1, l:currentpattern)
  end

  if b:prevpattern == l:currentpattern
    return
  end
  let b:prevpattern = l:currentpattern

  " Erase old results, if any
  let oldpos = getpos(".")
  if line("$") > 1
    exe "2,$d"
  endif

  " Search the files with the new pattern
  let patterns = split(currentpattern, "  *")
  let rootdirectorylength = len(b:rootdirectory)
  if len(patterns) > 0
    for item in b:foundfiles
      let allmatches = 1
      for pattern in patterns
        if match(item, pattern) == -1
          let allmatches = 0
          break
        endif
      endfor

      if allmatches == 1
        call append(line("$"), "  " . item)
      end
    endfor
  end

  if line("$") > 1
    normal 2G0r>
  end

  " Ensure the cursor is always in the first line
  let oldpos[1] = 1
  call setpos('.', oldpos)
  startinsert
endfunction

function! FFOpenSelectedFile()
  normal 1G
  if search("^>") > 0
    let selectedfile = strpart(getline("."), 2)
    bd
    echom "Open " . selectedfile . " in a new tab"
    exe "tabnew " . selectedfile
  end
endfunction

function! FFMoveSelection(offset)
  let oldpos = getpos(".")
  if search("^>") > 0
    s/^>/ /
    exe "normal " . (line(".") + a:offset) . "G"

    if line(".") < 2
      normal 2G
    end

    normal 0r>
  end
  call setpos('.', oldpos)
endfunction

noremap <leader>o :call OpenFileFinder()<Cr>
