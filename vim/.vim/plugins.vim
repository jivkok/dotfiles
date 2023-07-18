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

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugins --------------------------------------------------------------
call plug#begin('~/.vim/plugins')

" Editor
Plug 'ryanoasis/vim-devicons' " icons for various plugins
Plug 'benmills/vimux' " tmux integration, runs shell commands
Plug 'vim-airline/vim-airline' " status line
Plug 'vim-airline/vim-airline-themes' " status line
Plug 'airblade/vim-gitgutter' " git diff in the gutter and stages/reverts hunks
Plug 'tpope/vim-fugitive' " Git wrapper
Plug 'sheerun/vim-polyglot' " collection of language packs - syntax, indent, ftdetect
Plug 'nathanaelkane/vim-indent-guides' "displays indent levels

" Editor - buffers/files
Plug 'scrooloose/nerdtree' " File tree explorer
Plug 'Xuyuanp/nerdtree-git-plugin' " show git status in NerdTree

" Editor - languages
Plug 'OmniSharp/omnisharp-vim' " Omnicompletion (intellisense) and more for C#

" Editor - themes
" Plug 'mhartington/oceanic-next' " color scheme
Plug 'tomasiser/vim-code-dark' " color scheme
" Plug 'gruvbox-community/gruvbox' " color scheme

" Editing
Plug 'terryma/vim-multiple-cursors' " multiple selections
Plug 'easymotion/vim-easymotion' " motions - mark all words on a screen and then allow one-key-press to jump to any of them
Plug 'tpope/vim-surround' " surroundings: parentheses, brackets, quotes, XML tags, and more
Plug 'tpope/vim-repeat' " enable repeating supported plugin maps with '.'
Plug 'tpope/vim-unimpaired' " provides several pairs of bracket mappings
Plug 'mattn/emmet-vim' " HTML/CSS high-speed coding
Plug 'sgur/vim-editorconfig' " standardized editing styles
Plug 'simnalamburt/vim-mundo' " Vim undo tree visualizer

" Auto-completion
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' } " code-completion engine
else
  Plug 'Shougo/neocomplete' " code-completion engine
endif
" Plug 'davidhalter/jedi-vim' " Python autocompletion

" Linting engines
Plug 'dense-analysis/ale' " Asynchronous lint engine

" Linting, syntax-coloring, and auto-formatting
Plug 'Chiel92/vim-autoformat' " code auto-formatting

" Search
Plug 'mileszs/ack.vim' " Run your favorite search tool from Vim
Plug 'junegunn/fzf', { 'dir': '~/.vim/plugins/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim' " fuzzy file finder integration
Plug 'kshenoy/vim-signature' " place, toggle and display marks

" Tags
Plug 'majutsushi/tagbar' " class outline viewer

call plug#end()
" No plugins below this line --------------------------------------------------
