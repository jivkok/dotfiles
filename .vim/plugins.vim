" plugins.vim

" NerdTree (,nt)
let g:NERDTreeShowBookmarks=1
let g:NERDTreeMinimalUI=1
let g:NERDTreeIgnore=['\.so$', '\.class$', '\.swp']
" Open NERDTree if no files specified
"autocmd vimenter * if !argc() | NERDTree | endif
nmap <F5> :NERDTreeToggle<cr>
map <leader>nt :NERDTreeToggle<cr>
