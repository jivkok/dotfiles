#!/bin/bash
# Configure Alfred workflows (http://www.alfredapp.com/)

# $1 - workflow url
function install_alfred_workflow() {
  alfred_dir="$HOME/alfred-workflows"
  mkdir -p "$alfred_dir"

  workflow_url="$1"
  workflow_name=$(echo "$workflow_url" | perl -lne 'print $& if /([^\/]+)\.alfredworkflow/')

  dot_trace "Downloading $workflow_url"
  curl -L -o "$alfred_dir/$workflow_name" "$workflow_url"

  dot_trace "Installing $workflow_name ..."
  open "$alfred_dir/$workflow_name"
  sleep 20
}

# dotdir="$( cd "$( dirname "$0" )" && pwd )"
[ -z "$dotdir" ] && dotdir="$HOME/dotfiles"

source "$dotdir/setupfunctions.sh"

dot_trace "Configuring Alfred workflows ..."

cask_install_package alfred

# Awesome Lists
install_alfred_workflow 'https://github.com/nikitavoloboev/alfred-awesome-lists/releases/download/v1.0.5/Awesome.lists.alfredworkflow'

# Can I Use
install_alfred_workflow 'https://raw.github.com/willfarrell/alfred-caniuse-workflow/master/caniuse.alfredworkflow'

# Coffee
install_alfred_workflow 'https://github.com/vitorgalvao/alfred-workflows/raw/master/CoffeeCoffee/CoffeeCoffee.alfredworkflow'

# Dash workflow is installed from Dash directly: Preferences > Integration > Alfred

# DevDocs.io
install_alfred_workflow 'https://github.com/packal/repository/raw/master/com.yannickglt.alfred2.devdocs/devdocs.alfredworkflow'

# Dig
install_alfred_workflow 'https://github.com/phallstrom/AlfredDig/raw/master/Dig.alfredworkflow'

# Encode Decode
install_alfred_workflow 'https://github.com/willfarrell/alfred-encode-decode-workflow/raw/master/encode-decode.alfredworkflow'

# Font Awesome
install_alfred_workflow 'https://github.com/ruedap/alfred-font-awesome-workflow/raw/master/Font-Awesome.alfredworkflow'

# GitHub
install_alfred_workflow 'https://github.com/gharlan/alfred-github-workflow/releases/download/v1.6.2/github.alfredworkflow'

# HackerNews and Pinboard
install_alfred_workflow 'https://github.com/vitorgalvao/alfred-workflows/raw/master/HackerBoard/HackerBoard.alfredworkflow'

# Hash
install_alfred_workflow 'https://github.com/willfarrell/alfred-hash-workflow/raw/master/Hash.alfredworkflow'

# Homebrew
install_alfred_workflow 'https://github.com/fniephaus/alfred-homebrew/releases/download/v4.5/Homebrew-for-Alfred.alfredworkflow'

# Http Status Code
install_alfred_workflow 'https://github.com/ilstar/http_status_code/releases/download/v0.2.2/HTTP.Status.Code.alfredworkflow'

# Network Info
install_alfred_workflow 'https://github.com/packal/repository/raw/master/com.tedwise.networkinfo/network_info.alfredworkflow'

# Package Managers
install_alfred_workflow 'https://github.com/willfarrell/alfred-pkgman-workflow/releases/download/3.40/Package.Managers.alfredworkflow'

# Process Control
install_alfred_workflow 'https://github.com/vitorgalvao/alfred-workflows/raw/master/ProcessControl/ProcessControl.alfredworkflow'

# Passwords generator
install_alfred_workflow 'https://github.com/deanishe/alfred-pwgen/raw/master/Password-Generator-2.1.2.alfredworkflow'

# Product Hunt
install_alfred_workflow 'https://github.com/loris/alfred-producthunt-workflow/raw/master/Product%20Hunt.alfredworkflow'

# Source Tree
install_alfred_workflow 'https://github.com/zhaocai/alfred2-sourcetree-workflow/raw/master/Source%20Tree.alfredworkflow'

# Stack Overflow
install_alfred_workflow 'https://github.com/deanishe/alfred-stackoverflow/releases/download/v1.2.1/StackOverflow-1.2.1.alfredworkflow'

# Synonyms & Antonyms
install_alfred_workflow 'https://github.com/vitorgalvao/alfred-workflows/raw/master/SynAnt/SynAnt.alfredworkflow'

# Timezones
install_alfred_workflow 'https://github.com/packal/repository/raw/master/carlosnz.timezones/timezones_v1.7a.alfredworkflow'

# TLDR
install_alfred_workflow 'https://github.com/cs1707/tldr-alfred/raw/master/tldr.alfredworkflow'

# UUIDGen
install_alfred_workflow 'https://github.com/eliasmaier/uuidgen.alfred/raw/master/UUIDGen.alfredworkflow'

dot_trace "Configuring Alfred workflows done."
