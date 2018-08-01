[CmdletBinding()]
param(
  [parameter(Mandatory = $False, Position = 1)][string]$Config = "default",
  [parameter(Mandatory = $False)][string]$ChocolateyList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\chocolatey.lst"),
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\path.lst"),
  [parameter(Mandatory = $False)][switch]$Quiet
)

$Location = (Get-Location).Path
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Ensure this script is running with admin privileges.
if (-not $IsAdmin) {
  Write-Warning "This script must be executed with administrator privileges."
  Exit
}

# chocolatey
if (Get-Command "choco" -ErrorAction SilentlyContinue) {

  Write-Host "Starting of Chocolatey updates." -foreground cyan

  # Upgrade chocolatey.
  choco upgrade chocolatey -y

  # Upgrade globally installed packages.
  choco upgrade all -y
  
  # Refresh the powershell environment.
  refreshenv
  #powershell -NoLogo -NoExit

}


# Add missing paths to the path environment variable.

& (Join-Path -Path $Location -ChildPath "check-path-env.ps1")



Set-Location $Location

# Update environment variables.
refreshenv
powershell -NoLogo
