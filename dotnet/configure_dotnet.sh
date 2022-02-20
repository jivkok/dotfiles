#!/usr/bin/env bash
# Install .Net

# $1 - message
function echo2 ()
{
    echo -e "\n$1\n"
}

echo2 'Configuring DotNet ...'

os=$(uname -s)

# https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script
if [ "$os" = "Linux" ]; then
    # bash <(curl -sSL https://dot.net/v1/dotnet-install.sh) --channel LTS --no-path --dry-run
    bash <(curl -sSL https://dot.net/v1/dotnet-install.sh) --channel LTS --no-path

    # The above install all artifacts for the current user. Use this for system-wide install:
    # wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
    # sudo dpkg -i /tmp/packages-microsoft-prod.deb
    # sudo apt-get install -y dotnet-sdk-3.1
elif [ "$os" = "Darwin" ]; then
    bash <(curl -sSL https://dot.net/v1/dotnet-install.sh) --channel LTS --no-path

    ~/.dotnet/dotnet tool install --global coverlet.console

    cask install visual-studio-code
else
    echo2 "Unsupported OS: $os"
    return
fi

echo2 'Configuring DotNet done.'
