[CmdletBinding()]
param(
  # Use a custom config directory
  [parameter(Mandatory = $False, Position = 1)][string]$Config = "default",
  # File containing paths to your local web projects.
  [parameter(Mandatory = $False)][string]$ProjectList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\project.lst"),
  # Path to pat list verification file.
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\path.lst"),
  # Skip tasks requiring user input when running as scheduled task.
  [parameter(Mandatory = $False)][switch]$Quiet
)

$Location = (Get-Location).Path
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

If ($Quiet) {
  $VerbosePreference = "SilentlyContinue"
} Else {
  $VerbosePreference = "Continue"
}
#Write-Verbose ""

# chocolatey
If (Get-Command "choco" -ErrorAction SilentlyContinue) {

  If ($IsAdmin) {

    Write-Host "Starting of Chocolatey updates." -foreground cyan

    # Upgrade chocolatey.
    choco upgrade chocolatey -y

    # Upgrade globally installed packages.
    choco upgrade all -y

  } Else {

    # Update chocolatey only if script is not in quiet mode.
    If ($Quiet) {
      Write-Verbose "Skipping chocolatey packages update (require user input)"
    } Else {
      $Answer = Read-Host 'Chocolatey packages update requires elevated privileges. Do you want to process? (y/N)'
      Switch -Regex ($Answer) {
        Y {
          #Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "choco upgrade chocolatey -y; choco upgrade all -y" -Verb RunAs -Wait
          Start-Process -FilePath "powershell" -ArgumentList "choco upgrade chocolatey -y; choco upgrade all -y" -Verb RunAs -Wait
        }
        default {
          Write-Verbose "Skipping chocolatey packages update"
        }
      }
    }

  }

  # Refresh the powershell environment.
  refreshenv
  #powershell -NoLogo -NoExit

}


# gem
If ((Get-Command "gem" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting of GEM updates." -foreground cyan

  # Update rubygem.
  gem update --system

  # Upgrade installed gems.
  #gem update

  # bundle
  If (Get-Command "bundle" -ErrorAction SilentlyContinue) {

    # Update local projects gems.
    Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
      If ($_ -and (Test-Path $_)) {
        Set-Location $_
        If (Test-Path "Gemfile") {
          Write-Host "Starting of GEM packages update in $_." -foreground cyan
          bundle update
          bundle install
        }
      }
    }
    Set-Location $Location

  } Else {

    # Update local projects.
    Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
      If ($_ -and (Test-Path $_)) {
        Set-Location $_
        If (Test-Path "Gemfile") {
          Write-Host "Starting of GEM packages update in $_." -foreground cyan
          gem update
        }
      }
    }
    Set-Location $Location

  }

}


# pacman
If (Get-Command "pacman" -ErrorAction SilentlyContinue) {

  Write-Host "Starting of PACMAN updates." -foreground cyan

  # Update MSYS2.
  pacman -Syuu --noconfirm
  # Upgrade MSYS2.
  pacman -Syuu --noconfirm

  # Update packages
  pacman -Su --noconfirm

}

# yarn (NPM/Bower)
If (Get-Command "yarn" -ErrorAction SilentlyContinue) {

  Write-Host "Starting of NPM/Bower updates." -foreground cyan

  # Upgrade globally installed packages.
  Write-Host "Starting of global NPM/Bower packages update." -foreground cyan
  yarn global upgrade --latest

  # Update local projects packages.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    If ($_ -and (Test-Path $_)) {
      Set-Location $_
      If ((Test-Path "yarn.lock") -Or (Test-Path "package.json") -Or (Test-Path "bower.json")) {
        If (-Not (Test-Path "yarn.lock")) {
          Write-Host "Initializing Yarn in $_." -foreground cyan
          yarn install --check-files
        }
        Write-Host "Starting of NPM/Bower packages update in $_." -foreground cyan
        yarn upgrade --latest
      }
      # ElseIf ((Test-Path "package.json") -Or (Test-Path "bower.json")) {
      #  Write-Host "Initializing Yarn in $_." -foreground cyan
      #  yarn install
      #}
    }
  }
  Set-Location $Location

}


# npm
If ((Get-Command "npm" -ErrorAction SilentlyContinue) -And -Not (Get-Command "yarn" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting of NPM updates." -foreground cyan

  # Update NPM.
  npm install -g npm

  # Upgrade NPM.
  npm install -g npm@latest

  # Upgrade globally installed packages.
  Write-Host "Starting of global NPM packages update." -foreground cyan
  npm update -g

  # Update local projects packages.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    If ($_ -and (Test-Path $_)) {
      Set-Location $_
      If (Test-Path "package.json") {
        Write-Host "Starting of NPM packages update in $_." -foreground cyan
        npm update
      }
    }
  }
  Set-Location $Location

}


# bower
If ((Get-Command "bower" -ErrorAction SilentlyContinue) -And -Not (Get-Command "yarn" -ErrorAction SilentlyContinue)) {

  # Update local projects dependencies.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    If ($_ -and (Test-Path $_)) {
      Set-Location $_
      If (Test-Path "bower.json") {
        Write-Host "Starting of BOWER packages update in $_." -foreground cyan
        bower update --force-latest --save --save-dev
      }
    }
  }
  Set-Location $Location

}


# Update the Powershell help
Write-Host "Starting of Powershell help update." -foreground cyan
Update-Help -ErrorAction "SilentlyContinue"


# atom editor
If (Get-Command "apm" -ErrorAction SilentlyContinue) {
    # Update installed packages
    Write-Host "Starting of Atom editor updates." -foreground cyan
    If (-Not $Quiet) {
      apm upgrade --confirm false
    } Else {
      Write-Verbose "Skipping Atom editor updates (require user input)."
    }
}


# Check paths stored in the Path environment variable.
#& (Join-Path -Path $Location -ChildPath "check-path-env.ps1")


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
