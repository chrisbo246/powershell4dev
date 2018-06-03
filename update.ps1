[CmdletBinding()]
param(
  # File containing paths to your local web projects.
  [parameter(Mandatory = $False, Position=1)][string]$ProjectList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\project.lst"),
  # Clear cache and force un clean install.
  [parameter(Mandatory = $False, Position=2)][bool]$force = $False,
  # Skip tasks requiring user input when running as scheduled task.
  [parameter(Mandatory = $False, Position=3)][bool]$quiet = $False
)


$Location = Get-Location


# chocolatey
if (Get-Command "choco" -ErrorAction SilentlyContinue) {

  Write-Host "Starting chocolatey packages update." -foreground cyan

  if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    # Upgrade chocolatey.
    choco upgrade chocolatey -y

    # Upgrade globally installed packages.
    choco upgrade all -y

  } else {

    # Update chocolatey only if script is not in quiet mode
    if ($quiet) {
      Write-Warning "Skipping chocolatey packages update (require password)"
    } else {
      Start-Process -FilePath "powershell" -ArgumentList "choco upgrade chocolatey -y; choco upgrade all -y" -Verb RunAs -Wait
    }

  }

}


# gem
if ((Get-Command "gem" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting GEM update." -foreground cyan

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
      if (Test-Path $_) {
        Set-Location $_
        if (Test-Path "Gemfile") {
          Write-Host "Starting GEM packages update in $_." -foreground cyan
          bundle update
          bundle install
          bundle clean
        }
      }
    }
    Set-Location $Location

    # Clean up unused gems
    bundle clean

  } else {

    # Update local projects.
    Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
      if (Test-Path $_) {
        Set-Location $_
        if (Test-Path "Gemfile") {
          Write-Host "Starting GEM packages update in $_." -foreground cyan
          gem update
          gem cleanup
        }
      }
    }
    Set-Location $Location

  }

}


# pacman
if (Get-Command "msys2" -ErrorAction SilentlyContinue) {

  Write-Host "Starting PACMAN packages update." -foreground cyan

  # Upgrade MSYS2
  #C:\tools\msys64\msys2.exe update-core
  Start-Process -FilePath "msys2" -ArgumentList "pacman -Syuu --noconfirm" -Wait
  Start-Process -FilePath "msys2" -ArgumentList "pacman -Syuu --noconfirm" -Wait

  # Update packages
  Start-Process -FilePath "msys2" -ArgumentList "pacman -Su --noconfirm" -Wait

}


# npm
if (Get-Command "npm" -ErrorAction SilentlyContinue) {

  Write-Host "Starting NPM update." -foreground cyan

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
  Write-Host "Starting global NPM packages update." -foreground cyan
  npm update -g

  # Update local projects packages.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    if (Test-Path $_) {
      Set-Location $_
      if (Test-Path "package.json") {
        if ((Get-Command "yarn" -ErrorAction SilentlyContinue) -and (Test-Path "yarn.lock")) {
          Write-Host "Starting NPM/Bower packages update in $_." -foreground cyan
          yarn install --latest
          yarn upgrade --latest
        } else {
          Write-Host "Starting NPM packages update in $_." -foreground cyan
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
    if (Test-Path $_) {
      Set-Location $_
      if (Test-Path "bower.json") {
        if ((Get-Command "yarn" -ErrorAction SilentlyContinue) -and (Test-Path "yarn.lock")) {
          Write-Host "Starting BOWER packages update (with Yarn) in $_." -foreground cyan
          yarn install --latest
          yarn upgrade --latest
        } else {
          Write-Host "Starting BOWER packages update in $_." -foreground cyan
          bower update --force-latest --save --save-dev
        }
      }
    }
  }
  Set-Location $Location

}


# Check paths stored in the path environment variable
(Get-Childitem Env:Path).value -split ";" | Foreach {
  if (-not (Test-Path $_)) {
    Write-Warning "$_ is registered in the path environment variable but does not exists."
  }
}


# If you run into trouble, try to clean cache.
#npm cache clean --force ; bundle clean --force

# Upgrade package managers.
#choco upgrade chocolatey ; npm install -g npm ; gem update --system

# Upgrade globally installed packages.
#choco upgrade all -y ; npm update -g

# Upgrade local packages.
#npm update ; bundle update ; bundle install

# Update environment variables
refreshenv

# Install app updates without using a Windows Store account (MSA account)
#Write-Host "Starting Microsoft Store apps update." -foreground cyan
#Start ms-windows-store:Updates
