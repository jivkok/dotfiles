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

" Editing
Plugin 'msanders/snipmate.vim' " snippets mgmt for various languages
Plugin 'dhruvasagar/vim-table-mode' " tables creation
Plugin 'godlygeek/tabular' " text alignment
"Plugin 'tpope/vim-surround' " surroundings: parentheses, brackets, quotes, XML tags, and more
"Plugin 'mattn/emmet-vim' " HTML/CSS high-speed coding
"Plugin 'davidhalter/jedi-vim' " Python autocompletion

" Buffers/files
Plugin 'duff/vim-scratch'
Plugin 'scrooloose/nerdtree'

" Code checking and formatting
Plugin 'scrooloose/syntastic' " syntax checking
Plugin 'scrooloose/nerdcommenter' " comments mgmt

" No plugins below this line --------------------------------------------------
call vundle#end()

filetype plugin indent on
"filetype plugin on " To ignore plugin indent changes
