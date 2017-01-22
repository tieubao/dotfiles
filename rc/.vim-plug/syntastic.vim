"-----------------------------------------------------------------------------
" Syntastic
"-----------------------------------------------------------------------------
let g:syntastic_error_symbol             = '✘'
let g:syntastic_warning_symbol           = '✘'
let g:syntastic_style_error_symbol       = '≋'
let g:syntastic_style_warning_symbol     = '≈'
let g:syntastic_go_checkers              = ['golint', 'govet', 'errcheck']                       " use golint for syntax checking in Go
let g:syntastic_javascript_checkers      = ['eslint']
let g:syntastic_loc_list_height          = 5                                 " set error window height to 5
let g:syntastic_always_populate_loc_list = 1                        " stick errors into a location-list
let g:syntastic_auto_loc_list            = 1
let g:syntastic_html_tidy_exec           = 'tidy5'
let g:syntastic_html_tidy_ignore_errors  = [" proprietary attribute " ,"trimming empty <", "unescaped &" , "lacks \"action", "is not recognized!", "discarding unexpected"]

let g:syntastic_enable_elixir_checker = 1
let g:syntastic_elixir_checkers = ['elixir']
let g:syntastic_swift_checkers = ['swiftpm', 'swiftlint']

" Press Ctrl-w + Shift-e to toggle syntastic
" let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],'passive_filetypes': ['go'] }
nnoremap <C-w>E :SyntasticCheck<CR> :SyntasticToggleMode<CR>

" Open error panel: http://stackoverflow.com/a/17515778
function! ToggleErrors()
    let old_last_winnr = winnr('$')
    lclose
    if old_last_winnr == winnr('$')
        " Nothing was closed, open syntastic error location panel
        Errors
    endif
endfunction
nnoremap <silent> <C-e> :<C-u>call ToggleErrors()<CR>
