#!/usr/bin/env bash
# Configure HOME bin directory content

function download_to_bin ()
{
    local filename="$1"
    local download_url="$2"

    echo "$download_url"
    curl -s -o "$HOME/bin/$filename" "$download_url"
    chmod 755 "$HOME/bin/$filename"
}

dotdir="$( cd "$( dirname "$0" )" && pwd )"
source "$dotdir/setupfunctions.sh"

dot_trace "Configuring HOME bin folder ..."

mkdir -p "$HOME/bin"

download_to_bin "git-prompt.sh" "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh"
download_to_bin "diff-so-fancy" "https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy"
download_to_bin "prettyping" "https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping"

dot_trace "Configuring HOME bin folder done."
