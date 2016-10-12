"  ---------------------------------------------------------------------------
"  NERDTree
"  ---------------------------------------------------------------------------
" auto open NERDTree when start
autocmd VimEnter * NERDTree
autocmd BufEnter * NERDTreeMirror
autocmd VimEnter * wincmd p
map <Leader>n <plug>NERDTreeTabsToggle<CR>

let g:nerdtree_tabs_open_on_console_startup=1
let g:nerdtree_tabs_open_on_gui_startup=1
let g:nerdtree_tabs_open_on_new_tab=1

let g:NERDCreateDefaultMappings=1
let g:NERDSpaceDelims=1
let g:NERDShutUp=1
let g:NERDTreeHijackNetrw=0

map <F1> :call NERDTreeToggleAndFind()<cr>
map <F2> :NERDTreeToggle<CR>
map <Leader>nt :NERDTreeToggle<CR>
let NERDTreeShowHidden=1

let g:NERDTreeMinimalUI=1
let g:NERDTreeHijackNetrw = 0
let g:NERDTreeWinSize = 31
let g:NERDTreeChDirMode = 2
let g:NERDTreeAutoDeleteBuffer = 1
let g:NERDTreeShowBookmarks = 1
let g:NERDTreeCascadeOpenSingleChildDir = 1

function! NERDTreeToggleAndFind()
    if (exists('t:NERDTreeBufName') && bufwinnr(t:NERDTreeBufName) != -1)
        execute ':NERDTreeClose'
    else
        execute ':NERDTreeFind'
    endif
endfunction
