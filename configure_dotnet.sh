#!/bin/bash
# DotNet configuration

# $1 - message
function echo2 ()
{
    echo -e "\n$1\n"
}

echo2 'Configuring DotNet ...'

os=$(uname -s)

# https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script
if [ "$os" = "Linux" ]; then
    bash <(curl -s https://dot.net/v1/dotnet-install.sh) -Channel Current -NoPath
elif [ "$os" = "Darwin" ]; then
    bash <(curl -s https://dot.net/v1/dotnet-install.sh) -Channel Current -NoPath

    ~/.dotnet/dotnet tool install --global coverlet.console

    cask install visual-studio-code
else
    echo2 "Unsupported OS: $os"
    return
fi

echo2 'Configuring DotNet done.'
