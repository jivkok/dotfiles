source ~/.vim/plugins.vim " Plugins
source ~/.vim/config.vim " Core configuration
source ~/.vim/keys.vim " Keys and bindings
source ~/.vim/pluginsconfig.vim " Plugins-specific configuration

" Include user's local vim config
if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif
