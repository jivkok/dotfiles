# OSX and Linux machine configuration scripts

## OSX

### Content
* [Aliases](https://github.com/jivkok/dotfiles/blob/master/.aliases)
* [Functions](https://github.com/jivkok/dotfiles/blob/master/.functions)
* Customized [Bash prompt](https://github.com/jivkok/dotfiles/blob/master/.bash_prompt)
* [Environment settings](https://github.com/jivkok/dotfiles/blob/master/.bashrc) (common, vim, wget)
* [Homebrew packages](https://github.com/jivkok/dotfiles/blob/master/osx/brew.sh) (optional)
* [Additional software](https://github.com/jivkok/dotfiles/blob/master/osx/software.sh) (optional)
* [OSX tweaks](https://github.com/jivkok/dotfiles/blob/master/osx/.osx) (optional)
* [Git configuration](https://github.com/jivkok/dotfiles/blob/master/configure_git.sh) (optional)
* [SublimeText configuration](https://github.com/jivkok/dotfiles/tree/master/sublimetext) (optional)
* [Alfred workflows](https://github.com/jivkok/alfred-workflows) (optional)

### Installation
The setup script will configure aliases, function, prompt, and environment settings.
For the rest of the steps - it will ask whether to run each one.

#### Option #1
```sh
curl https://raw.githubusercontent.com/jivkok/dotfiles/master/setup-osx.sh | sh
```
#### Option #2
```sh
cd $HOME
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" # Homebrew
brew install git
git clone https://github.com/jivkok/dotfiles.git dotfiles
source dotfiles/setup-osx.sh
```

### Customizations

### Specify the `$PATH`

If `~/.path` exists, it will be sourced along with the other files.

Here’s an example `~/.path` file that adds `/usr/local/bin` to the `$PATH`:

```bash
export PATH="/usr/local/bin:$PATH"
```

### Add custom commands without creating a new fork

If `~/.bash_extra` exists, it will be sourced along with the other files. You can use this to add a few custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.
You can also use `~/.bash_extra` to override dotfiles settings, functions and aliases.


## Linux (Debian-style)

### Option 1
```sh
curl https://raw.githubusercontent.com/jivkok/dotfiles/master/setup-debian.sh | sh
```
### Option 2
```sh
cd $HOME
sudo apt-get install git
git clone https://github.com/jivkok/dotfiles.git dotfiles
source dotfiles/setup-debian.sh
```


## Upgrade
```sh
cd ~/dotfiles
git pull
```


## Credits

* Mathias Bynens for his [dotfiles](https://github.com/mathiasbynens/dotfiles)
* Balaji Srinivasan for his [dotfiles](https://github.com/startup-class/dotfiles)
* Zeno Rocha for his [Alfred workflows](https://github.com/zenorocha/alfred-workflows)
