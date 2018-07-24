[CmdletBinding()]
param(
  # Use a custom config directory
  [parameter(Mandatory = $False, Position = 1)][string]$Config = "default",
  # File containing paths to your local web projects.
  [parameter(Mandatory = $False)][string]$ProjectList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\project.lst"),
  # Path to pat list verification file.
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\path.lst"),
  # Clear cache and force un clean install.
  [parameter(Mandatory = $False)][bool]$force = $False,
  # Skip tasks requiring user input when running as scheduled task.
  [parameter(Mandatory = $False)][switch]$Quiet
)


$Location = (Get-Location).Path
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# chocolatey
if (Get-Command "choco" -ErrorAction SilentlyContinue) {

  if ($IsAdmin) {

    Write-Host "Starting of Chocolatey updates." -foreground cyan

    # Upgrade chocolatey.
    choco upgrade chocolatey -y

    # Upgrade globally installed packages.
    choco upgrade all -y

  } else {

    #Write-Warning "Skipping Chocolatey updates (require admin privileges)"

    # Update chocolatey only if script is not in quiet mode.
    if ($Quiet) {
      Write-Warning "Skipping chocolatey packages update (require user input)"
    } else {
      Start-Process -FilePath "powershell" -ArgumentList "-Command 'choco upgrade chocolatey -y; choco upgrade all -y'" -Verb RunAs -Wait
    }

  }

  # Refresh the powershell environment.
  refreshenv
  #powershell -NoLogo -NoExit

}


# gem
if ((Get-Command "gem" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting of GEM updates." -foreground cyan

  # If you run into trouble, try to clean cache.
  if ($force) {
    gem cleanup
  }

  # Upgrade gem.
  gem update --system

  # bundle
  if (Get-Command "bundle" -ErrorAction SilentlyContinue) {

    # If you run into trouble, try to clean cache.
    if ($force) {
      bundle clean --force
    }

    # Update local projects.
    Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
      if ($_ -and (Test-Path $_)) {
        Set-Location $_
        if (Test-Path "Gemfile") {
          Write-Host "Starting of GEM packages update in $_." -foreground cyan
          bundle update
          bundle install
          bundle clean
        }
      }
    }
    Set-Location $Location

    # Clean up unused gems.
    bundle clean

  } else {

    # Update local projects.
    Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
      if ($_ -and (Test-Path $_)) {
        Set-Location $_
        if (Test-Path "Gemfile") {
          Write-Host "Starting of GEM packages update in $_." -foreground cyan
          gem update
          gem cleanup
        }
      }
    }
    Set-Location $Location

  }

}


# pacman
if (Get-Command "pacman" -ErrorAction SilentlyContinue) {

  Write-Host "Starting of PACMAN updates." -foreground cyan

  # Update MSYS2.
  pacman -Syuu --noconfirm
  # Upgrade MSYS2.
  pacman -Syuu --noconfirm

  # Update packages
  pacman -Su --noconfirm

}


# npm
if (Get-Command "npm" -ErrorAction SilentlyContinue) {

  Write-Host "Starting of NPM updates." -foreground cyan

  # If you run into trouble, try to clean cache.
  if ($force) {
    npm cache clean --force
  } else {
    npm cache verify
  }

  # Update NPM.
  npm install -g npm

  # Upgrade NPM.
  npm install -g npm@latest

  # Upgrade globally installed packages.
  Write-Host "Starting of global NPM packages update." -foreground cyan
  npm update -g

  # Update local projects packages.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    if ($_ -and (Test-Path $_)) {
      Set-Location $_
      if (Test-Path "package.json") {
        if ((Get-Command "yarn" -ErrorAction SilentlyContinue) -and (Test-Path "yarn.lock")) {
          Write-Host "Starting of NPM/Bower packages update in $_." -foreground cyan
          yarn install --latest
          yarn upgrade --latest
        } else {
          Write-Host "Starting of NPM packages update in $_." -foreground cyan
          npm update
        }
      }
    }
  }
  Set-Location $Location

}


# bower
if ((Get-Command "bower" -ErrorAction SilentlyContinue) -or (Get-Command "yarn" -ErrorAction SilentlyContinue)) {

  # Update local projects dependencies.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    if ($_ -and (Test-Path $_)) {
      Set-Location $_
      if (Test-Path "bower.json") {
        if ((Get-Command "yarn" -ErrorAction SilentlyContinue) -and (Test-Path "yarn.lock")) {
          Write-Host "Starting of BOWER packages update (with Yarn) in $_." -foreground cyan
          yarn install --latest
          yarn upgrade --latest
        } else {
          Write-Host "Starting of BOWER packages update in $_." -foreground cyan
          bower update --force-latest --save --save-dev
        }
      }
    }
  }
  Set-Location $Location

}


# Update the Powershell help
Write-Host "Starting of Powershell help update." -foreground cyan
Update-Help -ErrorAction "SilentlyContinue"


# atom editor
if (Get-Command "apm" -ErrorAction SilentlyContinue) {
    # Update installed packages
    Write-Host "Starting of Atom editor updates." -foreground cyan
    if (-not $Quiet) {
      apm upgrade
    } else {
      Write-Host "Skipping Atom editor updates (require user input)."
    }
}


# Check paths stored in the Path environment variable.

& (Join-Path -Path $Location -ChildPath "check-path-env.ps1")


# If you run into trouble, try to clean cache.
#npm cache clean --force ; bundle clean --force

# Upgrade package managers.
#choco upgrade chocolatey ; npm install -g npm ; gem update --system

# Upgrade globally installed packages.
#choco upgrade all -y ; npm update -g

# Upgrade local packages.
#npm update ; bundle update ; bundle install

# Install app updates without using a Windows Store account (MSA account)
#Write-Host "Starting of Microsoft Store apps update." -foreground cyan
#Start ms-windows-store:Updates

# Refresh the powershell environment.
powershell -NoLogo
