"  ---------------------------------------------------------------------------
"  Golang customizations
"  ---------------------------------------------------------------------------
let g:go_fmt_command = "goimports"
au FileType go nmap <leader>g :! go test .<CR>
let g:go_bin_path = expand("$GOBIN")

" Syntax Highlighting for Golang
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:godef_same_file_in_same_window=1                              " when in go, just move the cursor if in same file
" let g:godef_split=0

let g:go_list_type = "quickfix"

let g:go_dispatch_enabled = 1

au BufRead,BufNewFile *.go set filetype=go
autocmd FileType go setlocal shiftwidth=8 tabstop=8 softtabstop=8   " set tabstop to 8 for go files
autocmd FileType go setlocal noexpandtab                            " don't expand tabs to spaces for go files

" Go keymaps
" Type Info
au FileType go nmap <Leader>i <Plug>(go-info)
au FileType go nmap <Leader>s <Plug>(go-implements)

" GoDoc
au FileType go nmap <Leader>gd <Plug>(go-doc)
au Filetype go nmap <Leader>gv <Plug>(go-doc-vertical)
au FileType go nmap <Leader>gb <Plug>(go-doc-browser)

" Build/Run/Test
au FileType go nmap <Leader>r <Plug>(go-run)
au FileType go nmap <Leader>b <Plug>(go-build)
au FileType go nmap <Leader>t <Plug>(go-test)

" GoDef
au FileType go nmap gd <Plug>(go-def)
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>dt <Plug>(go-def-tab)

if has('nvim') && has('python3')
    au FileType go nmap <leader>rt <Plug>(go-run-tab)
    au FileType go nmap <Leader>rs <Plug>(go-run-split)
    au FileType go nmap <Leader>rv <Plug>(go-run-vertical)

    " let g:go_term_mode = 'split'
    " let g:go_term_enabled = 1
endif
