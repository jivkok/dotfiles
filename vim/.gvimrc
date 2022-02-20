if has("gui_macvim") && has("gui_running")
  " Fullscreen takes up entire screen
  set fuoptions=maxhorz,maxvert

  " Command-T for CtrlP
  macmenu &File.New\ Tab key=<D-T>
  "map <D-t> :CtrlP<CR>
  "map <D-t> :let g:ctrlp_default_input = 0<cr>:CtrlP<cr>
  "map <Leader><D-t> :let g:ctrlp_default_input = 0<cr>:CtrlPClearCache<cr>:CtrlP<cr>
  "imap <D-t> <Esc>:let g:ctrlp_default_input = 0<cr>:CtrlP<cr>

  " Command-Return for fullscreen
  macmenu Window.Toggle\ Full\ Screen\ Mode key=<D-CR>

  " Command-Shift-F for Ag
  map <D-F> :Ag!<space>

  " Map Command-# to switch tabs
  map  <D-0> 0gt
  imap <D-0> <Esc>0gt
  map  <D-1> 1gt
  imap <D-1> <Esc>1gt
  map  <D-2> 2gt
  imap <D-2> <Esc>2gt
  map  <D-3> 3gt
  imap <D-3> <Esc>3gt
  map  <D-4> 4gt
  imap <D-4> <Esc>4gt
  map  <D-5> 5gt
  imap <D-5> <Esc>5gt
  map  <D-6> 6gt
  imap <D-6> <Esc>6gt
  map  <D-7> 7gt
  imap <D-7> <Esc>7gt
  map  <D-8> 8gt
  imap <D-8> <Esc>8gt
  map  <D-9> 9gt
  imap <D-9> <Esc>9gt

  macmenu &File.Close key=<nop>
  map <D-w> :CommandW<cr>
  imap <D-w> <Esc>:CommandW<CR>
endif

" Don't beep
set visualbell

" Start without the toolbar
set guioptions-=T

" Get rid of scroll bars
set guioptions-=L
set guioptions-=r

set guifont=Inconsolata-g\ for\ Powerline:h12
"set guifont=Menlo:h14

" Include user's local vim config
if filereadable(expand("~/.gvimrc.local"))
  source ~/.gvimrc.local
endif
