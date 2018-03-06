" Custom mapleader
let mapleader="\<Space>"

" Help
nmap <F1> :help<space>jkvim<cr>

" Searching
" Visual mode pressing * or # searches for the current selection, forward or backward, respectively
vnoremap <silent> * :call VisualSelection('f')<cr>
vnoremap <silent> # :call VisualSelection('b')<cr>
" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Buffers
nmap <leader>w :w!<cr> " Force-save file
nmap <leader>W :w !sudo tee % > /dev/null<cr> " Save file as root
nmap <F3> :bp<cr> " Previous buffer
nmap <F4> :bn<cr> " Next buffer
nmap <leader>bd :bd<cr> " Close buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr> " Switch CWD to the directory of the open buffer

" Tabs
nmap <Leader>tn :tabnew<cr>
nmap <Leader>tc :tabclose<cr>
" Opens new tab with the current buffer's tab
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/
nmap <F11> :tabp<cr>
nmap <F12> :tabn<cr>

" Tags
nmap <Leader>]t :tnext<CR>
nmap <Leader>[t :tprevious<CR>
nmap <Leader>]T :tlast<CR>
nmap <Leader>[T :tfirst<CR>
nmap <Leader>ts :tselect<CR>

" Quickfix & Location
nmap <silent> <Leader>]q :cnext<CR>
nmap <silent> <Leader>[q :cprevious<CR>
nmap <silent> <Leader>[Q :cfirst<CR>
nmap <silent> <Leader>]Q :clast<CR>
nmap <Leader>qo :copen<CR>
nmap <Leader>qc :cclose<CR>
nmap <silent> <Leader>]l :lnext<CR>
nmap <silent> <Leader>[l :lprevious<CR>
nmap <silent> <Leader>[L :lfirst<CR>
nmap <silent> <Leader>]L :llast<CR>
nmap <Leader>lo :lopen<CR>
nmap <Leader>lc :lclose<CR>

" Strip trailing whitespace ( ss)
function! StripWhitespace()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    :%s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfunction
noremap <leader>ss :call StripWhitespace()<cr>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! CmdLine(str)
    exe "menu Foo.Bar :" . a:str
    emenu Foo.Bar
    unmenu Foo
endfunction

function! VisualSelection(direction) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", '\\/.*$^~[]')
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'b'
        execute "normal ?" . l:pattern . "^M"
    elseif a:direction == 'gv'
        call CmdLine("vimgrep " . '/'. l:pattern . '/' . ' **/*.')
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    elseif a:direction == 'f'
        execute "normal /" . l:pattern . "^M"
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction
