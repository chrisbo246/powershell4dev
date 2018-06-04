[CmdletBinding()]
param(
  [parameter(Mandatory = $False)][string]$ChocolateyList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\chocolatey.lst"),
  [parameter(Mandatory = $False)][string]$PacmanList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\pacman.lst"),
  [parameter(Mandatory = $False)][string]$NpmList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\npm.lst"),
  [parameter(Mandatory = $False)][string]$GemList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\gem.lst"),
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\path.lst"),
  [parameter(Mandatory = $False)][string]$ProjectList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\project.lst")
)

$Location = Get-Location

# Ensure this script is running with admin privileges
if (-not (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) {
  Write-Warning "This script must be executed with administrator privileges."
  Exit
}

# Install chocolatey (package manager for Windows).
if (-Not (Get-Command "choco" -errorAction SilentlyContinue)) {
  Set-ExecutionPolicy Bypass -Scope Process -Force
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  refreshenv
}

# Install Windows softwares.
Get-Content -ErrorAction SilentlyContinue -Path $ChocolateyList | Foreach {
  choco install $_ -y
}

# Add missing paths to the path environment variable
Get-Content -ErrorAction SilentlyContinue -Path $PathList | Foreach {
  if (Test-Path $_) {
    Add-PathVariable $_
  } else {
    Write-Warning "$_ does not exists."
  }
}

# Update environment variables
refreshenv

# Install pacman packages
msys2 pacman -Syuu
Get-Content -ErrorAction SilentlyContinue -Path $PacmanList | Foreach {
  msys2 pacman -S --needed $_
}

# Install global NPMs.
Get-Content -ErrorAction SilentlyContinue -Path $NpmList | Foreach {
  npm install -g $_
}

# Install GEMs.
Get-Content -ErrorAction SilentlyContinue -Path $GemList | Foreach {
  gem install $_
}

# Install local projects dependencies.
Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
  if (Test-Path $_) {
    Set-Location $_
    if ((Get-Command "yarn" -ErrorAction SilentlyContinue) -and (Test-Path "yarn.lock")) {
      Write-Host "Starting NPM/Bower packages installation (with Yarn) in $_." -foreground cyan
      yarn install
    } else {
      if ((Get-Command "npm" -ErrorAction SilentlyContinue) -and (Test-Path "package.json")) {
        Write-Host "Starting NPM packages installation in $_." -foreground cyan
        npm install
      }
      if ((Get-Command "bower" -ErrorAction SilentlyContinue) -and (Test-Path "bower.json")) {
        Write-Host "Starting Bower packages installation in $_." -foreground cyan
        bower install
      }
    }
    if ((Get-Command "gem" -ErrorAction SilentlyContinue) -and (Test-Path "Gemfile")) {
      Write-Host "Starting GEM packages installation in $_." -foreground cyan
      gem install
    }
  }
}
Set-Location $Location

# Install Linux / Ubuntu
#lxrun /install

# Update environment variables
refreshenv
