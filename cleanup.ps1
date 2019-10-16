[CmdletBinding()]
param(
  # Use a custom config directory
  [parameter(Mandatory = $False, Position = 1)][string]$Config = "default",
  # File containing paths to your local web projects.
  [parameter(Mandatory = $False)][string]$ProjectList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\project.lst"),
  # Path to pat list verification file.
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\path.lst"),
  # Clear cache and reinstall everything.
  [parameter(Mandatory = $False)][bool]$Force = $False,
  # Skip tasks requiring user input when running as scheduled task.
  [parameter(Mandatory = $False)][switch]$Quiet
)


$Location = (Get-Location).Path
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# chocolatey
If (Get-Command "choco" -ErrorAction SilentlyContinue) {

  If ($IsAdmin) {
    If (Get-Command "choco-cleaner.ps1" -ErrorAction SilentlyContinue) {
      #Set-ExecutionPolicy -ExecutionPolicy Unrestricted
      #\ProgramData\chocolatey\bin\Choco-Cleaner.ps1
      .\choco-cleaner.ps1
    }
  } Else {

  }

}


# gem
If ((Get-Command "gem" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting of GEM cleanup." -foreground cyan


  Write-Host "Check a gems repository for added or missing files"
  gem check
  # Clean old packages.
  Write-Host "Clean up old versions of installed gems in GEM's home directory"
  gem cleanup --no-user-install --silent
  Write-Host "Clean up old versions of installed gems in user's home directory"
  gem cleanup --user-install --silent

  # bundle
  If (Get-Command "bundle" -ErrorAction SilentlyContinue) {

    # Update local projects gems.
    Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
      If ($_ -and (Test-Path $_)) {
        Set-Location $_
        If (Test-Path "Gemfile") {
          bundle clean --force
          bundle update --force
          #bundle install
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
          Write-Host "Clean up old versions of installed gems in $_."
          gem cleanup --silent --config-file "Gemfile"
        }
      }
    }
    Set-Location $Location

  }

}


# pacman
If (Get-Command "pacman" -ErrorAction SilentlyContinue) {

  Write-Host "Starting of PACMAN cleanup." -foreground cyan

  Write-Host "Uninstall unneeded PACMAN packages"
  pacman -Rns --noconfirm $(pacman -Qdtq)
  Write-Host "Remove all files from the PACMAN cache"
  pacman -Scc --noconfirm
  pacman -Scc --noconfirm

}


# yarn
If (Get-Command "yarn" -ErrorAction SilentlyContinue) {

  Write-Host "Starting of NPM/Bower cleanup." -foreground cyan

  Write-Host "Cleaning yarn cache."
  yarn cache clean

  # Clean local projects.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    If ($_ -and (Test-Path $_)) {
      Set-Location $_
      If ((Test-Path "yarn.lock") -Or (Test-Path "package.json") -Or (Test-Path "bower.json")) {
        If (-Not (Test-Path "yarn.lock")) {
          Write-Host "Create missing yarn.lock file."
          yarn install
        }
        If (-Not (Test-Path ".yarnclean")) {
          Write-Host "Create missing .yarnclean file."
          yarn autoclean --init
        }
        Write-Host "Verify that package.json match yarn.lock file in $_."
        yarn check
        Write-Host "Removes unnecessary files from NPM/Bower dependencies in $_."
        yarn autoclean --force
        Write-Host "Perform a vulnerability audit against the installed packages in $_."
        yarn audit
      }
    }
  }
  Set-Location $Location

}


# npm
If ((Get-Command "npm" -ErrorAction SilentlyContinue) -And -Not (Get-Command "yarn" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting of NPM cleanup." -foreground cyan

  If ($Force) {
    Write-Host "Delete all data out of the cache folder."
    npm cache clean --force
  } Else {
    Write-Host "Verify the contents of the cache folder."
    npm cache verify
  }


  # Clean local projects packages.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    If ($_ -and (Test-Path $_)) {
      Set-Location $_
      If (Test-Path "package.json") {
        Write-Host "Delete all data out of the cache folder in $_." -foreground cyan
        npm cache clean --force
        npm audit fix
      }
    }
  }
  Set-Location $Location

}


# bower
If ((Get-Command "bower" -ErrorAction SilentlyContinue) -And -Not (Get-Command "yarn" -ErrorAction SilentlyContinue)) {

  Write-Host "Starting of BOWER packages cleanup." -foreground cyan

  # Clean local projects dependencies.
  Get-Content -ErrorAction SilentlyContinue -Path $ProjectList | Foreach {
    If ($_ -and (Test-Path $_)) {
      Set-Location $_
      If (Test-Path "bower.json") {
        Write-Host "Cleaning of BOWER cache in $_."
        bower cache clean
      }
    }
  }
  Set-Location $Location

}


# atom editor
If (Get-Command "apm" -ErrorAction SilentlyContinue) {
  apm clean
}


# Check paths stored in the Path environment variable.
& (Join-Path -Path $Location -ChildPath "check-path-env.ps1")

# Refresh the powershell environment.
powershell -NoLogo
