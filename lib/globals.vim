
if !exists("g:FFsort")
  let g:FFsort = "FFsortbyoldfiles"
endif

if !exists("g:FFfilter")
  let g:FFfilter = "FFfiltermatchwithpatterns"
endif

if !exists("g:FFsortmethods")
  let g:FFsortmethods = {}
  let g:FFsortmethods['FFsortbyname'] = 'Name'
  let g:FFsortmethods['FFsortbymtime'] = 'Mod time'
  let g:FFsortmethods['FFsortbyoldfiles'] = 'Last access'
endif

if !exists("g:FFfiltermethods")
  let g:FFfiltermethods = {}
  let g:FFfiltermethods["FFfiltermatchwithletters"] = "Letters"
  let g:FFfiltermethods["FFfiltermatchwithpatterns"] = "Patterns"
endif
