" Vim File Finder
" Maintainer:  Ayose Cazorla <ayosec@gmail.com>
" Last Change: 2011 Nov 30

" Global variables: {{{

if !exists("g:filefinder#sort")
  let g:filefinder#sort = "filefinder#sortbyoldfiles"
endif

if !exists("g:filefinder#filter")
  let g:filefinder#filter = "filefinder#filtermatchwithpatterns"
endif

if !exists("g:filefinder#sortmethods")
  let g:filefinder#sortmethods = {}
  let g:filefinder#sortmethods['filefinder#sortbyname'] = 'Name'
  let g:filefinder#sortmethods['filefinder#sortbymtime'] = 'Mod time'
  let g:filefinder#sortmethods['filefinder#sortbyoldfiles'] = 'Last access'
endif

if !exists("g:filefinder#filtermethods")
  let g:filefinder#filtermethods = {}
  let g:filefinder#filtermethods["filefinder#filtermatchwithletters"] = "Letters"
  let g:filefinder#filtermethods["filefinder#filtermatchwithpatterns"] = "Patterns"
endif

" }}}

" Main function: {{{

function! s:currentbufferisempty()
  return empty(bufname("%")) && !getbufvar("%", "&modified")
endfunction

function! filefinder#open()

  " The most-recent-access is built with the current buffers and the v:oldfiles (marks)
  " We have to create this list before create the new tab
  let l:recentfiles = []
  call add(l:recentfiles, expand('%:p'))
  call add(l:recentfiles, expand('#:p'))
  for l:i in range(bufnr("$"))
    let bufpath = expand('#' . l:i . ':p')
    if !empty(bufpath)
      call add(l:recentfiles, bufpath)
    endif
  endfor

  " Append the v:oldfiles to our list of open files
  call extend(l:recentfiles, v:oldfiles)

  " Reuse the current buffer if it is empty. If not, create a new tab
  if !s:currentbufferisempty()
    tabnew
  endif

  " Save some options that doesn't obey the setlocal command
  " When the buffer is closing restore the old values
  let b:oldupdatetime = &updatetime
  let b:oldlaststatus = &laststatus
  let b:oldlazyredraw = &lazyredraw

  au BufLeave <buffer> let &updatetime = b:oldupdatetime
  au BufLeave <buffer> let &laststatus = b:oldlaststatus
  au BufLeave <buffer> let &lazyredraw = b:oldlazyredraw


  " Save our list in a variable buffer (once the new buffer (tabnew) is created)
  let b:recentfiles = l:recentfiles

  " State
  let b:prevpattern = ""
  let b:hiddenlines = ""
  let b:resultslength = 0

  " Root directory. The name has to finish with an slash
  if exists("g:filefinder#rootdir")
    let b:rootdirectory = g:filefinder#rootdir
  else
    let b:rootdirectory = getcwd()
    if b:rootdirectory[len(b:rootdirectory) - 1] != "/"
      let b:rootdirectory .= "/"
    endif
  end

  " Dialog-like buffer
  file \<File\ selector\>
  setlocal statusline=%!filefinder#statusline()
  setlocal laststatus=2
  setlocal lazyredraw
  setlocal buftype=nowrite
  setlocal bufhidden=delete
  setlocal noswapfile
  setlocal ignorecase

  " Colors
  setlocal cursorline
  syn region SelectedFile start='^>' end='$'
  syn region FixedSelection start='^ >' end='$'
  syn region ErrorMessage start='^!' end='$'
  syn region OpenFile start='^ +' end='$'
  hi CursorLine cterm=none ctermbg=darkgray ctermfg=white guibg=darkgray guifg=white
  hi SelectedFile cterm=none ctermbg=blue ctermfg=white guibg=blue guifg=white
  hi FixedSelection cterm=none ctermbg=lightblue ctermfg=black guibg=lightblue guifg=black
  hi def link OpenFile Identifier
  hi def link ErrorMessage Error

  " Timer to update the file list.
  " The timer is a trick using the CursorHoldI event and a fake key combination
  inoremap <buffer> \\ <C-o>:call filefinder#updatecontent()<Cr>
  setlocal updatetime=50
  au CursorHoldI <buffer> call feedkeys("\\\\")
  "au CursorHold <buffer> :bd

  " Key bindings to manage the file list
  inoremap <buffer> <Cr> <Esc>:call filefinder#openselectedfile()<Cr>
  inoremap <buffer> <Tab> <C-o>:call filefinder#fixselection()<Cr>
  inoremap <buffer> <Up> <C-o>:call filefinder#moveselection(-1)<Cr>
  inoremap <buffer> <Down> <C-o>:call filefinder#moveselection(1)<Cr>
  inoremap <buffer> <PageUp> <C-o>:call filefinder#moveselection(-winheight("."))<Cr>
  inoremap <buffer> <PageDown> <C-o>:call filefinder#moveselection(winheight("."))<Cr>
  inoremap <buffer> <C-a> <C-o>:2,$g/./normal 0lr>0<Cr>

  nnoremap <buffer> <Cr> :call filefinder#openselectedfile()<Cr>
  nnoremap <buffer> <Tab> :call filefinder#fixselection()<Cr>
  nnoremap <buffer> <Up> :call filefinder#moveselection(-1)<Cr>
  nnoremap <buffer> <Down> :call filefinder#moveselection(1)<Cr>
  nnoremap <buffer> <PageUp> :call filefinder#moveselection(-winheight("."))<Cr>
  nnoremap <buffer> <PageDown> :call filefinder#moveselection(winheight("."))<Cr>
  nnoremap <buffer> <C-a> :2,$g/./normal 0lr>0<Cr>

  " Sorting and filtering
  inoremap <buffer> <C-d> <C-o>:call filefinder#changesort()<Cr>
  inoremap <buffer> <C-f> <C-o>:call filefinder#changefilter()<Cr>

  " Don't keep the buffer if the focus is lost or <C-c> is pressed
  inoremap <buffer> <C-c> <Esc>:bd<Cr>
  nnoremap <buffer> <C-c> :bd<Cr>
  au BufLeave <buffer> :bd
  "au InsertLeave <buffer> :bd

  " Preload the pattern, if any
  " Append blank spaces to the EOL to make easier to restore the cursor
  " position after update the buffer content
  if exists("g:filefinder#oldpattern") && g:filefinder#oldpattern =~ "[^ ]"
    call setline(1, g:filefinder#oldpattern . "    ")
    normal $BEl
  else
    call setline(1, "    ")
    normal 0
  end


  if exists("#User#FileFinderConfigure")
    " Users can have their own definitions with the autocmd
    doautocmd User FileFinderConfigure
  endif

  call filefinder#generatefilelist()

  " Time to find files!
  startinsert

endfunction

" }}}

" UI: {{{

function! filefinder#statusline()
  let content = "[ "

  " Selected sort method
  let content .= "<C-d> Sort: " . get(g:filefinder#sortmethods, g:filefinder#sort, g:filefinder#sort) . " | "

  " Selected filter method
  let content .= "<C-f> Filter: " . get(g:filefinder#filtermethods, g:filefinder#filter, g:filefinder#filter) . " ] "

  " Counters (matches / available files)
  let content .= " [" . b:resultslength . "/" . len(b:foundfiles) . "] "

  " Root directory, right aligned
  let content .= "%=" . b:rootdirectory

  return content
endfunction

function! filefinder#generatefilelist()
  " Generate file list. Exclude directories.
  " Use wildignore to exclude files
  let b:foundfiles = []

  " Sort them
  let l:files = split(globpath(b:rootdirectory, "**"), "\n")
  call sort(files, g:filefinder#sort)

  for item in l:files
    if isdirectory(item) == 0
      if stridx(item, b:rootdirectory) == 0
        let item = strpart(item, len(b:rootdirectory))
      endif
      call add(b:foundfiles, item)
    endif
  endfor
endfunction

function! filefinder#refreshcontent()
  let b:prevpattern = ""

  call filefinder#generatefilelist()
  call filefinder#updatecontent()
endfunction

function! filefinder#openselectedfile()

  let l:rootdirectory = b:rootdirectory

  " Save current pattern
  1s/ *$//
  let g:filefinder#oldpattern = getline(1)

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
      exe (s:currentbufferisempty() ? 'e ' : 'tabnew ') . fnameescape(fnamemodify(path, ':.'))
    end
  endfor
endfunction

function! filefinder#fixselection()
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

function! filefinder#moveselection(offset)
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

function! filefinder#updatecontent()

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
      if {g:filefinder#filter}(l:currentpattern, item)
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

function! s:cyclenext(list, item)
  let idx = index(a:list, a:item) + 1
  return a:list[idx >= len(a:list) ? 0 : idx]
endfunction

function! filefinder#changesort()
  let g:filefinder#sort = s:cyclenext(keys(g:filefinder#sortmethods), g:filefinder#sort)
  call filefinder#refreshcontent()
endfunction

function! filefinder#changefilter()
  let g:filefinder#filter =  s:cyclenext(keys(g:filefinder#filtermethods), g:filefinder#filter)
  call filefinder#refreshcontent()
endfunction

" }}}

" Filter methods: {{{

function! filefinder#filtermatchwithpatterns(currentpattern, filename)
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

function! g:filefinder_match_limit(filename, argument)
  if(line("$") > a:argument)
    throw "STOP"
  endif
  return 1
endfunction

function! filefinder#filtermatchwithletters(currentpattern, filename)
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

function! filefinder#sortbyname(a, b)
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

function! filefinder#sortbyoldfiles(a, b)
  return s:indexforsorting(b:recentfiles, a:a) - s:indexforsorting(b:recentfiles, a:b)
endfunction

function! filefinder#sortbymtime(a, b)
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

" vim: fdm=marker sw=2 sts=2
