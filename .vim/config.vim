" Basic -------------------------------------------------------------
syntax on                 " Enable syntax highlighting
set encoding=utf-8 nobomb " Use UTF-8 without BOM
set visualbell t_vb=      " Turn off bell: most annoying default ever created

" UI ---------------------------------------------------------------
set background=dark
colorscheme OceanicNext
" if filereadable(expand("~/.vim/colors/solarized.vim"))
"     let g:solarized_termtrans=1
"     colorscheme solarized
" endif
set title                 " Show the filename in the window titlebar
set cursorline            " Highlight the line the cursor is on
set showcmd               " Show the (partial) command as it’s being typed
set showmode              " Show the current mode
set showmatch             " Briefly jump to matching bracket when inserted
set relativenumber number " Enable line numbers
set laststatus=2          " Always show status line
set ruler                 " Show the cursor position
set nowrap                " Do not wrap long lines
set shortmess=atI         " Don’t show the intro message when starting Vim
set lcs=tab:▸\ ,trail:·,nbsp:_ " Show “invisible” characters. set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_
set list
if $TERM_PROGRAM =~ "iTerm"
  set termguicolors
endif

" Behaviors --------------------------------------------------------------------
set wildmenu              " Turn on menu-based tab completion for commands
set autoread              " Read file if it has changed outside of Vim
set splitbelow splitright " More intuitive than default split behavior
set nojoinspaces          " Use only one space after period when joining lines
set ttyfast               " Optimize for fast terminal connections
set mouse=a               " Enable mouse in all modes
set confirm               " If command requires saved file, raise a dialog when unsaved changes exist

" Editor --------------------------------------------------------------------
set backspace=indent,eol,start " Allow backspace in insert mode
set clipboard=unnamed     " Use the OS clipboard by default (on versions compiled with `+clipboard`)
set binary
set nostartofline         " Don’t reset cursor to start of line when moving around.
set noerrorbells          " Disable error bells
set scrolloff=3           " Start scrolling three lines before the horizontal window border
set exrc                  " Enable per-directory .vimrc files
set secure                " Disable unsafe commands in .vimrc files

" Indents and tabs --------------------------------------------------------------
set shiftwidth=4          " Spaces to use for each indent step (>>, <<, etc.)
set shiftround            " Round indent to multiple of shiftwidth
set softtabstop=4         " Spaces to use for <tab> and <BS> editing operations
set expandtab             " Use appropriate # of spaces for <tab> in insert mode
set tabstop=2             " Make tabs as wide as two spaces
set linebreak             " Soft-wrap at word instead of character
set autoindent            " Copy indent from current line when starting new line
set bs=indent,eol,start   " Backspace over autoindent, EOL, and start of insert

" Searching --------------------------------------------------------------------
set ignorecase            " Case-insensitive search
set smartcase             " Case-sensitive search if query contains uppercase
set hlsearch              " Highlight searches
set incsearch             " Show first search result as query is typed
set gdefault              " Add the g flag to search/replace by default

" Files and buffers ------------------------------------------------------------
filetype on               " Enable file type detection
filetype plugin on        " Enable loading plugins per file types
set hidden                " Allows switching between buffers while they are unsaved
set nobackup
set swapfile
set undofile

" Folding ----------------------------------------------------------------------
set foldmethod=syntax
set foldlevelstart=20
set foldcolumn=1
let g:vim_markdown_folding_disabled=1 " Markdown
let javaScript_fold=1                 " JavaScript
let perl_fold=1                       " Perl
let php_folding=1                     " PHP
let r_syntax_folding=1                " R
let ruby_fold=1                       " Ruby
let sh_fold_enabled=1                 " sh
let vimsyn_folding='af'               " Vim script
let xml_syntax_folding=1              " XML

" Backups, swapfiles, and undo -------------------------------------------------
set backupdir=~/.vim/backups
set directory=~/.vim/swaps
if exists("&undodir")
    set undodir=~/.vim/undo
endif
set backupskip=/tmp/*,/private/tmp/* " Don’t create backups when editing files in certain directories

" When using vimdiff, remap prev/next changes to [ and ].
" Specify colors for added, modified, and deleted text. For details, see :help highlighting
" DiffAdd - added line
" DiffDelete - removed line
" DiffChange - changed line
" DiffText - changed text inside a changed line
if &diff
    set cursorline
    map ] ]c
    map [ [c
    " from https://github.com/jonathanfilip/vim-lucius/blob/master/colors/lucius.vim
    highlight DiffAdd    cterm=bold ctermfg=fg ctermbg=65 gui=bold guifg=fg guibg=#5f875f
    highlight DiffDelete cterm=bold ctermfg=fg ctermbg=95 gui=bold guifg=fg guibg=#875f5f
    highlight DiffChange cterm=bold ctermfg=fg ctermbg=101 gui=bold guifg=fg guibg=#87875f
    highlight DiffText   cterm=bold ctermfg=228 ctermbg=101 gui=bold guifg=#ffff87 guibg=#87875f
endif

if has("autocmd")
    " When editing a file, always jump to the last cursor position
    autocmd BufReadPost * if line("'\"") | exe "'\"" | endif
endif

