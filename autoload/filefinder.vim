" Vim File Finder
" Maintainer:  Ayose Cazorla <ayosec@gmail.com>
" Last Change: 2011 Dec 10


exe "command! -nargs=1 FileFinderPart source " . expand("<sfile>:h") . "/../lib/<args>.vim"

" Code is located in the <root>/lib directory

FileFinderPart globals
FileFinderPart helpers
FileFinderPart builder
FileFinderPart autocompl
FileFinderPart filelist
FileFinderPart selection
FileFinderPart filter
FileFinderPart sort

"delcommand FileFinderPart

function! filefinder#open()
  call FFopen()
endfunction

" vim: sw=2 sts=2
