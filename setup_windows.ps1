param (
    [string]$dotfiles = "$HOME\dotfiles"
)

function InstallChocolatey()
{
  if (!(Test-Path Env:ChocolateyInstall)) {
    echo 'Installing Chocolatey ...'
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
    echo 'Installing Chocolatey done.'
    echo ''
  }
}

function InstallChocolateyPackage($package, $source)
{
  if (Test-Path "$Env:ChocolateyInstall\lib\$package") { return }

  if ($source -eq $null) {
    echo "Installing $package"
    & cinst.exe $package -y
  } else {
    echo "Installing $package from $source"
    & cinst.exe $package -y -source $source
  }
}

function Get-CurrentDirectory
{
  $thisName = $MyInvocation.MyCommand.Name
  [IO.Path]::GetDirectoryName((Get-Content function:$thisName).File)
}

function New-Shortcut($ShortcutPath, $TargetPath, $Arguments, $IconLocation)
{
  $WshShell = New-Object -comObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
  $Shortcut.TargetPath = $TargetPath
  $Shortcut.Arguments = $Arguments
  $Shortcut.IconLocation = $IconLocation
  $Shortcut.Save()
}

function PinToTaskBar($filePath)
{
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

function CreateDirectorySymlink($folder, $srcPath, $destPath)
{
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

function CreateFileSymlink($file, $srcPath, $destPath)
{
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

try {
  # Workaround for not having Git on the path right after install
  $Env:Path += ";$ProgramW6432\Git\cmd;$ProgramFiles(x86)\Git\cmd"

  # Chocolatey and package dependencies
  InstallChocolatey
  InstallChocolateyPackage 'powershell'
  InstallChocolateyPackage 'console2'
  InstallChocolateyPackage 'git'
  InstallChocolateyPackage 'poshgit'
  InstallChocolateyPackage 'psget'
  InstallChocolateyPackage 'jivkok.SublimeText3.Packages' 'http://www.myget.org/F/jivkok-chocolatey'
  InstallChocolateyPackage 'jivkok.GitConfig' 'http://www.myget.org/F/jivkok-chocolatey'

  # find git.exe path
  $git_exe = 'git.exe'
  if ((Get-Command $git_exe -ErrorAction SilentlyContinue) -eq $null) {
    if (Test-Path "${Env:ProgramW6432}\Git\bin\git.exe") {
      $git_exe = "${Env:ProgramW6432}\Git\bin\git.exe"
    } else if (Test-Path "${Env:ProgramFiles(x86)}\Git\bin\git.exe") {
      $git_exe = "${Env:ProgramFiles(x86)}\Git\bin\git.exe"
    } else {
      throw 'Could not find git.exe'
    }
  }

  echo 'dotfiles repo'
  if (Test-Path "$dotfiles\.git") {
    . $git_exe -C $dotfiles pull --quiet --prune --recurse-submodules 2> $null
    . $git_exe -C $dotfiles submodule init --quiet 2> $null
    . $git_exe -C $dotfiles submodule update --quiet --remote --recursive 2> $null
  } else {
    if (Test-Path $dotfiles) {
      if (Test-Path "$dotfiles.BACKUP") { Remove-Item "$dotfiles.BACKUP" -Recurse -Force }
      Rename-Item $dotfiles "$dotfiles.BACKUP" -Force
    }
    . $git_exe clone --quiet --recursive https://github.com/jivkok/dotfiles.git $dotfiles 2> $null
  }

  $windowsPath = Join-Path $dotfiles 'windows'
  if (!(Test-Path $windowsPath)) {
    throw "Required folder not found: $windowsPath"
  }

  echo "Desktop shortcut (and taskbar pin): $Home\Desktop\Shell.lnk ==> $Env:ChocolateyInstall\bin\Console.exe"
  New-Shortcut "$Home\Desktop\Shell.lnk" "$Env:ChocolateyInstall\bin\Console.exe" "-c $windowsPath\console.xml" "cmd.exe,0"
  PinToTaskBar "$Home\Desktop\Shell.lnk"

  echo 'Bash symlinks'
  $destPath = "$Home"
  CreateDirectorySymlink '.vim' $dotfiles $destPath
  CreateFileSymlink '.aliases' $dotfiles $destPath
  CreateFileSymlink '.bash_profile' $dotfiles $destPath
  CreateFileSymlink '.bash_prompt' $dotfiles $destPath
  CreateFileSymlink '.bashrc' $dotfiles $destPath
  CreateFileSymlink '.curlrc' $dotfiles $destPath
  CreateFileSymlink '.editorconfig' $dotfiles $destPath
  CreateFileSymlink '.exports' $dotfiles $destPath
  CreateFileSymlink '.functions' $dotfiles $destPath
  CreateFileSymlink '.tmux.conf' $dotfiles $destPath
  CreateFileSymlink '.vimrc' "$dotfiles\.vim" $destPath
  CreateFileSymlink '.wgetrc' $dotfiles $destPath
  echo "Git prompt: https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh ==> $Home\git-prompt.sh"
  (New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh', "$Home\git-prompt.sh")

  # System configuration
  Import-Module (Join-Path $windowsPath BoxStarter.psm1)
  Disable-ShutdownTracker
  Disable-InternetExplorerESC
  Set-ExplorerOptions -showHidenFilesFoldersDrives $true -showProtectedOSFiles $true -showFileExtensions $true
  Enable-RemoteDesktop
  # Set-TaskbarSmall
  # Restart-Explorer

  # Environment variables
  echo 'Setting environment variable _NT_SYMBOL_PATH'
  [Environment]::SetEnvironmentVariable("_NT_SYMBOL_PATH", "srv*C:\Symbols*http://referencesource.microsoft.com/symbols*http://srv.symbolsource.org/pdb/Public*http://msdl.microsoft.com/download/symbols", "User")

  echo 'Done.'
  echo ''
} catch {
  Write-Error "$_"
  throw
}
