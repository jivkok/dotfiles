#!/bin/bash
# Configuring Brackets

function copy_config_file ()
{
    file=$1
    settingsDir=$2
    bracketsUserPath=$3

    if [ ! -f "$settingsDir/$file" ]; then
        dot_error "File $settingsDir/$file does not exist."
        return
    fi

    if [ -f "$bracketsUserPath/$file" ]; then
        dot_trace "Backing up $bracketsUserPath/$file   to   $bracketsUserPath/$file.old"
        mv -f "$bracketsUserPath/$file" "$bracketsUserPath/${file}.old"
    fi

    cp -f "$settingsDir/$file" "$bracketsUserPath/"
}

function install_extension ()
{
    bracketsUserExtensionsPath=$1
    extensionsRegistryPath=$2
    extensionDisplayName=$3

    dot_trace "Installing Brackets extension '$extensionDisplayName' ..."

    extensionName=$(cat "$extensionsRegistryPath" | jq ".[] | select(.metadata.title == \"$extensionDisplayName\").metadata.name" | sed 's/"//g')
    extensionVersion=$(cat "$extensionsRegistryPath" | jq ".[] | select(.metadata.title == \"$extensionDisplayName\").metadata.version" | sed 's/"//g')
    if [ -z "$extensionName" ]; then
        dot_error "Could not find package name within the registry"
        return
    fi
    if [ -z "$extensionVersion" ]; then
        dot_error "Could not find package version within the registry"
        return
    fi
    dot_trace "Found '$extensionDisplayName' in the registry. Name: $extensionName, version: $extensionVersion"

    extensionUrl="https://s3.amazonaws.com/extend.brackets/${extensionName}/${extensionName}-${extensionVersion}.zip"

    extensionZipPath="${TMPDIR}${extensionName}.zip"
    extensionZipDirPath="${TMPDIR}$extensionName"
    [ -f "$extensionZipPath" ] && rm -f "$extensionZipPath"
    [ -d "$extensionZipDirPath" ] && rm -rf "$extensionZipDirPath"

    dot_trace "Downloading $extensionUrl   to   $extensionZipPath"
    curl -o "$extensionZipPath" "$extensionUrl"
    if [ ! -f "$extensionZipPath" ]; then
        dot_error "Download failed - $extensionUrl"
        return
    fi
    dot_trace "Unzipping $extensionZipPath   to   $extensionZipDirPath"
    unzip -q "$extensionZipPath" -d "$extensionZipDirPath"

    packagejsonPath=$(find "$extensionZipDirPath" -maxdepth 2 -iname package.json | head -n 1)
    if [ -z "$packagejsonPath" ]; then
        dot_error "Could not find package.json in $extensionZipDirPath"
        return
    fi
    extensionTempDirPath=$(dirname "$packagejsonPath")

    if [ -d "$bracketsUserExtensionsPath/$extensionName" ]; then
        dot_trace "Deleting old extension content: $bracketsUserExtensionsPath/$extensionName"
        rm -rf "$bracketsUserExtensionsPath/$extensionName"
    fi
    dot_trace "Copying $extensionTempDirPath/   to   $bracketsUserExtensionsPath/$extensionName/"
    cp -L -r "$extensionTempDirPath/" "$bracketsUserExtensionsPath/$extensionName/"

    dot_trace "Installing Brackets extension '$extensionDisplayName' done."
}

# dotdir="$( cd "$( dirname "$0" )" && pwd )"
[ -z "$dotdir" ] && dotdir="$HOME/dotfiles"

source "$dotdir/setupfunctions.sh"

dot_trace "Configuring Brackets ..."

os=$(uname -s)
if [ "$os" = "Darwin" ]; then
    cask_install_package brackets
    brew_install_package jq

    bracketsUserPath="$HOME/Library/Application Support/Brackets"
    bracketsUserExtensionsPath="$HOME/Library/Application Support/Brackets/extensions/user"
    scriptdir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    settingsDir="$scriptdir/brackets"

    for f in brackets.json keymap.json
    do
        copy_config_file $f "$settingsDir" "$bracketsUserPath"
    done

    extensionsRegistryPath="${TMPDIR}registry.json"
    dot_trace "Downloading Brackets extensions registry   https://s3.amazonaws.com/extend.brackets/registry.json   to   $extensionsRegistryPath"
    curl -H "Accept-Encoding: gzip, deflate" https://s3.amazonaws.com/extend.brackets/registry.json | gunzip - > "$extensionsRegistryPath"

    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "AngularJS for Brackets" # QuickEdit for directives, controllers, and services
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Autoprefixer" # Parse CSS and add vendor prefixes automatically
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Autosave Files on Window Blur" # Autosave all open files when switching applications
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Beautify" # Format JavaScript, HTML, and CSS files
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Bootstrap Skeleton" # Add a Bootstrap Skeleton to your page.
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Brackets Bower" # Manage your application's front-end dependencies using Bower
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Brackets Git" # Integration of Git into Brackets
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Brackets Icons" # File icons in Brackets' file tree
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Brackets Snippets (by edc)" # Imitate Sublime Text's behavior of snippets, and bring it to Brackets
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "CanIUse" # Add a panel that renders CanIUse.com data
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Display Shortcuts" # Display current shortcuts in a bottom panel that can be sorted and filtered. Add and disable shortcuts from context menu
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "EditorConfig" # Supporting EditorConfig features
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Emmet" # High-speed HTML and CSS workflow
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "File Tree Exclude" # Excludes folders from the Brackets file system to avoid the 30,000 file limit
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "FTP-Sync Plus" # FTP/SFTP upload for Brackets
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "FuncDocr" # Generates JSDoc, PHPDoc annotations for your functions
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Indent Guides" # Show indent guides in the code editor
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Interactive Linter" # Interactive linting for Brackets
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Lorem Pixel" # Generate placeholder images for every case
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Markdown Preview" # Live preview of markdown documents
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Minimap" # Minimap like in Sublime Text
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Numbered Bookmarks" # Bookmark lines in the editor (CTRL+SHIFT+1 ... CTRL+SHIFT+9) as you work so you can quickly jump back to them later (CTRL+1 ... CTRL+9). Delete all: CTRL+SHIFT+DELETE
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "QuickDocsJS" #
    # Themes
    install_extension "$bracketsUserExtensionsPath" "$extensionsRegistryPath" "Monokai Dark Soda" # Dark theme based on Dark Soda and Monokai color schemes
    # install_extension "" $bracketsUserExtensionsPath/"
else
    echo "Unsupported OS: $os"
fi

unset -f copy_config_file
unset -f install_extension

dot_trace "Configuring Brackets done."
