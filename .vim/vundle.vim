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
Plugin 'mhinz/vim-startify'

" Behaviors

" Buffers/files
Plugin 'duff/vim-scratch'
Plugin 'scrooloose/nerdtree'

" Language syntax

" Code checking and formatting


" No plugins below this line --------------------------------------------------
call vundle#end()

filetype plugin indent on
"filetype plugin on " To ignore plugin indent changes
