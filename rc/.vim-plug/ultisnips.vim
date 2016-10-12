" delimitMate
let g:delimitMate_expand_cr=1   " Put new brace on newline after CR
let g:delimitMate_expand_space = 1
let g:delimitMate_smart_quotes = 1
let g:delimitMate_expand_inside_quotes = 0
let g:delimitMate_smart_matchpairs = '^\%(\w\|\$\)'

"-----------------------------------------------------------------------------
" UltiSnips
"-----------------------------------------------------------------------------

let g:UltiSnipsSnippetDirectories = ["UltiSnips", "ultisnips-snippets"]

let g:UltiSnipsExpandTrigger = '<c-l>'
let g:UltiSnipsJumpForwardTrigger = '<c-l>'
let g:UltiSnipsJumpBackwardTrigger = '<c-b>'
let g:UltiSnipsListSnippets="<nop>"
let g:ulti_expand_or_jump_res = 0

function! <SID>ExpandSnippetOrReturn()
    let snippet = UltiSnips#ExpandSnippet()

    if g:ulti_expand_or_jump_res > 0
        return snippet
    else
        return "\<C-Y>"
    endif
endfunction
imap <expr> <CR> pumvisible() ? "<C-R>=<SID>ExpandSnippetOrReturn()<CR>" : "<Plug>delimitMateCR"

function! s:tab_complete()
    " is completion menu open? cycle to next item
    if pumvisible()
        return "\<c-n>"
    endif

    " is there a snippet that can be expanded?
    " is there a placholder inside the snippet that can be jumped to?
    if neosnippet#expandable_or_jumpable()
        return "\<Plug>(neosnippet_expand_or_jump)"
    endif

    " if none of these match just use regular tab
    return "\<tab>"
endfunction

imap <silent><expr><TAB> <SID>tab_complete()
