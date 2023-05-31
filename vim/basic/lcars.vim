" MIT License. 
" vim: et ts=2 sts=2 sw=2 tw=80

scriptencoding utf-8

" Airline themes are generated based on the following concepts:
"   * The section of the status line, valid Airline statusline sections are:
"       * airline_a (left most section)
"       * airline_b (section just to the right of airline_a)
"       * airline_c (section just to the right of airline_b)
"       * airline_x (first section of the right most sections)
"       * airline_y (section just to the right of airline_x)
"       * airline_z (right most section)
"   * The mode of the buffer, as reported by the :mode() function.  Airline 
"     converts the values reported by mode() to the following:
"       * normal
"       * insert
"       * replace
"       * visual
"       * inactive
"       * terminal
"       The last one is actually no real mode as returned by mode(), but used by
"       airline to style inactive statuslines (e.g. windows, where the cursor
"       currently does not reside in).
"   * In addition to each section and mode specified above, airline themes 
"     can also specify overrides.  Overrides can be provided for the following
"     scenarios:
"       * 'modified'
"       * 'paste'
"
" Airline themes are specified as a global viml dictionary using the above
" sections, modes and overrides as keys to the dictionary.  The name of the
" dictionary is significant and should be specified as:
"   * g:airline#themes#<theme_name>#palette
" where <theme_name> is substituted for the name of the theme.vim file where the
" theme definition resides.  Airline themes should reside somewhere on the
" 'runtimepath' where it will be loaded at vim startup, for example:  

" For this, the lcars.vim, theme, this is defined as
let g:airline#themes#lcars#palette = {}

" Keys in the dictionary are composed of the mode, and if specified the
" override.  For example:
"   * g:airline#themes#lcars#palette.normal 
"       * the colors for a statusline while in normal mode
"   * g:airline#themes#lcars#palette.normal_modified 
"       * the colors for a statusline while in normal mode when the buffer has
"         been modified
"   * g:airline#themes#lcars#palette.visual 
"       * the colors for a statusline while in visual mode
"
" Values for each dictionary key is an array of color values that should be
" familiar for colorscheme designers:
"   * [guifg, guibg, ctermfg, ctermbg, opts]
" See "help attr-list" for valid values for the "opt" value.
"
" Each theme must provide an array of such values for each airline section of
" the statusline (airline_a through airline_z).  A convenience function, 
" airline#themes#generate_color_map() exists to mirror airline_a/b/c to
" airline_x/y/z, respectively.

" The lcars.vim theme:
" let s:airline_a_normal   = [ '#aaaaaa' , '#444444' , 0  , 172 ]
" let s:airline_b_normal   = [ '#ffffff' , '#000000' , 0 , 179 ]
" let s:airline_c_normal   = [ '#9cffd3' , '#000000' , 222  , 238 ]
" let g:airline#themes#lcars#palette.normal = airline#themes#generate_color_map(s:airline_a_normal, s:airline_b_normal, s:airline_c_normal)

" It should be noted the above is equivalent to:
" let g:airline#themes#lcars#palette.normal = airline#themes#generate_color_map(
"    \  [ '#00005f' , '#dfff00' , 17  , 190 ],  " section airline_a
"    \  [ '#ffffff' , '#444444' , 255 , 238 ],  " section airline_b
"    \  [ '#9cffd3' , '#202020' , 85  , 234 ]   " section airline_c
"    \)
"
" In turn, that is equivalent to:
let g:airline#themes#lcars#palette.normal = {
   \  'airline_a': [ '#aaaaaa' , '#444444' , 0  , 172 ],
   \  'airline_b': [ '#ffffff' , '#000000' , 0 , 179 ],
   \  'airline_c': [ '#9cffd3' , '#000000' , 222  , 238 ],
   \  'airline_x': [ '#9cffd3' , '#000000' , 222  , 238 ],
   \  'airline_y': [ '#ffffff' , '#000000' , 0 , 179 ],
   \  'airline_z': [ '#aaaaaa' , '#444444' , 0  , 172 ] 
   \}
"
" airline#themes#generate_color_map() also uses the values provided as
" parameters to create intermediary groups such as:
"   airline_a_to_airline_b
"   airline_b_to_airline_c
"   etc...

" Here we define overrides for when the buffer is modified.  This will be
" applied after g:airline#themes#lcars#palette.normal, hence why only certain keys are
" declared.
let g:airline#themes#lcars#palette.normal_modified = {
      \ 'airline_c': [ '#ffffff' , '#5f005f' , 255     , 53      , ''     ] ,
      \ }


" let s:airline_a_insert = [ '#00005f' , '#00dfff' , 17  , 45  ]
" let s:airline_b_insert = [ '#ffffff' , '#005fff' , 255 , 27  ]
" let s:airline_c_insert = [ '#ffffff' , '#000080' , 15  , 17  ]
let g:airline#themes#lcars#palette.insert = {
   \  'airline_a': [ '#00005f' , '#00dfff' , 17  , 45  ],
   \  'airline_b': [ '#ffffff' , '#005fff' , 255 , 27  ],
   \  'airline_c': [ '#ffffff' , '#000080' , 15  , 17  ],
   \  'airline_x': [ '#ffffff' , '#000080' , 15  , 17  ],
   \  'airline_y': [ '#ffffff' , '#005fff' , 255 , 27  ],
   \  'airline_z': [ '#00005f' , '#00dfff' , 17  , 45  ] 
   \}
let g:airline#themes#lcars#palette.insert_modified = {
      \ 'airline_c': [ '#ffffff' , '#5f005f' , 255     , 53      , ''     ] ,
      \ }
let g:airline#themes#lcars#palette.insert_paste = {
      \ 'airline_a': [ '#00005f'   , '#d78700' , 17 , 172     , ''     ] ,
      \ }

" let g:airline#themes#lcars#palette.terminal = airline#themes#generate_color_map(s:airline_a_insert, s:airline_b_insert, s:airline_c_insert)

let g:airline#themes#lcars#palette.terminal = {
   \  'airline_a': [ '#00005f' , '#00dfff' , 17  , 45  ],
   \  'airline_b': [ '#ffffff' , '#005fff' , 255 , 27  ],
   \  'airline_c': [ '#ffffff' , '#000080' , 15  , 17  ],
   \  'airline_x': [ '#ffffff' , '#000080' , 15  , 17  ],
   \  'airline_y': [ '#ffffff' , '#005fff' , 255 , 27  ],
   \  'airline_z': [ '#00005f' , '#00dfff' , 17  , 45  ] 
   \}
let g:airline#themes#lcars#palette.replace = copy(g:airline#themes#lcars#palette.insert)
let g:airline#themes#lcars#palette.replace.airline_a = [ '#ffffff'   , '#af0000' ,  255 , 124     , ''     ]
let g:airline#themes#lcars#palette.replace_modified = g:airline#themes#lcars#palette.insert_modified


" let s:airline_a_visual = [ '#000000' , '#ffaf00' , 232 , 214 ]
" let s:airline_b_visual = [ '#000000' , '#ff5f00' , 232 , 202 ]
" let s:airline_c_visual = [ '#ffffff' , '#5f0000' , 15  , 52  ]
let g:airline#themes#lcars#palette.visual = {
   \  'airline_a': [ '#000000' , '#ffaf00' , 232 , 214 ],
   \  'airline_b': [ '#000000' , '#ff5f00' , 232 , 202 ],
   \  'airline_c': [ '#ffffff' , '#5f0000' , 15  , 52  ],
   \  'airline_x': [ '#ffffff' , '#5f0000' , 15  , 52  ],
   \  'airline_y': [ '#000000' , '#ff5f00' , 232 , 202 ],
   \  'airline_z': [ '#000000' , '#00dfff' , 17  , 45  ] 
   \}
let g:airline#themes#lcars#palette.visual_modified = {
      \ 'airline_c': [ '#ffffff' , '#5f005f' , 255     , 53      , ''     ] ,
      \ }


" let s:airline_a_inactive = [ '#4e4e4e' , '#1c1c1c' , 239 , 234 , '' ]
" let s:airline_b_inactive = [ '#4e4e4e' , '#262626' , 239 , 235 , '' ]
" let s:airline_c_inactive = [ '#4e4e4e' , '#303030' , 239 , 236 , '' ]
let g:airline#themes#lcars#palette.inactive = {
   \  'airline_a': [ '#4e4e4e' , '#1c1c1c' , 239 , 234 , '' ],
   \  'airline_b': [ '#4e4e4e' , '#262626' , 239 , 235 , '' ],
   \  'airline_c': [ '#4e4e4e' , '#303030' , 239 , 236 , '' ],
   \  'airline_x': [ '#4e4e4e' , '#303030' , 239 , 236 , '' ],
   \  'airline_y': [ '#4e4e4e' , '#262626' , 239 , 235 , '' ],
   \  'airline_z': [ '#4e4e4e' , '#1c1c1c' , 239 , 234 , '' ] 
   \}
let g:airline#themes#lcars#palette.inactive_modified = {
      \ 'airline_c': [ '#875faf' , '' , 97 , '' , '' ] ,
      \ }

" For commandline mode, we use the colors from normal mode, except the mode
" indicator should be colored differently, e.g. light green
" let s:airline_a_commandline = [ '#00005f' , '#00d700' , 17  , 40 ]
" let s:airline_b_commandline = [ '#ffffff' , '#444444' , 255 , 238 ]
" let s:airline_c_commandline = [ '#9cffd3' , '#202020' , 85  , 234 ]
let g:airline#themes#lcars#palette.commandline = {
   \  'airline_a': [ '#00005f' , '#00d700' , 17  , 40 ],
   \  'airline_b': [ '#ffffff' , '#444444' , 255 , 238 ],
   \  'airline_c': [ '#9cffd3' , '#202020' , 85  , 234 ],
   \  'airline_x': [ '#9cffd3' , '#202020' , 85  , 234 ],
   \  'airline_y': [ '#ffffff' , '#444444' , 255 , 238 ],
   \  'airline_z': [ '#00005f' , '#00d700' , 17  , 40 ] 
   \}

" Accents are used to give parts within a section a slightly different look or
" color. Here we are defining a "red" accent, which is used by the 'readonly'
" part by default. Only the foreground colors are specified, so the background
" colors are automatically extracted from the underlying section colors. What
" this means is that regardless of which section the part is defined in, it
" will be red instead of the section's foreground color. You can also have
" multiple parts with accents within a section.
let g:airline#themes#lcars#palette.accents = {
      \ 'red': [ '#ff0000' , '' , 160 , ''  ]
      \ }


" Here we define the color map for ctrlp.  We check for the g:loaded_ctrlp
" variable so that related functionality is loaded if the user is using
" ctrlp. Note that this is optional, and if you do not define ctrlp colors
" they will be chosen automatically from the existing palette.
if get(g:, 'loaded_ctrlp', 0)
  let g:airline#themes#lcars#palette.ctrlp = airline#extensions#ctrlp#generate_color_map(
        \ [ '#d7d7ff' , '#5f00af' , 189 , 55  , ''     ],
        \ [ '#ffffff' , '#875fd7' , 231 , 98  , ''     ],
        \ [ '#5f00af' , '#ffffff' , 55  , 231 , 'bold' ])
endif

