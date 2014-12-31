#!/bin/bash
# Configure Alfred workflows (http://www.alfredapp.com/)

# $1 - file
function install_alfred_workflow ()
{
    echo "Installing $1 ..."
    open $1
    sleep 20

    return
}

cd $HOME

# repo
if [ -d alfred-workflows/.git ]; then
    cd alfred-workflows
    git pull origin master
    cd ..
else
    if [ -d alfred-workflows ]; then
        mv alfred-workflows alfred-workflows.old
    fi
    git clone https://github.com/jivkok/alfred-workflows alfred-workflows
fi

find alfred-workflows -iname "*.alfredworkflow" | while read file; do install_alfred_workflow "$file"; done

echo "Done."
