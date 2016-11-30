# OSX, Linux, and Windows machine configuration scripts

## Table of Contents

* [OS Details](#os-details)
* [OSX / Linux (Debian-style) / Windows (cygwin)](#osx-linux-debian-style-windows-cygwin)
    + [What is included](#what-is-included)
    + [Installation](#installation)
    + [Individual Configuration Scripts](#individual-configuration-scripts)
    + [Customizations](#customizations)
    + [Upgrade](#upgrade)
* [Windows (Command shell and Powershell)](#windows-command-shell-and-powershell)
    + [What is included](#what-is-included_1)
    + [Installation](#installation_1)
    + [Customizations](#customizations_1)
    + [Upgrade](#upgrade_1)
* [Credits](#credits)



## OS Details

* [OSX](www.apple.com/osx/) - OSX [Snow Leopard](www.apple.com/support/snowleopard/) (10.5) onward.
* [Linux](www.linux.com/) - [Debian](www.debian.org/) distros ([Ubuntu](www.ubuntu.com/), etc.).
* [Windows](www.microsoft.com/en-us/windows/) - [babun](http://babun.github.io) shell (pre-configured [Cygwin](www.cygwin.com/) with [Zsh](www.zsh.org/)), [Command shell](https://technet.microsoft.com/en-us/library/cc754340.aspx), and [Powershell](https://technet.microsoft.com/library/hh857337.aspx)



## OSX / Linux (Debian-style) / Windows (cygwin)

### What is included

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
There is option to change the default shell to [Zsh](www.zsh.org/).

**Note**: Dotfiles default location is **$HOME/dotfiles**. If yo want to change it, specify a different directory prior to running the setup scripts by setting the **dotdir** variable:

```sh
export dotdir=$HOME/path/to/my/dotfiles
```

#### Option #1

```sh
curl https://raw.githubusercontent.com/jivkok/dotfiles/master/setup.sh | bash
```

#### Option #2 - OS-specific, plus manual repo clone

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


### Individual Configuration Scripts

* **configure_brackets.sh**: text editor for web development
* **configure_databases.sh**: MySQL, PostgreSQL, MongoDB, Redis, and ElasticSearch
* **configure_dotnet.sh**: .Net framework
* **configure_git.sh**: Git DVCS
* **configure_nodejs.sh**: NodeJS runtime environment
* **configure_python.sh**: Python programming language
* **configure_ruby.sh**: Ruby programming language
* **configure_sublimetext.sh**: multi-purpose text editor
* **configure_vim.sh**: highly configurable text editor
* **configure_zsh.sh**: ZShell



### Customizations

#### Specify custom `$PATH`

If `$HOME/.path` exists, it will be sourced along with the other files.
Here is an example `~/.path` file that adds `/usr/local/bin` to `$PATH`:

```sh
export PATH="/usr/local/bin:$PATH"
```

#### Custom commands without creating a new fork

If `$HOME/.profile.local` exists, it will be sourced along with the other files. You can use this to add custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.
Since `$HOME/.profile.local` is sourced at the end, it allows for overriding of existing settings, functions, and aliases.

#### OSX: System Preferences

* Security & Privacy:
  * General:
    * Require password immediately after sleep or screen saver begins.
    * Show contact info when screen is locked.
    * Allow apps downloaded from App Store and identified developers.
  * FileVault:
    * Enable FileVault and save the recovery key in a secure location.
  * Firewall:
    * Enable it.
    * Automatically allow signed software.
    * Enable stealth mode.
  * Privacy:
    * Apps like Alfred, Dropbox, etc. will need to be enabled for accessibility.
* Printers & Scanners:
    * Add them.
* iCloud:
    * Enable Find My Mac.
* Users & Groups:
    * Update avatar.


### Upgrade

```sh
cd ~/dotfiles
git pull
```



## Windows (Command shell and Powershell)

### What is included

* [Packages](https://github.com/jivkok/Chocolatey-Packages/blob/master/jivkok.Shell/jivkok.Shell.nuspec) with [Chocolatey](https://chocolatey.org/)
* [Command shell / Powershell setup](https://github.com/jivkok/dotfiles/blob/master/setup_windows.ps1)
* [Console configuration](https://github.com/jivkok/dotfiles/blob/master/windows/console.xml)
* [Command shell configuration](https://github.com/jivkok/dotfiles/blob/master/windows/SetEnv.cmd)
* [Powershell configuration](https://github.com/jivkok/dotfiles/blob/master/windows/SetEnv.ps1)

### Installation

The setup script will install packages with Chocolatey, configure a multi-tabbed console and its desktop shortcut, configure system options, theme, aliases, and functions.

**Note**: run the shell commands from elevated shell.

#### Option #1 (concise, with Boxstarter & Chocolatey)

Open [http://j.mp/jivkokshell](http://j.mp/jivkokshell) in Internet Explorer or Edge. Same as:

```bat
START http://boxstarter.org/package/nr/url?https://raw.githubusercontent.com/jivkok/Chocolatey-Packages/master/jivkok.Shell/shell.boxstarter.ps1
```

#### Option #2 (concise)

```bat
rem With Command shell:
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/jivkok/dotfiles/master/setup_windows.ps1'))"
```

```posh
# With Powershell:
Set-ExecutionPolicy Bypass
iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/jivkok/dotfiles/master/setup_windows.ps1'))
```

#### Option #3 (with Chocolatey)

```bat
rem With Command shell:
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
cinst jivkok.shell -y -source http://www.myget.org/F/jivkok-chocolatey
```

```posh
# With Powershell:
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
cinst jivkok.shell -y -source http://www.myget.org/F/jivkok-chocolatey
```

#### Option #4 (manual repo cloning)

```bat
rem With Command shell:
git clone https://github.com/jivkok/dotfiles.git %USERPROFILE%\dotfiles
@powershell -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\dotfiles\setup_windows.ps1
```

```posh
# With Powershell:
git clone https://github.com/jivkok/dotfiles.git $HOME\dotfiles
. $HOME\dotfiles\setup_windows.ps1
```

### Customizations

#### Custom commands without creating a new fork

If custom profile script ( `%USERPROFILE%\profile.cmd` for Command shell, `$Home\profile.ps1` for Powershell ) exists, it will be included along with the other files. You can use this to add custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.
Since this local profile is included at the end, it allows for overriding of existing settings, functions, and aliases.

### Upgrade

```bat
rem With Command shell:
cd /d %USERPROFILE%\dotfiles
git pull
```

```posh
# With Powershell:
cd $HOME\dotfiles
git pull
```



## Credits

* Mathias Bynens for his [dotfiles](https://github.com/mathiasbynens/dotfiles)
* Balaji Srinivasan for his [dotfiles](https://github.com/startup-class/dotfiles)
* Zeno Rocha for his [Alfred workflows](https://github.com/zenorocha/alfred-workflows)
* Rob Reynolds for [Chocolatey.org](https://chocolatey.org/)
* Matt Wrock for [boxstarter.org](https://boxstarter.org/)
