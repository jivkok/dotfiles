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
  $scriptPath = Get-CurrentDirectory
  $windowsPath = Join-Path $scriptPath 'windows'
  if (!(Test-Path $windowsPath)) {
    throw "Required folder not found: $windowsPath"
  }

  # Workaround for not having Git on the path right after install
  $Env:Path += ";$ProgramFiles(x86)\Git\cmd"

  # Chocolatey and package dependencies
  InstallChocolatey
  InstallChocolateyPackage 'powershell'
  InstallChocolateyPackage 'console2'
  InstallChocolateyPackage 'git'
  InstallChocolateyPackage 'poshgit'
  InstallChocolateyPackage 'psget'
  InstallChocolateyPackage 'jivkok.SublimeText3.Packages' 'http://www.myget.org/F/jivkok-chocolatey'
  InstallChocolateyPackage 'jivkok.GitConfig' 'http://www.myget.org/F/jivkok-chocolatey'

  echo "Desktop shortcut (and taskbar pin): $Home\Desktop\Shell.lnk ==> $Env:ChocolateyInstall\bin\Console.exe"
  New-Shortcut "$Home\Desktop\Shell.lnk" "$Env:ChocolateyInstall\bin\Console.exe" "-c $windowsPath\console.xml" "cmd.exe,0"
  PinToTaskBar "$Home\Desktop\Shell.lnk"

  # Bash
  $destPath = "$Home"
  CreateDirectorySymlink '.vim' $scriptPath $destPath
  CreateFileSymlink '.aliases' $scriptPath $destPath
  CreateFileSymlink '.bash_profile' $scriptPath $destPath
  CreateFileSymlink '.bash_prompt' $scriptPath $destPath
  CreateFileSymlink '.bashrc' $scriptPath $destPath
  CreateFileSymlink '.curlrc' $scriptPath $destPath
  CreateFileSymlink '.exports' $scriptPath $destPath
  CreateFileSymlink '.functions' $scriptPath $destPath
  CreateFileSymlink '.tmux.conf' $scriptPath $destPath
  CreateFileSymlink '.vimrc' "$scriptPath\.vim" $destPath
  CreateFileSymlink '.wgetrc' $scriptPath $destPath
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
