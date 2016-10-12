"-----------------------------------------------------------------------------
" Vim Tmux Navigator
"-----------------------------------------------------------------------------
" let g:tmux_navigator_no_mappings = 1

nnoremap <Leader><Up> :exe "resize " . (winheight(0) * 11/10)<CR>
nnoremap <Leader><Down> :exe "resize " . (winheight(0) * 10/11)<CR>
nnoremap <Leader><Left> :exe "vertical resize " . (winwidth(0) * 10/11)<CR>
nnoremap <Leader><Right> :exe "vertical resize " . (winwidth(0) * 11/10)<CR>

" For tmux-complete
let g:tmuxcomplete#trigger = ''

