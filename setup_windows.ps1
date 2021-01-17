param (
  [string]$dotfiles = "$HOME\dotfiles"
)

function InstallChocolatey() {
  if (!(Test-Path Env:ChocolateyInstall)) {
    Write-Output 'Installing Chocolatey ...'
    Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
    Write-Output 'Installing Chocolatey done.'
    Write-Output ''
  }
}

function InstallChocolateyPackage($package, $source) {
  if (Test-Path "$Env:ChocolateyInstall\lib\$package") {
    if ($null -eq $source) {
      & cup "$package"
    }
    else {
      & cup "$package" -source "$source"
    }
  }
  else {
    if ($null -eq $source) {
      & cinst -y "$package"
    }
    else {
      & cinst -y "$package" -source "$source"
    }
  }
}

function Get-CurrentDirectory {
  $thisName = $MyInvocation.MyCommand.Name
  [IO.Path]::GetDirectoryName((Get-Content function:$thisName).File)
}

function New-Shortcut($ShortcutPath, $TargetPath, $Arguments, $IconLocation) {
  $WshShell = New-Object -comObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
  $Shortcut.TargetPath = $TargetPath
  $Shortcut.Arguments = $Arguments
  $Shortcut.IconLocation = $IconLocation
  $Shortcut.Save()
}

function PinToTaskBar($filePath) {
  if (!(Test-Path $filePath)) {
    Write-Warning "$filePath does not exist."
    return
  }

  $folder = Split-Path $filePath -Parent
  $fileName = Split-Path $filePath -Leaf

  $shellApp = New-Object -c Shell.Application
  $folderItem = $shellApp.Namespace($folder).ParseName($fileName)
  $folderItem.InvokeVerb('taskbarpin')
}

function CreateDirectorySymlink($folder, $srcPath, $destPath) {
  if (!(Test-Path "$srcPath\$folder")) {
    Write-Warning "$srcPath\$folder does not exist."
    return
  }

  if (Test-Path "$destPath\$folder") {
    if (Test-Path "$destPath\$folder.BACKUP") { cmd /c "rd $destPath\$folder.BACKUP" }
    Rename-Item "$destPath\$folder" "$destPath\$folder.BACKUP" -Force
  }

  cmd /c "mklink /D $destPath\$folder $srcPath\$folder"
}

function CreateFileSymlink($file, $srcPath, $destPath) {
  if (!(Test-Path "$srcPath\$file")) {
    Write-Warning "$srcPath\$file does not exist."
    return
  }

  if (Test-Path "$destPath\$file") {
    if (Test-Path "$destPath\$file.BACKUP") { Remove-Item "$destPath\$file.BACKUP" -Force }
    Rename-Item "$destPath\$file" "$destPath\$file.BACKUP" -Force
  }

  cmd /c "mklink $destPath\$file $srcPath\$file"
}

function InstallFont($fontFileName) {
  $fontPath = [IO.Path]::Combine($dotfiles, 'fonts', $fontFileName)
  $ssfFonts = 0x14
  $Shell = New-Object -ComObject Shell.Application
  $SystemFontsFolder = $Shell.Namespace($ssfFonts)
  $SystemFontsPath = $SystemFontsFolder.Self.Path
  
  $targetPath = Join-Path $SystemFontsPath $fontFileName
  if(Test-Path $targetPath) {
    Remove-Item $targetPath -Force
    Copy-Item $fontPath $targetPath -Force
  } else {
    $SystemFontsFolder.CopyHere($fontPath)
  }
}

try {
  # Workaround for not having Git on the path right after install
  $Env:Path += ";$ProgramW6432\Git\cmd;$ProgramFiles(x86)\Git\cmd"

  # Install packages
  InstallChocolatey

  InstallChocolateyPackage 'pwsh' # Latest Powershell
  InstallChocolateyPackage 'console2' # when no Windows Terminal is available
  InstallChocolateyPackage 'microsoft-windows-terminal'

  InstallChocolateyPackage 'git' # Source code control
  InstallChocolateyPackage 'poshgit' # Git helpers for Powershell
  InstallChocolateyPackage 'lazygit' # Terminal UI for git
  InstallChocolateyPackage 'kdiff3' # diff/merge. Also: git-cola, smartgit, gitkraken
  InstallChocolateyPackage 'jivkok.GitConfig' 'http://www.myget.org/F/jivkok-chocolatey'

  # Terminal prompt themes: https://ohmyposh.dev. Not used at the moment - I have created a simple theme in place.

  InstallChocolateyPackage 'lf' # File manager, Vim-inspired, like Ranger

  InstallChocolateyPackage 'fzf' # CLI text fuzzy finder
  Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
  Install-Module PSFzf -Scope CurrentUser

  InstallChocolateyPackage 'vscode' # Code/markup/text editor

  # find git.exe
  $git_exe = 'git.exe'
  if ($null -eq (Get-Command $git_exe -ErrorAction SilentlyContinue)) {
    if (Test-Path "${Env:ProgramW6432}\Git\bin\git.exe") {
      $git_exe = "${Env:ProgramW6432}\Git\bin\git.exe"
    }
    elseif (Test-Path "${Env:ProgramFiles(x86)}\Git\bin\git.exe") {
      $git_exe = "${Env:ProgramFiles(x86)}\Git\bin\git.exe"
    }
    else {
      throw 'Could not find git.exe'
    }
  }

  Write-Output 'Pulling latest dotfiles'
  if (Test-Path "$dotfiles\.git") {
    . $git_exe -C $dotfiles pull --quiet --prune --recurse-submodules 2> $null
    . $git_exe -C $dotfiles submodule init --quiet 2> $null
    . $git_exe -C $dotfiles submodule update --quiet --remote --recursive 2> $null
  }
  else {
    if (Test-Path $dotfiles) {
      if (Test-Path "$dotfiles.BACKUP") { Remove-Item "$dotfiles.BACKUP" -Recurse -Force }
      Rename-Item $dotfiles "$dotfiles.BACKUP" -Force
    }
    . $git_exe clone --quiet --recursive https://github.com/jivkok/dotfiles.git $dotfiles 2> $null
  }

  $windowsPath = Join-Path $dotfiles 'windows'
  if (!(Test-Path $windowsPath)) {
    throw "Required directory not found: $windowsPath"
  }

  $setenvref = '. ' + $([IO.Path]::Combine($dotfiles, 'windows', 'SetEnv.ps1')).Replace("$HOME", '$HOME')
  if (Test-Path $PROFILE) {
    if ($null -eq $(Select-String -Path $PROFILE -Pattern 'SetEnv.ps1')) {
      Write-Output "Adding SetEnv.ps1 to $PROFILE"
      Add-Content $PROFILE ("`n" + $setenvref)
    }
  }
  else {
    New-Item -Path $PROFILE -ItemType "file" -Force -Value $setenvref
  }

  Write-Output "Desktop shortcut (and taskbar pin): $Home\Desktop\Shell.lnk ==> $Env:ChocolateyInstall\bin\Console.exe"
  New-Shortcut "$Home\Desktop\Shell.lnk" "$Env:ChocolateyInstall\bin\Console.exe" "-c $windowsPath\console.xml" "cmd.exe,0"
  PinToTaskBar "$Home\Desktop\Shell.lnk"

  Write-Output 'Creating symlinks'
  CreateFileSymlink 'AutoHotkey.ahk' $windowsPath "$Home\Documents"

  # System configuration
  Import-Module (Join-Path $windowsPath BoxStarter.psm1)
  Disable-ShutdownTracker
  Disable-InternetExplorerESC
  Set-ExplorerOptions -showHidenFilesFoldersDrives $true -showProtectedOSFiles $true -showFileExtensions $true
  # Enable-RemoteDesktop
  # Set-TaskbarSmall
  # Restart-Explorer

  # Fonts
  Write-Output 'Installing font "Inconsolata-g for Powerline"'
  InstallFont 'Inconsolata-g for Powerline.otf'

  # Environment variables
  Write-Output 'Setting environment variable _NT_SYMBOL_PATH'
  [Environment]::SetEnvironmentVariable("_NT_SYMBOL_PATH", "srv*C:\Symbols*http://referencesource.microsoft.com/symbols*http://srv.symbolsource.org/pdb/Public*http://msdl.microsoft.com/download/symbols", "User")

  Write-Output 'Done.'
  Write-Output ''
}
catch {
  Write-Error "$_"
  throw
}
