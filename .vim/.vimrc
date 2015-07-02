" .vimrc

source ~/.vim/vundle.vim  " Plugins contained within are installed via Vundle

source ~/.vim/config.vim  " Core configuration
source ~/.vim/keys.vim    " Keys and bindings
source ~/.vim/plugins.vim " Plugin-specific configuration

" Include user's local vim config
if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif