# OSX and Linux machine configuration scripts

## OSX

### Content
* Aliases
* Functions
* Customized Bash prompt
* Environment settings (common, vim, wget)
* Homebrew packages (optional)
* Additional software (optional)
* OSX tweaks (optional)
* Git configuration (optional)
* SublimeText configuration (optional)

### Installation
The setup script will configure aliases, function, prompt, and environment settings.
For the rest of the steps - it will ask whether to run each one.

#### Option #1
```sh
wget -qO- https://raw.githubusercontent.com/jivkok/dotfiles/master/setup-osx.sh | sh
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
wget -qO- https://raw.githubusercontent.com/jivkok/dotfiles/master/setup-debian.sh | sh
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
