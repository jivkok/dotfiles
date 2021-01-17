$env:PLINK_PROTOCOL = "ssh"
$env:EDITOR = "Notepad"

# Aliases

function .. { Push-Location .. }
function ... { Push-Location ..\.. }
function .... { Push-Location ..\..\.. }
function l { Get-ChildItem -Name $args }
function ll { Get-ChildItem -Force $args }
function n { notepad $args }
function qg { Start-Process "http://www.google.com/#q=$args" }
function b { msbuild $args }
function x { exit }
Set-Alias e code
Set-Alias g git

function fs {
    if (!$args) {
        Write-Output 'Usage: fs <pattern> <path>'
        return;
    }
    $pattern = $args[0]
    $path = Split-Path -Path $args[0] -Parent
    if ($args.length -gt 1) {
        $path = $args[1]
    }
    else {
        $path = '.\*.*'
    }
    Get-ChildItem -Path $path -Recurse | Select-String -pattern $pattern
}

function ff {
    if (!$args) {
        Get-ChildItem -Recurse | Select-Object Fullname
        return;
    }
    $path = Split-Path -Path $args[0] -Parent
    if ($path.length -eq 0) {
        $path = '.'
    }
    $filter = Split-Path -Path $args[0] -Leaf
    if ($filter.length -eq 0) {
        $filter = '*.*'
    }
    Get-ChildItem -Path $path -Filter $filter -Recurse | Select-Object Fullname
}

# Prompt

function ShortenPath([string] $path) {
    $loc = $path.Replace($HOME, '~')
    return $loc
}

function prompt {
    $originalLASTEXITCODE = $LASTEXITCODE

    $colorDelimiter = [ConsoleColor]::Gray
    $colorNames = [ConsoleColor]::DarkYellow
    $colorLocation = [ConsoleColor]::DarkGreen

    # Window Title
    $host.UI.RawUI.WindowTitle = "$env:USERNAME @ $env:COMPUTERNAME : $(Get-Location)"

    # Core text
    Write-Host
    Write-Host "$env:USERNAME" -NoNewline -ForegroundColor $colorNames
    Write-Host " @ " -NoNewline -ForegroundColor $colorDelimiter
    Write-Host ([net.dns]::GetHostName()) -NoNewline -ForegroundColor $colorNames
    Write-Host " : " -NoNewline -ForegroundColor $colorDelimiter
    # Show provider name if it is not the file system
    if ($pwd.Provider.Name -ne "FileSystem") {
        Write-Host "[" -NoNewline -ForegroundColor $colorDelimiter
        Write-Host (Get-Location).Provider.Name -NoNewline -ForegroundColor $colorDelimiter
        Write-Host "] " -NoNewline -ForegroundColor $colorDelimiter
    }
    Write-Host (ShortenPath (Get-Location).Path) -NoNewline -ForegroundColor $colorLocation

    # poshgit
    if (Test-Path Function:\Write-VcsStatus) {
        Write-VcsStatus
        $global:LASTEXITCODE = $originalLASTEXITCODE
    }

    Write-Host -f $colorDelimiter

    # Check for elevated prompt
    $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp = new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin = $prp.IsInRole($adm)
    if ($IsAdmin) {
        Write-Host "#" -NoNewline -ForegroundColor $colorDelimiter
    }
    else {
        Write-Host ">" -NoNewline -ForegroundColor $colorDelimiter
    }

    return ' '
}

# VS

if (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\Common7\Tools\VsDevCmd.bat") {
    Write-Output 'Setting VS 2019 environment ...'
    $vsEnvFile = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\Common7\Tools\VsDevCmd.bat"
}
elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\Common7\Tools\VsDevCmd.bat") {
    Write-Output 'Setting VS 2019 environment ...'
    $vsEnvFile = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\Common7\Tools\VsDevCmd.bat"
}
elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\Common7\Tools\VsDevCmd.bat") {
    Write-Output 'Setting VS 2019 environment ...'
    $vsEnvFile = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\Common7\Tools\VsDevCmd.bat"
}
elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio 15.0\Common7\Tools\VsDevCmd.bat") {
    Write-Output 'Setting VS 2017 environment ...'
    $vsEnvFile = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 15.0\Common7\Tools\VsDevCmd.bat"
}
elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\Tools\VsDevCmd.bat") {
    Write-Output 'Setting VS 2015 environment ...'
    $vsEnvFile = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\Tools\VsDevCmd.bat"
}
elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\Tools\VsDevCmd.bat") {
    Write-Output 'Setting VS 2013 environment ...'
    $vsEnvFile = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\Tools\VsDevCmd.bat"
}
elseif (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\Tools\VsDevCmd.bat") {
    Write-Output 'Setting VS 2012 environment ...'
    $vsEnvFile = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\Tools\VsDevCmd.bat"
}
if ($vsEnvFile) {
    cmd /c "`"$vsEnvFile`" & set" |
    ForEach-Object {
        if ($_ -match "(.*?)=(.*)") {
            Set-Item -force -path "ENV:\$($matches[1])" -value "$($matches[2])"
        }
    }
}

# FZF
if ((Get-Module -ListAvailable -Name "PSFzf") -and !(Get-Module -Name "PSFzf")) {
    Remove-PSReadlineKeyHandler 'Ctrl+r'
    Remove-PSReadlineKeyHandler 'Ctrl+t'
    Import-Module PSFzf
}

# Custom settings
if (Test-Path "$Home\profile.ps1") {
    . "$Home\profile.ps1"
}
