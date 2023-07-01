# VSCode Personal Settings


## Manual steps

1. Copy `settings.json`, `keybindings.json` to the appropriate OS path (see sections below for details). Cherry-pick settings as needed (by language, extension, etc.)
2. Install extensions - either manually, or with `code --install-extension extension-name` / `code --uninstall-extension ms-vscode.csharp` / `code --list-extensions`.
3. Reopen VSCode to activate extensions.


## Misc
For settings-per-workspace, the settings file is located under a `.vscode` folder in that project.


## Settings Locations by OS
Depending on the OS, the user settings.json (and other config files like `keybindings.json`) are located at this path:

- Windows: `$env:APPDATA\Code\User`
- Mac: `$HOME/Library/Application Support/Code/User`
- Linux: `$HOME/.config/Code/User`


## Extensions

### Common

- [Bookmarks](https://marketplace.visualstudio.com/items?itemName=alefragnani.Bookmarks)
- [Code Ace Jumper](https://marketplace.visualstudio.com/items?itemName=lucax88x.codeacejumper)
- [Docker](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)
- [EditorConfig](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig)
- [Linter](https://marketplace.visualstudio.com/items?itemName=fnando.linter)
- [Makefile Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.makefile-tools)
- [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one)
- [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)
- [Remote - SSH: Editing Configuration Files](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-edit)
- [Remote Explorer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer)
- [shell-format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format)

### Themes

- [Theme - Oceanic Next](https://marketplace.visualstudio.com/items?itemName=naumovs.theme-oceanicnext)

### C#

- [C#](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csharp)

### Python

- [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance)
- [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python)

### YAML

- [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)
