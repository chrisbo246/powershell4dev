[CmdletBinding()]
param(
  [parameter(Mandatory = $False, Position = 1)][string]$Config = "default",
  [parameter(Mandatory = $False)][string]$ChocolateyList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\chocolatey.lst"),
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\path.lst"),
  [parameter(Mandatory = $False)][switch]$Quiet
)

$Location = Get-Location
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
Get-Content -ErrorAction SilentlyContinue -Path $PathList | Foreach {
  if (Test-Path -IsValid ($_ -ireplace "%USERPROFILE%", $env:userprofile)) {
    if(($_.StartsWith("%USERPROFILE%")) -or ($_.StartsWith($env:userprofile))) {
      Write-Host "$_ added to the Path user environment variable."
      [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$_", [System.EnvironmentVariableTarget]::User)
    } else {
      Write-Host "$_ added to the Path system environment variable."
      [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$_", [System.EnvironmentVariableTarget]::Machine)
    }
  } else {
    Write-Warning "$_ does not exists."
  }
}


Set-Location $Location

# Update environment variables.
refreshenv
powershell -NoLogo
