"-----------------------------------------------------------------------------
" FZF
"-----------------------------------------------------------------------------
" This is the default extra key bindings
let g:fzf_action = {
            \ 'ctrl-t': 'tab split',
            \ 'ctrl-x': 'split',
            \ 'ctrl-v': 'vsplit' }

nnoremap <c-p> :FZF -m<cr>

let g:fzf_layout = { 'down': '20%' }
let g:fzf_height = '20%'

" For Commits and BCommits to customize the options used by 'git log':
let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'

" Advanced customization using autoload functions
autocmd VimEnter * command! Colors
            \ call fzf#vim#colors({'left': '20%', 'options': '--reverse --margin 30%,0'})

" Mapping selecting mappings
nmap <leader><tab> <plug>(fzf-maps-n)
xmap <leader><tab> <plug>(fzf-maps-x)
omap <leader><tab> <plug>(fzf-maps-o)

" Insert mode completion
" imap <c-x><c-f> <plug>(fzf-complete-path)

imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-l> <plug>(fzf-complete-line)

" Use fuzzy completion relative filepaths across directory
imap <expr> <c-x><c-f> fzf#vim#complete#path('git ls-files $(git rev-parse --show-toplevel)')

" Advanced customization using autoload functions
" inoremap <expr> <c-x><c-k> fzf#vim#complete#word({'left': '15%'})

" Open FZF in new tab
nnoremap <silent> <leader>fe :call fzf#run({'sink': 'tabe'})<CR>

" Tag related
command! -bar FZFTags if !empty(tagfiles()) |
            \ call fzf#run({
            \   'source': 'sed ''/^\\!/ d; s/^\([^\t]*\)\t.*\t\(\w\)\(\t.*\)\?/\2\t\1/; /^l/ d'' ' . join(tagfiles()) . ' | uniq',
            \   'sink': function('<SID>tag_line_handler'),
            \ }) | else | call MakeTags() | FZFTags | endif

command! FZFTagsBuffer call fzf#run({
            \   'source': 'ctags -f - --sort=no ' . bufname("") . ' | sed ''s/^\([^\t]*\)\t.*\t\(\w\)\(\t.*\)\?/\2\t\1/'' | sort -k 1.1,1.1 -s',
            \   'sink': function('<SID>tag_line_handler'),
            \   'options': '--tac',
            \ })

function! s:tag_line_handler(l)
    let keys = split(a:l, '\t')
    exec 'tag' keys[1]
endfunction

function! MakeTags()
    echo 'Preparing tags...'
    call system('ctags -R')
    echo 'Tags done'
endfunction

let g:fzf_nvim_statusline = 0 " disable statusline overwriting

" Advanced mapping
nnoremap <silent> <leader><space> :Files<CR>
nnoremap <silent> <leader>a :Buffers<CR>
nnoremap <silent> <leader>A :Windows<CR>
nnoremap <silent> <leader>; :BLines<CR>
nnoremap <silent> <leader>. :Lines<CR>
nnoremap <silent> <leader>o :BTags<CR>
nnoremap <silent> <leader>O :Tags<CR>
nnoremap <silent> <leader>? :History<CR>
nnoremap <silent> <leader>/ :execute 'Ag ' . input('Ag/')<CR>
nnoremap <silent> K :call SearchWordWithAg()<CR>
vnoremap <silent> K :call SearchVisualSelectionWithAg()<CR>
nnoremap <silent> <leader>gl :Commits<CR>
nnoremap <silent> <leader>ga :BCommits<CR>
nnoremap <silent> <leader>ft :Filetypes<CR>

fun! s:fzf_root()
	let path = finddir(".git", expand("%:p:h").";")
	return fnamemodify(substitute(path, ".git", "", ""), ":p:h")
endfun

nnoremap <silent> <Leader>ff :exe 'Files ' . <SID>fzf_root()<CR>

function! SearchWordWithAg()
    execute 'Ag' expand('<cword>')
endfunction

function! SearchVisualSelectionWithAg() range
    let old_reg = getreg('"')
    let old_regtype = getregtype('"')
    let old_clipboard = &clipboard
    set clipboard&
    normal! ""gvy
    let selection = getreg('"')
    call setreg('"', old_reg, old_regtype)
    let &clipboard = old_clipboard
    execute 'Ag' selection
endfunction

" Search Buffer
function! s:buflist()
    redir => ls
    silent ls
    redir END
    return split(ls, '\n')
endfunction

function! s:bufopen(e)
    execute 'buffer' matchstr(a:e, '^[ 0-9]*')
endfunction

nnoremap <silent> <Leader><Enter> :call fzf#run({
            \   'source':  reverse(<sid>buflist()),
            \   'sink':    function('<sid>bufopen'),
            \   'options': '+m',
            \   'down':    len(<sid>buflist()) + 2
            \ })<CR>
