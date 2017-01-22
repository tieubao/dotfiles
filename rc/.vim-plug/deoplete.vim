"-----------------------------------------------------------------------------
" Deoplete
"-----------------------------------------------------------------------------

if has('nvim') && has('python3')
    let g:deoplete#enable_at_startup = 1
    let g:deoplete#enable_smart_case = 1
    let g:deoplete#auto_complete_start_length = 1

    let g:deoplete#keyword_patterns = {}
    let g:deoplete#keyword_patterns._ = '[a-zA-Z_]\k*\(?'

    let g:deoplete#tag#cache_limit_size = 5000000

    let g:deoplete#auto_complete_delay = 50

    " neocomplete like
    set completeopt+=noinsert

    " deoplete.nvim recommend
    set completeopt+=noselect

    " <TAB>: completion.
    " inoremap <expr><tab> pumvisible() ? "\<C-n>" : "\<TAB>"
    " inoremap <expr><s-tab> pumvisible() ? "\<C-p>" : "\<TAB>"

    " <C-h>, <BS>: close popup and delete backword char.
    inoremap <expr><C-h> deoplete#smart_close_popup()."\<C-h>"
    inoremap <expr><BS> deoplete#smart_close_popup()."\<C-h>"

    " deoplete-go settings
    let g:deoplete#sources#go#gocode_binary = $GOPATH.'/bin/gocode'
    let g:deoplete#sources#go#sort_class = ['package', 'func', 'type', 'var', 'const']
    let g:deoplete#sources#go#use_cache = 1
    let g:deoplete#sources#go#json_directory = '~/.cache/deoplete/go/$GOOS_$GOARCH'

endif
