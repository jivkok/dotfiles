#!/bin/bash
# Configure Alfred workflows (http://www.alfredapp.com/)

# $1 - file
function install_alfred_workflow ()
{
    echo "Installing $1 ..."
    open "$1"
    sleep 20

    return
}

alfred_dir="$HOME/alfred-workflows"

# repo
if [ -d "$alfred_dir/.git" ]; then
    git -C "$alfred_dir" pull origin master
else
    if [ -d "$alfred_dir" ]; then
        mv "$alfred_dir" "${alfred_dir}.old"
    fi
    git clone https://github.com/jivkok/alfred-workflows "$alfred_dir"
fi

find "$alfred_dir" -iname "*.alfredworkflow" | while read -r file; do install_alfred_workflow "$file"; done

echo "Done."
