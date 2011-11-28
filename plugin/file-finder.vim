" Vim File Finder
" Maintainer:  Ayose Cazorla <ayosec@gmail.com>
" Last Change: 2011 Nov 28

if !exists("g:filefinder_sort")
  let g:filefinder_sort = "FFSortByOldFiles"
endif

function! OpenFileFinder()

  if !empty(bufname("%")) || getbufvar("%", "&modified")
    tabnew
  endif

  let b:prevpattern = ""

  " Root directory. Ensure the name is finished with an slash
  let b:rootdirectory = getcwd()
  if b:rootdirectory[len(b:rootdirectory) - 1] != "/"
    let b:rootdirectory .= "/"
  endif

  call FFGenerateFileList()

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
  setlocal updatetime=50
  au CursorHoldI <buffer> call feedkeys("\\\\")
  "au CursorHold <buffer> :bd

  " Key bindings to manage the file list
  inoremap <buffer> <Cr> <Esc>:call FFOpenSelectedFile()<Cr>
  inoremap <buffer> <Up> <C-o>:call FFMoveSelection(-1)<Cr>
  inoremap <buffer> <Down> <C-o>:call FFMoveSelection(1)<Cr>

  " Sorting
  inoremap <buffer> <F5> <C-o>:call FFChangeSort("Name")<Cr>
  inoremap <buffer> <F6> <C-o>:call FFChangeSort("MTime")<Cr>
  inoremap <buffer> <F7> <C-o>:call FFChangeSort("OldFiles")<Cr>

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

function! FFGenerateFileList()
  " Generate file list. Excludie directories.
  " Use wildignore to exclude files
  let b:foundfiles = []

  " Sort them
  let l:files = split(globpath(b:rootdirectory, "**"), "\n")
  call sort(files, g:filefinder_sort)

  for item in l:files
    if isdirectory(item) == 0
      if stridx(item, b:rootdirectory) == 0
        let item = strpart(item, len(b:rootdirectory))
      endif
      call add(b:foundfiles, item)
    endif
  endfor
endfunction

function! FFStatusLine()
  return "[" . g:filefinder_sort . "] Showing " . (getpos("$")[1] - 1) . " files of " . len(b:foundfiles) . " in " . b:rootdirectory
endfunction

function! FFUpdateContent()

  " Avoid update the list if the pattern is unmodified
  let l:currentpattern = getline(1)

  " Ensure spaces at the EOL
  if l:currentpattern[len(l:currentpattern) - 1] != ' '
    let l:currentpattern .= " "
    call setline(1, l:currentpattern)
  endif

  if b:prevpattern == l:currentpattern
    return
  endif
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
      endif
    endfor
  endif

  if line("$") > 1
    normal 2G0r>
  endif

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
  endif
endfunction

function! FFChangeSort(sortname)
  let g:filefinder_sort = "FFSortBy" . a:sortname
  let b:prevpattern = ""

  call FFGenerateFileList()
  call FFUpdateContent()
endfunction

function! FFMoveSelection(offset)
  let oldpos = getpos(".")
  if search("^>") > 0
    s/^>/ /
    exe "normal " . (line(".") + a:offset) . "G"

    if line(".") < 2
      normal 2G
    endif

    normal 0r>
  endif
  call setpos('.', oldpos)
endfunction

function! FFSortByName(a, b)
  if a:a > a:b
    return 1
  elseif a:a < a:b
    return -1
  endif
  return 0
endfunction

function! FFSortByOldFiles(a, b)
  let pa = index(v:oldfiles, a:a)
  let pb = index(v:oldfiles, a:b)
  if pa == pb
    return FFSortByName(a:a, a:b)
  elseif pa == -1 || (pb != -1 && pb < pa)
    return 1
  elseif pb == -1 || (pb != -1 && pa < pb)
    return -1
  endif
endfunction

function! FFSortByMTime(a, b)
  let va = getftime(a:a)
  let vb = getftime(a:b)
  if va == -1 && vb != -1
    return 1
  elseif vb == -1 && va != -1
    return -1
  endif
  return vb - va
endfunction

function! FFSortByOldFiles(a, b)
  let pa = index(v:oldfiles, a:a)
  let pb = index(v:oldfiles, a:b)
  if pa == pb
    return FFSortByName(a:a, a:b)
  elseif pa == -1 || (pb != -1 && pb < pa)
    return 1
  elseif pb == -1 || (pb != -1 && pa < pb)
    return -1
  endif
endfunction

noremap <leader>o :call OpenFileFinder()<Cr>
