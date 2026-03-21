" Use nicer highlight colors
hi Search ctermfg=black ctermbg=228
hi CursorLine ctermbg=237
hi CursorLineNR ctermfg=39
hi CursorColumn ctermbg=238

hi diffAdded ctermfg=41
hi diffRemoved ctermfg=Red

hi diffFile cterm=NONE ctermfg=39
hi gitcommitDiff cterm=NONE ctermfg=39
hi diffIndexLine cterm=NONE ctermfg=39
hi diffLine cterm=NONE ctermfg=39

" Markdown headline highlights (vim-markdown / markdown-navigator)
execute 'highlight htmlH1 ctermfg='.accentText
execute 'highlight htmlH2 ctermfg='.primaryText
execute 'highlight htmlH3 ctermfg='.secondaryText
execute 'highlight htmlH4 ctermfg='.secondaryText
execute 'highlight htmlH5 ctermfg='.secondaryText
execute 'highlight htmlH6 ctermfg='.secondaryText

execute 'highlight MarkdownNavigatorH1 ctermfg='.accentText
execute 'highlight MarkdownNavigatorH2 ctermfg='.primaryText
execute 'highlight MarkdownNavigatorH3 ctermfg='.secondaryText
execute 'highlight MarkdownNavigatorH4 ctermfg='.secondaryText
execute 'highlight MarkdownNavigatorH5 ctermfg='.secondaryText
execute 'highlight MarkdownNavigatorH6 ctermfg='.secondaryText

" GitGutter
hi GitGutterAdd    ctermfg=2
hi GitGutterChange ctermfg=3
hi GitGutterDelete ctermfg=1

" LSP + nvim-cmp
hi CmpItemAbbrMatch ctermfg=184          " matched chars in completion popup (was CocSearch)
hi PmenuSel ctermbg=22                   " selected completion item (was CocMenuSel)
hi DiagnosticUnnecessary ctermfg=250     " unused symbols dimmed (was CocUnusedHighlight)
hi LspReferenceText ctermbg=248          " document highlight under cursor
hi LspReferenceRead ctermbg=248
hi LspReferenceWrite ctermbg=240
if dotfilesTheme =~ '-light$'
  hi LspReferenceText ctermbg=248
  hi LspReferenceRead ctermbg=248
endif

" Conflict markers (rhysd/conflict-marker.vim)
hi ConflictMarkerOurs ctermbg=23
hi ConflictMarkerTheirs ctermbg=58
hi ConflictMarkerCommonAncestorsHunk ctermbg=237

" Float windows
hi NormalFloat ctermbg=236

" Transparent background (so use terminal background)
hi Normal ctermbg=NONE
hi EndOfBuffer ctermbg=NONE
hi LineNr ctermbg=NONE
hi SignColumn ctermbg=NONE
hi Directory guibg=NONE ctermbg=NONE
