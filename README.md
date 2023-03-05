# OSX, Linux, and Windows machine configuration scripts

## Table of Contents

* [OS Details](#os-details)
* [macOS / Linux (Debian-based, Arch)](#macos-linux-debian-based-arch)
    + [What is included](#what-is-included)
    + [Installation](#installation)
    + [Customizations](#customizations)
    + [Upgrade](#upgrade)
* [Windows (Command shell and Powershell)](#windows-command-shell-and-powershell)
    + [What is included](#what-is-included_1)
    + [Installation](#installation_1)
    + [Customizations](#customizations_1)
    + [Upgrade](#upgrade_1)
* [Credits](#credits)



## OS Details

* [macOS](www.apple.com/macos/) - OSX [Snow Leopard](www.apple.com/support/snowleopard/) (10.5) onwards.
* [Linux](www.linux.com/) - [Debian](www.debian.org/)/[Ubuntu](www.ubuntu.com/), [Arch](https://archlinux.org/).
* [Windows](www.microsoft.com/en-us/windows/) - [Command shell](https://technet.microsoft.com/en-us/library/cc754340.aspx) and [Powershell](https://technet.microsoft.com/library/hh857337.aspx)



## macOS / Linux (Debian-based, Arch)

### What is included

* Aliases
* Functions
* Shell options: Bash / Zsh
* Shell theme: Bash / Zsh
* Shell packages: macOS (Homebrew), Debian (apt), Arch (pacman)
* ZSH configuration
* Git configuration
* Tmux configuration
* Vim configuration

### Installation

The setup script will configure shell options, theme, aliases, functions, and packages.
The setup script will ask whether to run each of the optional steps.
There is option to change the default shell to [Zsh](www.zsh.org/).

**Note**: Dotfiles default location is `$HOME/dotfiles`. If you want to change it, specify a different directory prior to running the setup scripts by setting the `dotdir` variable: `export dotdir=$HOME/path/to/my/dotfiles`

```sh
# OSX
cd $HOME
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" # Homebrew
brew install git
git clone https://github.com/jivkok/dotfiles.git dotfiles
./dotfiles/setup.sh

# Linux (Debian-based)
cd $HOME
sudo apt-get install -y git
git clone https://github.com/jivkok/dotfiles.git dotfiles
./dotfiles/setup.sh

# Linux (Arch)
cd $HOME
sudo pacman -S --noconfirm git
git clone https://github.com/jivkok/dotfiles.git dotfiles
./dotfiles/setup.sh
```


### Customizations

#### Specify custom `$PATH`

If `$HOME/.path` exists, it will be sourced along with the other files.

#### Custom commands without creating a new fork

If `$HOME/.profile.local` exists, it will be sourced along with the other files. You can use this to add custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.
Since `$HOME/.profile.local` is sourced at the end, it allows for overriding of existing settings, functions, and aliases.

### Upgrade

```sh
cd ~/dotfiles
git pull
```



## Windows (Command shell and Powershell)

### What is included

* Packages with [Chocolatey](https://chocolatey.org/)
* Command shell / Powershell setup
* Console configuration
* Command shell configuration
* Powershell configuration

### Installation

The setup script will install packages with Chocolatey, configure a multi-tabbed console and its desktop shortcut, and configure system options / theme / aliases / functions.

**Note**: run the shell commands from an elevated shell.

#### Option #1 (concise, with Boxstarter & Chocolatey)

Open [http://j.mp/jivkokshell](http://j.mp/jivkokshell) in a browser. It is same as:

```bat
START http://boxstarter.org/package/nr/url?https://raw.githubusercontent.com/jivkok/Chocolatey-Packages/master/jivkok.Shell/shell.boxstarter.ps1
```

#### Option #2 (concise)

```bat
rem With Command shell:
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/jivkok/dotfiles/master/setup/setup.ps1'))"
```

```posh
# With Powershell:
Set-ExecutionPolicy Bypass
iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/jivkok/dotfiles/master/setup/setup.ps1'))
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
@powershell -NoProfile -ExecutionPolicy Bypass -File %USERPROFILE%\dotfiles\setup\setup.ps1
```

```posh
# With Powershell:
git clone https://github.com/jivkok/dotfiles.git $HOME\dotfiles
. $HOME\dotfiles\setup\setup.ps1
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
* Rob Reynolds for [Chocolatey.org](https://chocolatey.org/)
* Matt Wrock for [boxstarter.org](https://boxstarter.org/)
