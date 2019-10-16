[CmdletBinding()]
param(
  [parameter(Mandatory = $False, Position = 1)][string]$Config = "default",
  [parameter(Mandatory = $False)][string]$ChocolateyList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\chocolatey.lst"),
  [parameter(Mandatory = $False)][string]$PacmanList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\pacman.lst"),
  [parameter(Mandatory = $False)][string]$NpmList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\npm.lst"),
  [parameter(Mandatory = $False)][string]$GemList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\gem.lst"),
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\path.lst"),
  [parameter(Mandatory = $False)][string]$ProjectList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\project.lst"),
  [parameter(Mandatory = $False)][string]$AtomList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\atom.lst"),
  [parameter(Mandatory = $False)][switch]$Quiet
)

$Location = Get-Location
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Ensure this script is running with admin privileges.
If (-not $IsAdmin) {
  Write-Warning "This script must be executed with administrator privileges."
  Exit
}

# Install chocolatey (package manager for Windows).
If (-Not (Get-Command "choco" -errorAction SilentlyContinue)) {
  Set-ExecutionPolicy Bypass -Scope Process -Force
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  refreshenv
  #powershell -NoLogo -NoExit
}

# Install Windows softwares.
Get-Content -ErrorAction SilentlyContinue -Path $ChocolateyList | Foreach {
  choco install $_ -y
  refreshenv
}
#powershell -NoLogo -NoExit

# Install Atom editor packages.
If (Get-Command "apm" -errorAction SilentlyContinue) {
  Get-Content -ErrorAction SilentlyContinue -Path $AtomList | Foreach {
    apm install $_
  }
}


# Refresh the powershell environment.
refreshenv
#powershell -NoLogo -NoExit

# Add missing paths to the path environment variable.
Get-Content -ErrorAction SilentlyContinue -Path $PathList | Foreach {
  If (Test-Path -IsValid ($_ -ireplace "%USERPROFILE%", $env:userprofile)) {
    if(($_.StartsWith("%USERPROFILE%")) -or ($_.StartsWith($env:userprofile))) {
      Write-Host "$_ added to the Path user environment variable."
      [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariables("User").Path + ";" + $_, [System.EnvironmentVariableTarget]::User)
    } Else {
      Write-Host "$_ added to the Path system environment variable."
      [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariables("Machine").Path + ";" + $_, [System.EnvironmentVariableTarget]::Machine)
    }
  } Else {
    Write-Warning "$_ does not exists."
  }
}


# Update environment variables.
refreshenv

#ridk install
# select 3

# Regenerate GPG key
#msys2 pacman -Syu haveged
#msys2 systemctl start haveged
#msys2 systemctl enable haveged
##rm -fr /etc/pacman.d/gnupg
#$gnupgPath = (cygpath -w /etc/pacman.d/gnupg)
#Remove-Item $gnupgPath -Force -Recurse
#msys2 pacman-key --init
#msys2 pacman-key --populate archlinux


# Install pacman packages.
msys2 pacman -Syuu
Get-Content -ErrorAction SilentlyContinue -Path $PacmanList | Foreach {
  msys2 pacman -S --needed $_
}

# Install global NPMs.
If ((Get-Command "yarn" -ErrorAction SilentlyContinue)) {
  Get-Content -ErrorAction SilentlyContinue -Path $NpmList | Foreach {
    yarn global add $_
  }
} Else {
  Get-Content -ErrorAction SilentlyContinue -Path $NpmList | Foreach {
    npm install -g $_
  }
}

# Install GEMs.
Get-Content -ErrorAction SilentlyContinue -Path $GemList | Foreach {
  gem install $_
}

# Install Ruby Devkit
ridk install

# Install local projects dependencies.
Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
  If (Test-Path $_) {
    Set-Location $_
    If ((Get-Command "yarn" -ErrorAction SilentlyContinue) -And ((Test-Path "yarn.lock") -Or (Test-Path "package.json") -Or (Test-Path "bower.json"))) {
      Write-Host "Starting of NPM/Bower packages installation (with Yarn) in $_." -foreground cyan
      yarn install
    } Else {
      If ((Get-Command "npm" -ErrorAction SilentlyContinue) -And (Test-Path "package.json")) {
        Write-Host "Starting of NPM packages installation in $_." -foreground cyan
        npm install
      }
      If ((Get-Command "bower" -ErrorAction SilentlyContinue) -And (Test-Path "bower.json")) {
        Write-Host "Starting of Bower packages installation in $_." -foreground cyan
        bower install
      }
    }
    If ((Get-Command "bundle" -ErrorAction SilentlyContinue) -And (Test-Path "Gemfile")) {
      Write-Host "Starting of GEM packages installation in $_ (with Bundler)." -foreground cyan
      gem install bundler
      bundle install
      bundle update
    } ElseIf ((Get-Command "gem" -ErrorAction SilentlyContinue) -And (Test-Path "Gemfile")) {
      Write-Host "Starting of GEM packages installation in $_." -foreground cyan
      gem install
    }
  }
}
Set-Location $Location

# Install Linux / Ubuntu.
#lxrun /install

# Update environment variables.
refreshenv
powershell -NoLogo
