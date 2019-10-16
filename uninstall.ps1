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

# chocolatey
If (Get-Command "choco" -ErrorAction SilentlyContinue) {

  If ($IsAdmin) {
    choco uninstall all -y --remove-dependencies
  } Else {

  }

}


# gem
If ((Get-Command "gem" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting of GEM uninstall." -foreground cyan

  # Clean old packages.
  Write-Host "Removing gems from the GEM's home directory"
  gem uninstall --all --quiet

  # bundle
  If (Get-Command "bundle" -ErrorAction SilentlyContinue) {

    # Update local projects gems.
    Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
      If ($_ -and (Test-Path $_)) {
        Set-Location $_
        If (Test-Path "Gemfile") {
          #Write-Host "Removing gems in $_."
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
          Write-Host "Removing GEMs in $_."
          gem uninstall --quiet --config-file "Gemfile"
        }
      }
    }
    Set-Location $Location

  }

}


# pacman
If (Get-Command "pacman" -ErrorAction SilentlyContinue) {

  Write-Host "Starting of PACMAN uninstall." -foreground cyan

  Write-Host "Removing every PACMAN packages"
  pacman -Rsc $(pacman -Qeq)

}


# yarn
If (Get-Command "yarn" -ErrorAction SilentlyContinue) {

  Write-Host "Starting of NPM/Bower uninstall." -foreground cyan

  Write-Host "Removing global NPM/Bower dependencies."
  yarn global remove --all

  # Remove local projects packages.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    If ($_ -and (Test-Path $_)) {
      Set-Location $_
      If ((Test-Path "yarn.lock") -Or (Test-Path "package.json") -Or (Test-Path "bower.json")) {
        Write-Host "Removing NPM/Bower dependencies in $_."
        yarn remove --all
      }
    }
  }
  Set-Location $Location

}


# npm
If ((Get-Command "npm" -ErrorAction SilentlyContinue) -And -Not (Get-Command "yarn" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting of NPM uninstall." -foreground cyan

  Write-Host "Uninstalling global NPM packages."
  npm uninstall --all --global

  # Remove local projects packages.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    If ($_ -and (Test-Path $_)) {
      Set-Location $_
      If (Test-Path "package.json") {
        Write-Host "Uninstalling NPM packages in $_." -foreground cyan
        npm uninstall --all --no-save
      }
    }
  }
  Set-Location $Location

}


# bower
If ((Get-Command "bower" -ErrorAction SilentlyContinue) -And -Not (Get-Command "yarn" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting of BOWER packages uninstall." -foreground cyan

  # Remove local projects dependencies.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    If ($_ -and (Test-Path $_)) {
      Set-Location $_
      If (Test-Path "bower.json") {
        Write-Host "Removing Bower dependencies in $_."
        bower uninstall
      }
    }
  }
  Set-Location $Location

}


# Refresh the powershell environment.
powershell -NoLogo
