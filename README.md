# OSX, Linux, and Windows machine configuration scripts

Details:
* [OSX](www.apple.com/osx/) - OSX [Snow Leopard](www.apple.com/support/snowleopard/) (10.5) onward.
* [Linux](www.linux.com/) - [Debian](www.debian.org/) distros ([Ubuntu](www.ubuntu.com/), etc.).
* [Windows](www.microsoft.com/en-us/windows/) - [babun](http://babun.github.io) shell (pre-configured [Cygwin](www.cygwin.com/) with [Zsh](www.zsh.org/)), [DOS](https://technet.microsoft.com/en-us/library/cc754340.aspx), and [Powershell](https://technet.microsoft.com/library/hh857337.aspx)



## OSX / Linux (Debian-style) / Windows (cygwin)

### What's included

#### Common
* [Aliases](https://github.com/jivkok/dotfiles/blob/master/.aliases)
* [Functions](https://github.com/jivkok/dotfiles/blob/master/.functions)
* Shell options: [Bash](https://github.com/jivkok/dotfiles/blob/master/.bashrc) / [Zsh](https://github.com/jivkok/dotfiles/blob/master/.zshrc)
* Shell theme: [Bash](https://github.com/jivkok/dotfiles/blob/master/.bash_prompt) / [Zsh](https://github.com/jivkok/dotfiles/blob/master/.zsh-theme)
* [Zsh configuration](https://github.com/jivkok/dotfiles/blob/master/configure_zsh.sh)
* [Git configuration](https://github.com/jivkok/dotfiles/blob/master/configure_git.sh)
* [Tmux configuration](https://github.com/jivkok/dotfiles/blob/master/.tmux.conf)
* [Vim configuration](https://github.com/jivkok/dotfiles/tree/master/.vim)
* [SublimeText configuration](https://github.com/jivkok/dotfiles/tree/master/sublimetext)

#### OSX-specific
* [Homebrew packages](https://github.com/jivkok/dotfiles/blob/master/osx/brew.sh)
* [OSX software](https://github.com/jivkok/dotfiles/blob/master/osx/software.sh)
* [OSX tweaks](https://github.com/jivkok/dotfiles/blob/master/osx/.osx)
* [Alfred workflows](https://github.com/jivkok/alfred-workflows)

### Installation
The setup script will configure shell options, theme, aliases, and functions.
The setup script will ask whether to run each of the optional steps.
There is option to change the shell to [Zsh](www.zsh.org/).

#### Option #1
```sh
# OSX
curl https://raw.githubusercontent.com/jivkok/dotfiles/master/setup_osx.sh | sh

# Linux (Debian-style)
curl https://raw.githubusercontent.com/jivkok/dotfiles/master/setup_debian.sh | sh

# Windows (cygwin)
curl https://raw.githubusercontent.com/jivkok/dotfiles/master/setup_babun.sh | sh
```

#### Option #2
```sh
# OSX
cd $HOME
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" # Homebrew
brew install git
git clone https://github.com/jivkok/dotfiles.git dotfiles
source dotfiles/setup_osx.sh

# Linux (Debian-style)
cd $HOME
sudo apt-get install git
git clone https://github.com/jivkok/dotfiles.git dotfiles
source dotfiles/setup_debian.sh

# Windows (cygwin)
cd $HOME
git clone https://github.com/jivkok/dotfiles.git dotfiles
source dotfiles/setup_babun.sh
```

### Customizations

#### Specify the `$PATH`
If `~/.path` exists, it will be sourced along with the other files.
Here’s an example `~/.path` file that adds `/usr/local/bin` to the `$PATH`:

```bash
export PATH="/usr/local/bin:$PATH"
```

#### Custom commands without creating a new fork
If `~/.profile.local` exists, it will be sourced along with the other files. You can use this to add custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.
Since `~/.profile.local` is sourced at the end, it allows for overriding of existing settings, functions, and aliases.

### Upgrade
```sh
cd ~/dotfiles
git pull
```



## Windows (DOS and Powershell)

### What's included
* [Packages](https://github.com/jivkok/Chocolatey-Packages/blob/master/jivkok.Shell/jivkok.Shell.nuspec) with [Chocolatey](https://chocolatey.org/)
* [DOS/Powershell setup](https://github.com/jivkok/dotfiles/blob/master/setup_windows.ps1)
* [Console configuration](https://github.com/jivkok/dotfiles/blob/master/windows/console.xml)
* [DOS configuration](https://github.com/jivkok/dotfiles/blob/master/windows/SetEnv.cmd)
* [Powershell configuration](https://github.com/jivkok/dotfiles/blob/master/windows/SetEnv.ps1)

### Installation
The setup script will install packages with Chocolatey, configure a multi-tabbed console and its desktop shortcut, configure system options, theme, aliases, and functions.

#### Option #1 (concise, with Boxstarter & Chocolatey)
Open [http://j.mp/jivkokshell]() in Internet Explorer. Same as:
```
START http://boxstarter.org/package/nr/url?https://raw.githubusercontent.com/jivkok/Chocolatey-Packages/master/jivkok.Shell/shell.boxstarter.ps1
```

#### Option #2 (concise)
```
# Note: run from elevated shell
# DOS
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/jivkok/dotfiles/master/setup_windows.ps1'))"
# Powershell
iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/jivkok/dotfiles/master/setup_windows.ps1'))
```

#### Option #3 (with Chocolatey)
```
# Note: run from elevated shell
# DOS
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
cinst jivkok.shell -source http://www.myget.org/F/jivkok-chocolatey

# Powershell
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
cinst jivkok.shell -source http://www.myget.org/F/jivkok-chocolatey
```

#### Option #4 (manual repo cloning)
```
# Note: run from elevated shell
# DOS
cd /d %USERPROFILE%
git clone https://github.com/jivkok/dotfiles.git dotfiles
@powershell -NoProfile -ExecutionPolicy Bypass -File dotfiles\setup_windows.ps1

# Powershell
cd $HOME
git clone https://github.com/jivkok/dotfiles.git dotfiles
. dotfiles\setup_windows.ps1
```

### Customizations

#### Custom commands without creating a new fork
If custom profile script ( `%USERPROFILE%\profile.cmd` for DOS, `$Home\profile.ps1` for Powershell ) exists, it will be included along with the other files. You can use this to add custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.
Since this local profile is included at the end, it allows for overriding of existing settings, functions, and aliases.

### Upgrade
```
# DOS: cd /d %USERPROFILE%\dotfiles
# Powershell: cd $HOME\dotfiles
git pull
```



## Credits

* Mathias Bynens for his [dotfiles](https://github.com/mathiasbynens/dotfiles)
* Balaji Srinivasan for his [dotfiles](https://github.com/startup-class/dotfiles)
* Zeno Rocha for his [Alfred workflows](https://github.com/zenorocha/alfred-workflows)
* Rob Reynolds for [Chocolatey.org](https://chocolatey.org/)
* Matt Wrock for [boxstarter.org](https://boxstarter.org/)
