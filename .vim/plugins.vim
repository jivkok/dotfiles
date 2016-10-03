" VimPlug (https://github.com/junegunn/vim-plug) -----------------------
" Brief help
" :PlugInstall [name ...] [#threads]   - Install plugins
" :PlugUpdate [name ...] [#threads]    - Install or update plugins
" :PlugClean[!]   - Remove unused directories (bang version will clean without prompt)
" :PlugUpgrade   - Upgrade vim-plug itself
" :PlugStatus   - Check the status of plugins
" :PlugDiff   - Examine changes from the previous update and the pending changes
" :PlugSnapshot[!] [output path]   - Generate script for restoring the current snapshot of the plugins
" see https://github.com/junegunn/vim-plug/wiki/faq for more details

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

" Plugins --------------------------------------------------------------
call plug#begin('~/.vim/plugins')

" UI
Plug 'mhinz/vim-startify' " Start screen with MRUs, sessions, bookmarks, etc.
Plug 'benmills/vimux' " tmux integration, runs shell commands
Plug 'bling/vim-airline' " status line
Plug 'airblade/vim-gitgutter' " git diff in the gutter and stages/reverts hunks
Plug 'tpope/vim-fugitive' " Git wrapper
Plug 'sheerun/vim-polyglot' " collection of language packs - syntax, indent, ftdetect
Plug 'nathanaelkane/vim-indent-guides' "displays indent levels

" Editing
Plug 'msanders/snipmate.vim' " snippets mgmt for various languages
Plug 'dhruvasagar/vim-table-mode' " tables creation
Plug 'godlygeek/tabular' " text alignment
Plug 'vim-scripts/ZoomWin' " Zoom in/out of windows (toggle between one window and multi-window)
Plug 'terryma/vim-multiple-cursors' " multiple selections
Plug 'easymotion/vim-easymotion' " motions - mark all words on a screen and then allow one-key-press to jump to any of them
Plug 'tpope/vim-surround' " surroundings: parentheses, brackets, quotes, XML tags, and more
Plug 'tpope/vim-repeat' " enable repeating supported plugin maps with '.'
Plug 'mattn/emmet-vim' " HTML/CSS high-speed coding
Plug 'editorconfig/editorconfig-vim' " standardized editing styles
"Plug 'davidhalter/jedi-vim' " Python autocompletion

" Buffers/files
Plug 'kien/ctrlp.vim' " Full path fuzzy file, buffer, mru, tag, ... finder
Plug 'duff/vim-scratch' " Temporary scratch buffers
Plug 'scrooloose/nerdtree' " File tree explorer

" Code checking and formatting
Plug 'scrooloose/syntastic' " syntax checking
Plug 'scrooloose/nerdcommenter' " comments mgmt
Plug 'majutsushi/tagbar' " class outline viewer

" Misc
Plug 'rking/ag.vim' " Vim plugin for the_silver_searcher 'ag' - code-searching tool
" Plug '/usr/local/opt/fzf' " fuzzy file finder
Plug 'junegunn/fzf', { 'dir': '~/.vim/plugins/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim' " fuzzy file finder integration

if has('nvim')
  Plug 'Shougo/deoplete.nvim' " code-completion engine
else
  Plug 'Valloric/YouCompleteMe' " code-completion engine
  " Plug 'Shougo/neocomplete' " code-completion engine
endif

call plug#end()
" No plugins below this line --------------------------------------------------
