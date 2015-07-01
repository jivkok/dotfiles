" plugins.vim

" NerdTree (,nt)
let g:NERDTreeShowBookmarks=1
let g:NERDTreeMinimalUI=1
let g:NERDTreeIgnore=['\.so$', '\.class$', '\.swp']
" Open NERDTree if no files specified
"autocmd vimenter * if !argc() | NERDTree | endif
nmap <F5> :NERDTreeToggle<cr>
map <leader>nt :NERDTreeToggle<cr>

" vim-airline
" Shows tabline even with a single tab - shows buffers instead
let g:airline#extensions#tabline#enabled = 1

" vim-gitgutter
let g:gitgutter_escape_grep = 1
nmap <Leader>ht :GitGutterLineHighlightsToggle<cr>

" ctrlp
let g:ctrlp_show_hidden = 1
let g:ctrlp_custom_ignore = '\v[\/](node_modules|target|dist)|(\.(swp|ico|git|svn|DS_Store))$'

" ag.vim
let g:ag_highlight=1
