
function! FFopen()

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
  if !FFHcurrentbufferisempty()
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
  let b:prevpattern = "-"
  let b:hiddenlines = ""
  let b:resultslength = 0
  let b:marktorestorecursor = "#-#-#"

  " Root directory. The name has to finish with an slash
  if exists("g:FFrootdir")
    let b:rootdirectory = g:FFrootdir
  else
    let b:rootdirectory = getcwd()
    if b:rootdirectory[len(b:rootdirectory) - 1] != "/"
      let b:rootdirectory .= "/"
    endif
  end

  " Dialog-like buffer
  file \<File\ selector\>
  setlocal statusline=%!FFstatusline()
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
  inoremap <buffer> \\ <Esc>:call FFupdatecontent()<Cr>
  setlocal updatetime=50
  au CursorHoldI <buffer> call feedkeys(b:marktorestorecursor . "\\\\\gg0/" . b:marktorestorecursor . "\<Cr>" . len(b:marktorestorecursor) . "s")
  "au CursorHold <buffer> :bd

  " Key bindings to manage the file list
  inoremap <buffer> <Cr> <C-r>=pumvisible() ? "\<lt>Space>" : "\<lt>Esc>:call FFopenselectedfile()\<lt>Cr>"<Cr>
  inoremap <buffer> <Tab> <C-r>=FFexe("FFfixselection()")<Cr>
  inoremap <buffer> <Up> <C-r>=pumvisible() ? "\<lt>C-p>" : FFexe("FFmoveselection(-1)")<Cr>
  inoremap <buffer> <Down> <C-r>=pumvisible() ? "\<lt>C-n>" : FFexe("FFmoveselection(1)")<Cr>
  inoremap <buffer> <PageUp> <C-o>:call FFmoveselection(-winheight("."))<Cr>
  inoremap <buffer> <PageDown> <C-o>:call FFmoveselection(winheight("."))<Cr>
  inoremap <buffer> <C-a> <C-o>:2,$g/./normal 0lr>0<Cr><C-o>gg

  " Autocomplete for params
  inoremap <buffer> : :<C-r>=FFcompletecolon()<Cr>

  " With this combination we can avoid that a <Delete> at EOL joins the two
  " first lines
  inoremap <buffer> <Delete> #<Left><C-o>2x

  " Sorting and filtering
  inoremap <buffer> <C-d> <C-r>=FFexe("FFchangesort()")<Cr>
  inoremap <buffer> <C-f> <C-r>=FFexe("FFchangefilter()")<Cr>

  " Don't keep the buffer if the focus is lost or <C-c> is pressed
  inoremap <buffer> <C-c> <Esc>:bd<Cr>
  nnoremap <buffer> <C-c> :bd<Cr>
  au BufLeave <buffer> :bd
  "au InsertLeave <buffer> :bd

  " Preload the pattern, if any
  if exists("g:FFoldpattern") && g:FFoldpattern =~ "[^ ]"
    call setline(1, g:FFoldpattern)
  end

  if exists("#User#FileFinderConfigure")
    " Users can have their own definitions with the autocmd
    doautocmd User FileFinderConfigure
  endif

  call FFgeneratefilelist()

  " Time to find files!
  " Send an A command to start the insert mode at the end of the line
  " The command «normal A» does not work
  call feedkeys("A", "n")

endfunction

function! FFstatusline()
  let content = "[ "

  " Selected sort method
  let content .= "<C-d> Sort: " . get(g:FFsortmethods, g:FFsort, g:FFsort) . " | "

  " Selected filter method
  let content .= "<C-f> Filter: " . get(g:FFfiltermethods, g:FFfilter, g:FFfilter) . " ] "

  " Counters (matches / available files)
  let content .= " [" . b:resultslength . "/" . len(b:foundfiles) . "] "

  " Root directory, right aligned
  let content .= "%=" . b:rootdirectory

  return content
endfunction
