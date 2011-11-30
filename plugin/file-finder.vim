" Vim File Finder
" Maintainer:  Ayose Cazorla <ayosec@gmail.com>
" Last Change: 2011 Nov 29

" Global variables: {{{

if !exists("g:filefinder_sort")
  let g:filefinder_sort = "FFSortByOldFiles"
endif

if !exists("g:filefinder_filter")
  let g:filefinder_filter = "FFFilterMatchWithPatterns"
endif

if !exists("g:filefinder_sortmethods")
  let g:filefinder_sortmethods = {}
  let g:filefinder_sortmethods['FFSortByName'] = 'Name'
  let g:filefinder_sortmethods['FFSortByMTime'] = 'Mod time'
  let g:filefinder_sortmethods['FFSortByOldFiles'] = 'Last access'
endif

if !exists("g:filefinder_filtermethods")
  let g:filefinder_filtermethods = {}
  let g:filefinder_filtermethods["FFFilterMatchWithLetters"] = "Letters"
  let g:filefinder_filtermethods["FFFilterMatchWithPatterns"] = "Patterns"
endif

" }}}

" Main function: {{{

function! OpenFileFinder()

  if !empty(bufname("%")) || getbufvar("%", "&modified")
    tabnew
  endif

  let b:prevpattern = ""
  let b:hiddenlines = ""
  let b:resultslength = 0

  " Root directory. The name has to finish with an slash
  if exists("g:filefinder_rootdir")
    let b:rootdirectory = g:filefinder_rootdir
  else
    let b:rootdirectory = getcwd()
    if b:rootdirectory[len(b:rootdirectory) - 1] != "/"
      let b:rootdirectory .= "/"
    endif
  end

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
  inoremap <buffer> <PageUp> <C-o>:call FFMoveSelection(-winheight("."))<Cr>
  inoremap <buffer> <PageDown> <C-o>:call FFMoveSelection(winheight("."))<Cr>

  nnoremap <buffer> <Cr> :call FFOpenSelectedFile()<Cr>
  nnoremap <buffer> <Up> :call FFMoveSelection(-1)<Cr>
  nnoremap <buffer> <Down> :call FFMoveSelection(1)<Cr>
  nnoremap <buffer> <PageUp> :call FFMoveSelection(-winheight("."))<Cr>
  nnoremap <buffer> <PageDown> :call FFMoveSelection(winheight("."))<Cr>

  " Sorting and filtering
  inoremap <buffer> <C-d> <C-o>:call FFChangeSort()<Cr>
  inoremap <buffer> <C-f> <C-o>:call FFChangeFilter()<Cr>

  " Don't keep the buffer if the focus is lost or <C-c> is pressed
  inoremap <buffer> <C-c> <Esc>:bd<Cr>
  nnoremap <buffer> <C-c> :bd<Cr>
  au BufLeave <buffer> :bd
  "au InsertLeave <buffer> :bd

  " Append blank spaces to the EOL to make easier to restore the cursor position after update the buffer content
  1s/$/    /
  normal 0

  if exists("#User#FileFinderConfigure")
    " Users can have their own definitions with the autocmd
    doautocmd User FileFinderConfigure
  endif

  call FFGenerateFileList()

  " Time to find files!
  startinsert

endfunction

" }}}

" UI: {{{

function! FFStatusLine()
  let content = "["

  " Selected sort method
  let content .= "[ <C-d> Sort: " . get(g:filefinder_sortmethods, g:filefinder_sort, g:filefinder_sort) . " | "

  " Selected filter method
  let content .= "<C-f> Filter: " . get(g:filefinder_filtermethods, g:filefinder_filter, g:filefinder_filter) . " ] "

  " Counters (matches / available files)
  let content .= " [" . b:resultslength . "/" . len(b:foundfiles) . "] "

  " Root directory, right aligned
  let content .= "%=" . b:rootdirectory

  return content
endfunction

function! FFGenerateFileList()
  " Generate file list. Exclude directories.
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

function! FFRefreshContent()
  let b:prevpattern = ""

  call FFGenerateFileList()
  call FFUpdateContent()
endfunction

function! FFOpenSelectedFile()
  normal gg
  if search("^>") > 0
    let selectedfile = fnameescape(b:rootdirectory . strpart(getline("."), 2))
    bd
    echom "Open " . selectedfile . " in a new tab"
    exe "tabnew " . selectedfile
  endif
endfunction

function! FFMoveSelection(offset)
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

" }}}

" Update content: {{{

function! FFUpdateContent()

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
  if line("$") > 1
    2,$d
  endif

  " Search the files with the new pattern
  let s:filterfn = function(g:filefinder_filter)
  for item in b:foundfiles
    if call(s:filterfn, [l:currentpattern, item])
      call append(line("$"), "  " . item)
    endif
  endfor

  " Cache the size to show it in the statusline
  let b:resultslength = line("$") - 1

  if line("$") > 1
    normal 2G0r>
  endif

  " Ensure the cursor is always in the first line
  let oldpos[1] = 1
  call setpos('.', oldpos)
  startinsert
endfunction

function! s:cyclenext(list, item)
  let idx = index(a:list, a:item) + 1
  return a:list[idx >= len(a:list) ? 0 : idx]
endfunction

function! FFChangeSort()
  let g:filefinder_sort = s:cyclenext(keys(g:filefinder_sortmethods), g:filefinder_sort)
  call FFRefreshContent()
endfunction

function! FFChangeFilter()
  let g:filefinder_filter =  s:cyclenext(keys(g:filefinder_filtermethods), g:filefinder_filter)
  call FFRefreshContent()
endfunction

" }}}

" Filter methods: {{{

function! FFFilterMatchWithPatterns(currentpattern, filename)
  for pattern in split(a:currentpattern, "  *")
    if match(a:filename, pattern) == -1
      return 0
    endif
  endfor
  return 1
endfunction

function! FFFilterMatchWithLetters(currentpattern, filename)
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

" }}}

" Sort methods: {{{

function! FFSortByName(a, b)
  if a:a > a:b
    return 1
  elseif a:a < a:b
    return -1
  endif
  return 0
endfunction

function! s:indexforsorting(list, item)
  let idx = index(a:list, a:item)
  return idx == -1 ? len(a:list) + 1 : idx
endfunction

function! FFSortByOldFiles(a, b)
  return s:indexforsorting(v:oldfiles, a:a) - s:indexforsorting(v:oldfiles, a:b)
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

" }}}

noremap <leader>o :call OpenFileFinder()<Cr>

" vim: fdm=marker sw=2 sts=2
