" Vundle ----------------------------------------------------------------------
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
" see :h vundle for more details or wiki for FAQ

set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'

" Plugin bundles --------------------------------------------------------------

" UI
Plugin 'mhinz/vim-startify' " Start screen with MRUs, sessions, bookmarks, etc.
Plugin 'benmills/vimux' " tmux integration, runs shell commands
Plugin 'bling/vim-airline' " status line
Plugin 'airblade/vim-gitgutter' " git diff in the gutter and stages/reverts hunks
Plugin 'tpope/vim-fugitive' " Git wrapper
Plugin 'sheerun/vim-polyglot' " collection of language packs - syntax, indent, ftdetect
Plugin 'nathanaelkane/vim-indent-guides' "displays indent levels

" Editing
Plugin 'msanders/snipmate.vim' " snippets mgmt for various languages
Plugin 'Valloric/YouCompleteMe' " code-completion engine
Plugin 'dhruvasagar/vim-table-mode' " tables creation
Plugin 'godlygeek/tabular' " text alignment
Plugin 'vim-scripts/ZoomWin' " Zoom in/out of windows (toggle between one window and multi-window)
Plugin 'terryma/vim-multiple-cursors' " multiple selections
Plugin 'easymotion/vim-easymotion' " motions - mark all words on a screen and then allow one-key-press to jump to any of them
Plugin 'tpope/vim-surround' " surroundings: parentheses, brackets, quotes, XML tags, and more
Plugin 'tpope/vim-repeat' " enable repeating supported plugin maps with '.'
Plugin 'mattn/emmet-vim' " HTML/CSS high-speed coding
Plugin 'editorconfig/editorconfig-vim' " standardized editing styles
"Plugin 'davidhalter/jedi-vim' " Python autocompletion

" Buffers/files
Plugin 'kien/ctrlp.vim' " Full path fuzzy file, buffer, mru, tag, ... finder
Plugin 'duff/vim-scratch' " Temporary scratch buffers
Plugin 'scrooloose/nerdtree' " File tree explorer

" Code checking and formatting
Plugin 'scrooloose/syntastic' " syntax checking
Plugin 'scrooloose/nerdcommenter' " comments mgmt
Plugin 'majutsushi/tagbar' " class outline viewer

" Misc
Plugin 'rking/ag.vim' " Vim plugin for the_silver_searcher 'ag' - code-searching tool

" No plugins below this line --------------------------------------------------
call vundle#end()

filetype plugin indent on
"filetype plugin on " To ignore plugin indent changes
