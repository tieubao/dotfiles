set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'

Plugin 'L9'
Plugin 'git://git.wincent.com/command-t.git'
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
Plugin 'tpope/vim-git'
Plugin 'tpope/vim-fugitive'

Bundle 'fatih/molokai'
Bundle 'altercation/vim-colors-solarized'

Bundle 'Shougo/neocomplete.vim'
Bundle 'majutsushi/tagbar'
Bundle 'SirVer/ultisnips'
Bundle 'honza/vim-snippets'
Bundle 'myusuf3/numbers.vim'
Bundle 'terryma/vim-multiple-cursors'
Plugin 'bling/vim-airline'
Plugin 'itchyny/lightline.vim'

Plugin 'airblade/vim-gitgutter'

Plugin 'edkolev/tmuxline.vim'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'benmills/vimux'
Plugin 'benmills/vimux-golang'
Bundle 'godlygeek/tabular'
Bundle 'kchmck/vim-coffee-script'
Bundle 'elzr/vim-json'
Bundle 'Yggdroot/indentLine'

Bundle 'tienle/vim-itermux'
Bundle "pangloss/vim-javascript"
Bundle 'maksimr/vim-jsbeautify'

Bundle 'vim-scripts/greplace.vim'
Bundle 'vim-scripts/globalreplace.vim'
Bundle 'vim-scripts/tinymode.vim'
Bundle 'tpope/vim-surround'
Bundle 'scrooloose/syntastic'

" very nice file browser
Bundle 'scrooloose/nerdtree'
Bundle 'Xuyuanp/nerdtree-git-plugin'
Bundle 'scrooloose/nerdcommenter'
Bundle 'jistr/vim-nerdtree-tabs'
Plugin 'tyok/nerdtree-ack'

" some markdown support
Bundle 'https://github.com/plasticboy/vim-markdown.git'

" full path fuzzy search
Bundle 'kien/ctrlp.vim'
Bundle 'tacahiroy/ctrlp-funky'
Bundle 'jasoncodes/ctrlp-modified.vim'
Bundle 'garyburd/go-explorer'

" jump around documents
Bundle 'Lokaltog/vim-easymotion'

" prereq for FuzzyFinder
Bundle 'FuzzyFinder'

" Edit encrypted files
Bundle 'openssl.vim'

" ack.vim / the_silver_searcher integration
Bundle 'mileszs/ack.vim'
Bundle 'dyng/ctrlsf.vim'

" Bundle 'severin-lemaignan/vim-minimap'
" Bundle 'ryanoasis/vim-webdevicons'

Bundle 'Blackrush/vim-gocode'
" Bundle 'dgryski/vim-godef'
Bundle 'fatih/vim-go'
Plugin 'ap/vim-css-color'
Plugin 'JulesWang/css.vim' " only necessary if your Vim version < 7.4
Plugin 'cakebaker/scss-syntax.vim'
Plugin 'othree/html5.vim'
Plugin 'nginx.vim'
Plugin 'guileen/vim-node'
Plugin 'myhere/vim-nodejs-complete'


" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

"-----------------------------------------------------------------------------
" Colors/ Theme
"-----------------------------------------------------------------------------
if !has("gui_running")
    set t_Co=256
    if !has('mac')
        set term=xterm-256color
    endif
endif

syntax enable

set background=dark
let g:solarized_termcolors=256
let g:solarized_contrast='high'
" let g:solarized_visibility='high'
" let g:solarized_visibility='medium'
let g:solarized_termtrans=1
colorscheme solarized

if has("syntax")
    syntax on
endif

set hls                               " Highlighting search result

"-----------------------------------------------------------------------------
" Mapping keys
"-----------------------------------------------------------------------------
" remap Leader to , instead of \
let mapleader = ","

" format the entire file
map === mmgg=G`m^zz

"a trick for sudo save
cmap w!! w !sudo tee % >/dev/null

"Ctrl + S to save
map <C-s> :w<CR>
imap <C-s> <Esc>:w<CR>

"Ctrl + Space to auto complete on local buff
imap <C-Space> <C-P>



nmap <Leader>] >>
nmap <Leader>[ <<
vmap <Leader>[ <gv
vmap <Leader>] >gv

map <Leader>1 1gt
map <Leader>2 2gt
map <Leader>3 3gt
map <Leader>4 4gt
map <Leader>5 5gt
map <Leader>6 6gt
map <Leader>7 7gt
map <Leader>8 8gt
map <Leader>9 9gt

" until we have default MacVim shortcuts this is the only way to use it in
" insert mode
imap <Leader>1 <esc>1gt
imap <Leader>2 <esc>2gt
imap <Leader>3 <esc>3gt
imap <Leader>4 <esc>4gt
imap <Leader>5 <esc>5gt
imap <Leader>6 <esc>6gt
imap <Leader>7 <esc>7gt
imap <Leader>8 <esc>8gt
imap <Leader>9 <esc>9gt

let g:go_disable_autoinstall = 0
let g:molokai_original = 1
"-----------------------------------------------------------------------------
" Text formatting
"-----------------------------------------------------------------------------

set laststatus=2
set tabstop=4
set softtabstop=4
set shiftwidth=4
set textwidth=0
set smarttab
set expandtab
set smartindent
" set relativenumber
set ttyfast
set autoread
set more
set cursorline!
set splitright                  " Split vertical windows right to the current windows
set splitbelow                  " Split horizontal windows below to the current windows

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

" Smart way to move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Move a line of text using ALT+[jk] or Comamnd+[jk] on mac
nmap <M-j> mz:m+<cr>`z
nmap <M-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

if has("mac") || has("macunix")
    nmap <D-j> <M-j>
    nmap <D-k> <M-k>
    vmap <D-j> <M-j>
    vmap <D-k> <M-k>
endif

func! DeleteTrailingWS()
    exe "normal mz"
    %s/\s\+$//ge
    exe "normal `z"
endfunc
autocmd BufWrite *.py :call DeleteTrailingWS()
autocmd BufWrite *.coffee :call DeleteTrailingWS()

" Visualize tabs, trailing whitespaces and funny characters
" http://www.reddit.com/r/programming/comments/9wlb7/proggitors_do_you_like_the_idea_of_indented/c0esam1
" https://wincent.com/blog/making-vim-highlight-suspicious-characters
" set list
" set listchars=nbsp:¬,tab:»·,trail:·

set foldmethod=syntax
set foldnestmax=10
set nofoldenable                        "don't fold by default
set foldlevel=1
set clipboard+=unnamed                  " yanks go on clipboard instead
set cinoptions=:0,p0,t0
set cinwords=if,else,while,do,for,switch,case
set cindent

"-----------------------------------------------------------------------------
" Backup
"-----------------------------------------------------------------------------
set nobackup
set nowritebackup
set noswapfile
set backupdir=~/tmp,/tmp
set backupcopy=yes
set backupskip=/tmp/*,$TMPDIR/*,$TMP/*,$TEMP/*
set directory=/tmp

"-----------------------------------------------------------------------------
" UI
"-----------------------------------------------------------------------------
set ruler                             " show cursor position all the time
set nolazyredraw
set number                            " set line number on
set ch=1                              " command line height
set backspace=indent,eol,start        " backspace through everything in insert mode
set report=0                          " tell us about changes
set guioptions=aegitcm
"win 180 50
set mousehide                         " hide mouse after chars typed
set mouse+=a                           " mouse in all modes
set ttymouse=xterm

"tmux knows extended mouse mode
if &term =~ '^screen'
  set ttymouse=xterm2
endif

" No annoying sound on errors
set noerrorbells
set novisualbell
set timeoutlen=500

set showmode
set showcmd
set autowrite
set autoread


"-----------------------------------------------------------------------------
" Visual cues
"-----------------------------------------------------------------------------
" set paste
set showmatch
set incsearch
set magic
set ignorecase                        " case insensitive search
set mat=5                             " bracket blinking
" set novisualbell                      " no blinking
set visualbell
set t_vb=

" Starting from vim 7.3 undo can be persisted across sessions
" http://www.reddit.com/r/vim/comments/kz84u/what_are_some_simple_yet_mindblowing_tweaks_to/c2onmqe
if has("persistent_undo")
    set undodir=~/.vim/undodir
    set undofile
endif

highlight ExtraWhitespace ctermbg=yellow guibg=yellow
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

autocmd BufWritePre * :%s/\s\+$//e

"-----------------------------------------------------------------------------
"set wildmode=list:longest

set wildmenu                "enable ctrl-n and ctrl-p to scroll thru matches
set wildignore=*.o,*.obj,*~ "stuff to ignore when tab completing
set wildignore+=*vim/backups*
set wildignore+=*sass-cache*
set wildignore+=*DS_Store*
set wildignore+=vendor/rails/**
set wildignore+=vendor/cache/**
set wildignore+=*.gem
set wildignore+=log/**
set wildignore+=tmp/**
set wildignore+=*.png,*.jpg,*.gif
set wildignore+=*node_modules*
set wildignore+=*/bower_components/*.so,*.swp,*.zip
set wildignore+=*/.git/*,*/.idea/*

set scrolloff=5         "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=1

"  ---------------------------------------------------------------------------
"  Easymotion
"  ---------------------------------------------------------------------------
let g:EasyMotion_leader_key = '\'
let g:EasyMotion_mapping_f  = '<Leader>m'
let g:EasyMotion_keys       = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
let g:EasyMotion_do_shade   = 0


"  ---------------------------------------------------------------------------
"  When vimrc, either directly or via symlink, is edited, automatically reload it
"  ---------------------------------------------------------------------------
autocmd! bufwritepost .vimrc source %
autocmd! bufwritepost vimrc source %


"  ---------------------------------------------------------------------------
"  Other files to consider Ruby
"  ---------------------------------------------------------------------------
au BufRead,BufNewFile Gemfile,Rakefile,Thorfile,config.ru,Vagrantfile,Guardfile,Capfile set ft=ruby


"  ---------------------------------------------------------------------------
"  CoffeeScript
"  ---------------------------------------------------------------------------

let coffee_compile_vert = 1
au BufNewFile,BufReadPost *.coffee setl foldmethod=indent

"  ---------------------------------------------------------------------------
"  SASS / SCSS
"  ---------------------------------------------------------------------------

au BufNewFile,BufReadPost *.scss setl foldmethod=indent
au BufNewFile,BufReadPost *.sass setl foldmethod=indent
au BufRead,BufNewFile *.scss set filetype=scss

"-----------------------------------------------------------------------------
" Auto commands
"-----------------------------------------------------------------------------
" Edit .vimrc
au! BufRead,BufNewFile *.haml setfiletype haml
au! BufRead,BufNewFile *.hamlc setfiletype haml
au! BufRead,BufNewFile *.rabl setfiletype ruby

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

map <F2> :NERDTreeToggle<CR>
map <Leader>nt :NERDTreeToggle<CR>
let NERDTreeShowHidden=1

"-----------------------------------------------------------------------------
" NeoComplete
"-----------------------------------------------------------------------------

let g:neocomplete#enable_at_startup = 1

" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
            \ 'default' : '',
            \ 'vimshell' : $HOME.'/.vimshell_hist',
            \ 'scheme' : $HOME.'/.gosh_completions'
            \ }

" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
    " return neocomplete#close_popup() . "\<CR>"
    " For no inserting <CR> key.
    return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplete#close_popup()
inoremap <expr><C-e>  neocomplete#cancel_popup()
" Close popup by <Space>.
"inoremap <expr><Space> pumvisible() ? neocomplete#close_popup() : "\<Space>"

" For cursor moving in insert mode(Not recommended)
"inoremap <expr><Left>  neocomplete#close_popup() . "\<Left>"
"inoremap <expr><Right> neocomplete#close_popup() . "\<Right>"
"inoremap <expr><Up>    neocomplete#close_popup() . "\<Up>"
"inoremap <expr><Down>  neocomplete#close_popup() . "\<Down>"
" Or set this.
"let g:neocomplete#enable_cursor_hold_i = 1
" Or set this.
"let g:neocomplete#enable_insert_char_pre = 1

" AutoComplPop like behavior.
let g:neocomplete#enable_auto_select = 1

" Shell like behavior(not recommended).
"set completeopt+=longest
"let g:neocomplete#enable_auto_select = 1
"let g:neocomplete#disable_auto_complete = 1
"inoremap <expr><TAB>  pumvisible() ? "\<Down>" : "\<C-x>\<C-u>"

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
    let g:neocomplete#sources#omni#input_patterns = {}
endif
"let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
"let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
"let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'

" For perlomni.vim setting.
" https://github.com/c9s/perlomni.vim
let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'

"-----------------------------------------------------------------------------
" Tagbar
"-----------------------------------------------------------------------------

let g:tagbar_type_go = {
            \ 'ctagstype' : 'go',
            \ 'kinds'     : [
                \ 'p:package',
                \ 'i:imports:1',
                \ 'c:constants',
                \ 'v:variables',
                \ 't:types',
                \ 'n:interfaces',
                \ 'w:fields',
                \ 'e:embedded',
                \ 'm:methods',
                \ 'r:constructor',
                \ 'f:functions'
            \ ],
            \ 'sro' : '.',
            \ 'kind2scope' : {
                \ 't' : 'ctype',
                \ 'n' : 'ntype'
            \ },
            \ 'scope2kind' : {
                \ 'ctype' : 't',
                \ 'ntype' : 'n'
            \ },
            \ 'ctagsbin'  : 'gotags',
            \ 'ctagsargs' : '-sort -silent'
            \ }


nmap <F8> :TagbarToggle<CR>

" Tag path
set tags=./tags,tags;$HOME

" Golang customizations
let g:go_fmt_command = "goimports"
au FileType go nmap <leader>g :! go test .<CR>
let g:go_bin_path = expand("$GOBIN")

" Syntax Highlighting for Golang
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

" generate go ctags upon save
" au BufWritePost *.go,*.js,*.rb,*.py silent! !ctags -R --exclude=*.html 2> /dev/null &
au BufWritePost *.go,*.js silent! !ctags -R 2> /dev/null &
let g:godef_same_file_in_same_window=1                              " when in go, just move the cursor if in same file
" let g:godef_split=0

au BufRead,BufNewFile *.go set filetype=go
autocmd FileType go setlocal shiftwidth=8 tabstop=8 softtabstop=8   " set tabstop to 8 for go files
autocmd FileType go setlocal noexpandtab                            " don't expand tabs to spaces for go files
" Go keymaps
" Type Info
au FileType go nmap <Leader>i <Plug>(go-info)
" GoDoc
au FileType go nmap <Leader>gd <Plug>(go-doc)
au Filetype go nmap <Leader>gv <Plug>(go-doc-vertical)
" Build/Run/Test
au FileType go nmap <Leader>r <Plug>(go-run)
au FileType go nmap <Leader>b <Plug>(go-build)
au FileType go nmap <Leader>t <Plug>(go-test)
" GoDef
au FileType go nmap gd <Plug>(go-def)
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>dt <Plug>(go-def-tab)

if exists(":Tabularize")
    nmap <Leader>a= :Tabularize /=<CR>
    vmap <Leader>a= :Tabularize /=<CR>
    nmap <Leader>a: :Tabularize /:\zs<CR>
    vmap <Leader>a: :Tabularize /:\zs<CR>
endif

inoremap <silent> <Bar>   <Bar><Esc>:call <SID>align()<CR>a

function! s:align()
    let p = '^\s*|\s.*\s|\s*$'
    if exists(':Tabularize') && getline('.') =~# '^\s*|' && (getline(line('.')-1) =~# p || getline(line('.')+1) =~# p)
        let column = strlen(substitute(getline('.')[0:col('.')],'[^|]','','g'))
        let position = strlen(matchstr(getline('.')[0:col('.')],'.*|\s*\zs.*'))
        Tabularize/|/l1
        normal! 0
        call search(repeat('[^|]*|',column).'\s\{-\}'.repeat('.',position),'ce',line('.'))
    endif
endfunction

"-----------------------------------------------------------------------------
" UltiSnips
"-----------------------------------------------------------------------------

" Trigger configuration. Do not use <tab> if you use
" https://github.com/Valloric/YouCompleteMe.
" let g:UltiSnipsExpandTrigger="<tab>"
" let g:UltiSnipsJumpForwardTrigger="<c-b>"
" let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
" let g:UltiSnipsEditSplit="vertical"

" Snippets

" UltiSnips completion function that tries to expand a snippet. If there's no
" snippet for expanding, it checks for completion window and if it's
" shown, selects first element. If there's no completion window it tries to
" jump to next placeholder. If there's no placeholder it just returns TAB key

function! g:UltiSnips_Complete()
    call UltiSnips#ExpandSnippet()
    if g:ulti_expand_res == 0
        if pumvisible()
            return "\<C-n>"
        else
            call UltiSnips#JumpForwards()
            if g:ulti_jump_forwards_res == 0
                return "\<TAB>"
            endif
        endif
    endif
    return ""
endfunction

au BufEnter * exec "inoremap <silent> " . g:UltiSnipsExpandTrigger . " <C-R>=g:UltiSnips_Complete()<cr>"

let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsListSnippets="<c-e>"
let g:UltiSnipsSnippetDirectories = ["UltiSnips", "ultisnips-snippets"]

"  ---------------------------------------------------------------------------
"  Numbers
"  ---------------------------------------------------------------------------
nnoremap <F6> :NumbersToggle<CR>
nnoremap <F7> :NumbersOnOff<CR>

"  ---------------------------------------------------------------------------
"  Airline settings
"  ---------------------------------------------------------------------------
let g:airline_powerline_fonts = 1
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#tabline#enabled = 0
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline_left_sep = ' '
let g:airline_right_sep = ' '
let g:airline_theme = "solarized"

let g:rbpt_colorpairs = [
            \ ['brown',       'RoyalBlue3'],
            \ ['Darkblue',    'SeaGreen3'],
            \ ['darkgray',    'DarkOrchid3'],
            \ ['darkgreen',   'firebrick3'],
            \ ['darkcyan',    'RoyalBlue3'],
            \ ['darkred',     'SeaGreen3'],
            \ ['darkmagenta', 'DarkOrchid3'],
            \ ['brown',       'firebrick3'],
            \ ['gray',        'RoyalBlue3'],
            \ ['black',       'SeaGreen3'],
            \ ['darkmagenta', 'DarkOrchid3'],
            \ ['Darkblue',    'firebrick3'],
            \ ['darkgreen',   'RoyalBlue3'],
            \ ['darkcyan',    'SeaGreen3'],
            \ ['darkred',     'DarkOrchid3'],
            \ ['red',         'firebrick3'],
            \ ]

nmap gt gt<sid>ts
nmap gT gT<sid>ts
nn <script> <sid>ts+ gt<sid>ts
nn <script> <sid>ts- gT<sid>ts
nmap <sid>ts <nop>

" Minimap
let g:minimap_highlight='Visual'

"  ---------------------------------------------------------------------------
"  Ctrlsf
"  ---------------------------------------------------------------------------
nmap     <C-F>f <Plug>CtrlSFPrompt
vmap     <C-F>f <Plug>CtrlSFVwordPath
vmap     <C-F>F <Plug>CtrlSFVwordExec
nmap     <C-F>n <Plug>CtrlSFCwordPath
nmap     <C-F>p <Plug>CtrlSFPwordPath
nnoremap <C-F>o :CtrlSFOpen<CR>

let g:ctrlsf_ackprg = 'ag'
let g:ctrlsf_position = 'bottom'
let g:ctrlsf_winsize = '30%'
" let g:ctrlsf_winsize = '100'
let g:ctrlsf_auto_close = 1
let g:ctrlsf_context = '-B 5 -A 3'

" Indent Guide
" set ts=4 sw=4 et
" let g:indent_guides_guide_size=1
" let g:indent_guides_start_level=2

let g:indentLine_color_term = 239
let g:indentLine_char = '︙'
" let g:indentLine_char = '¦'
let g:indentLine_noConcealCursor=""

" HTML 5
let g:html5_event_handler_attributes_complete = 0
let g:html5_rdfa_attributes_complete = 0
let g:html5_microdata_attributes_complete = 0
let g:html5_aria_attributes_complete = 0

" Angular
let g:angular_source_directory = 'app/source'
let g:angular_test_directory = 'test/units'



"-----------------------------------------------------------------------------
" Syntastic
"-----------------------------------------------------------------------------

let g:syntastic_error_symbol = '✘'
let g:syntastic_warning_symbol = '✘'
let g:syntastic_style_error_symbol = '≋'
let g:syntastic_style_warning_symbol = '≈'
let g:syntastic_go_checkers = ['golint']                       " use golint for syntax checking in Go
let g:syntastic_loc_list_height = 5                                 " set error window height to 5
let g:syntastic_always_populate_loc_list = 1                        " stick errors into a location-list
let g:syntastic_html_tidy_exec = 'tidy5'
let g:syntastic_html_tidy_ignore_errors=[" proprietary attribute " ,"trimming empty <", "unescaped &" , "lacks \"action", "is not recognized!", "discarding unexpected"]

"-----------------------------------------------------------------------------
" ACK
"-----------------------------------------------------------------------------

if executable('ag')
    let g:ackprg = 'ag --vimgrep'
endif

nnoremap <,a> <Esc>:Ack!

"-----------------------------------------------------------------------------
" Ctrl P
"-----------------------------------------------------------------------------

let g:ctrlp_map = '<c-p>'
" let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_cmd = 'CtrlPMixed'          " search anything (in files, buffers and MRU files at the same time.)
" let g:ctrlp_working_path_mode = 'ra'    " search for nearest ancestor like .git, .hg, and the directory of the current file

let g:ctrlp_max_files = 0
let g:ctrlp_working_path_mode = '0'         " Current Working Directory
let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
let g:ctrlp_custom_ignore = {
            \ 'dir':  '\v[\/](\.(git|hg|svn|idea|build|sass-cache)|node_modules|bower_components|dist)$',
            \ 'file': '\v\.(exe|so|dll)$',
            \ 'link': 'some_bad_symbolic_links',
            \ }

let g:ctrlp_match_window_reversed = 0
let MRU_Max_Entries = 400

nnoremap <silent> <F4> <Esc>:ClearCtrlPCache<CR>
nnoremap <silent> <F3> :TlistToggle<CR>
nnoremap <Leader>u :ClearCtrlPCache<CR>
nnoremap <Leader>j :CtrlPMRU<CR>
nnoremap <Leader>b :CtrlPBuffer<CR>
nnoremap <Leader><Leader> <C-^>

let g:multi_cursor_use_default_mapping = 0
let g:multi_cursor_next_key = '<D-d>'
let g:multi_cursor_prev_key = '<D-u>'
let g:multi_cursor_skip_key = '<D-k>' "until we got multiple keys support
let g:multi_cursor_quit_key = '<Esc>'

let g:ctrlp_match_window_bottom = 1     " show the match window at the top of the screen
let g:ctrlp_by_filename = 1
let g:ctrlp_max_height = 10             " maxiumum height of match window
let g:ctrlp_switch_buffer = 'et'        " jump to a file if it's open already
let g:ctrlp_use_caching = 1             " enable caching
let g:ctrlp_clear_cache_on_exit=0       " speed up by not removing clearing cache evertime
let g:ctrlp_mruf_max = 250              " number of recently opened files

func! MyPrtMappings()
    let g:ctrlp_prompt_mappings = {
                \ 'AcceptSelection("e")': ['<c-t>'],
                \ 'AcceptSelection("t")': ['<cr>', '<2-LeftMouse>'],
                \ }
endfunc

func! MyCtrlPTag()
    let g:ctrlp_prompt_mappings = {
                \ 'AcceptSelection("e")': ['<cr>', '<2-LeftMouse>'],
                \ 'AcceptSelection("t")': ['<c-t>'],
                \ }
    CtrlPBufTag
endfunc

let g:ctrlp_buffer_func = { 'exit': 'MyPrtMappings' }
com! MyCtrlPTag call MyCtrlPTag()

" TODO: add javascript and some other languages who doesn't have ctags support
" coffee: https://gist.github.com/michaelglass/5210282
" go: http://stackoverflow.com/a/8236826/462233
" objc:  http://www.gregsexton.org/2011/04/objective-c-exuberant-ctags-regex/
" rust: https://github.com/mozilla/rust/blob/master/src/etc/ctags.rust
let g:ctrlp_buftag_types = {
            \ 'go'         : '--language-force=go --golang-types=ftv',
            \ 'coffee'     : '--language-force=coffee --coffee-types=cmfvf',
            \ 'markdown'   : '--language-force=markdown --markdown-types=hik',
            \ 'objc'       : '--language-force=objc --objc-types=mpci',
            \ 'rc'         : '--language-force=rust --rust-types=fTm'
            \ }


" CtrlPFunky
nnoremap <Leader>fu :CtrlPFunky<Cr>
" narrow the list down with a word under cursor
nnoremap <Leader>fU :execute 'CtrlPFunky ' . expand('<cword>')<Cr>
let g:ctrlp_funky_syntax_highlight = 1

let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ }

let g:airline#extensions#tmuxline#enabled = 0
let g:tmuxline_theme = 'lightline_insert'


"-----------------------------------------------------------------------------
" Vim Tmux Navigator
"-----------------------------------------------------------------------------
let g:tmux_navigator_no_mappings = 1

nnoremap <silent> {Left-mapping} :TmuxNavigateLeft<cr>
nnoremap <silent> {Down-Mapping} :TmuxNavigateDown<cr>
nnoremap <silent> {Up-Mapping} :TmuxNavigateUp<cr>
nnoremap <silent> {Right-Mapping} :TmuxNavigateRight<cr>
nnoremap <silent> {Previous-Mapping} :TmuxNavigatePrevious<cr>


" Resize splits like a boss
" nnoremap <S-Up> :exe "resize " . (winheight(0) * 11/10)<CR>
" nnoremap <S-Down> :exe "resize " . (winheight(0) * 10/11)<CR>
" nnoremap <S-Left> :exe "vertical resize " . (winwidth(0) * 10/11)<CR>
" nnoremap <S-Right> :exe "vertical resize " . (winwidth(0) * 11/10)<CR>
nnoremap <Leader><Up> :exe "resize " . (winheight(0) * 11/10)<CR>
nnoremap <Leader><Down> :exe "resize " . (winheight(0) * 10/11)<CR>
nnoremap <Leader><Left> :exe "vertical resize " . (winwidth(0) * 10/11)<CR>
nnoremap <Leader><Right> :exe "vertical resize " . (winwidth(0) * 11/10)<CR>
