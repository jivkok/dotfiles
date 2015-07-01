" keys.vim

" Custom mapleader
let mapleader=","

" Fast saving (,w)
nmap <leader>w :w!<cr>
" Save a file as root (,W)
noremap <leader>W :w !sudo tee % > /dev/null<cr>

" Searching
" Visual mode pressing * or # searches for the current selection, forward or backward, respectively
vnoremap <silent> * :call VisualSelection('f')<cr>
vnoremap <silent> # :call VisualSelection('b')<cr>
" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Buffers
nmap <F3> :bp<cr> " Previous (F3)
nmap <F4> :bn<cr> " Next (F4)
map <leader>bd :Bclose<cr> " Close
" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Tabs
nmap <Leader>tt :tabnew<cr>
nmap <Leader>tc :tabclose<cr>
" Opens new tab with the current buffer's tab
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/
nmap <F11> :tabp<cr>
nmap <F12> :tabn<cr>

" Strip trailing whitespace (,ss)
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

