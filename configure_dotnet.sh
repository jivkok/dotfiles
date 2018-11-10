#!/bin/bash
# DotNet configuration

# $1 - message
function echo2 ()
{
    echo -e "\n$1\n"
}

echo2 'Configuring DotNet ...'

os=$(uname -s)

if [ "$os" = "Linux" ]; then
    sudo sh -c 'echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet/ trusty main" > /etc/apt/sources.list.d/dotnetdev.list'
    sudo apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893
    sudo apt-get update
    sudo apt-get install dotnet-dev-1.0.0-preview1-002702
elif [ "$os" = "Darwin" ]; then
    echo2 Prerequisites
    brew update
    brew install libuv openssl
    brew link --force openssl

    echo2 "Cleaning up previous DotNet versions"
    curl -s https://raw.githubusercontent.com/dotnet/cli/master/scripts/obtain/uninstall/dotnet-uninstall-pkgs.sh | sudo bash

    echo2 "Installing the DotNet package"
    wget -O "${TMPDIR}dotnet.pkg" "https://download.microsoft.com/download/E/8/A/E8AF2EE0-5DDA-4420-A395-D1A50EEFD83E/dotnet-sdk-2.1.401-osx-gs-x64.pkg"
    sudo installer -verboseR -pkg "${TMPDIR}dotnet.pkg" -target /
    rm "${TMPDIR}dotnet.pkg"

    dotnet tool install --global coverlet.console

    cask install visual-studio-code
else
    echo2 "Unsupported OS: $os"
    return
fi

echo2 'Configuring DotNet done.'
