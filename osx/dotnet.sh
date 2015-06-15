#!/bin/sh

# DotNet utility
brew tap aspnet/dnx
brew update
brew install dnvm

# Node
brew install node

# Yeoman
npm install -g yo
npm install -g bower

# Yeoman generators
npm install -g generator-aspnet
npm install -g generator-csharp
