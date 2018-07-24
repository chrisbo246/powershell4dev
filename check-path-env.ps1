[CmdletBinding()]
param(
  # Use a custom config directory
  [parameter(Mandatory = $False, Position = 1)][string]$Config = "default",
  # Path to pat list verification file.
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\path.lst"),
  # Skip tasks requiring user input when running as scheduled task.
  [parameter(Mandatory = $False)][switch]$Quiet
)

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")


if (-Not $Quiet) {
  Write-Host "Starting of 'Path' environment variable verifications." -foreground cyan
}

$RegistredPaths = [Environment]::GetEnvironmentVariables("User").Path + ';' + [Environment]::GetEnvironmentVariables("Machine").Path
$RegistredPaths = $ExecutionContext.InvokeCommand.ExpandString(($RegistredPaths -ireplace '~', $env:userprofile -ireplace '%([a-zA-Z0-9]+)%', '${env:$1}'))
$RegistredPaths = $RegistredPaths -Split ";"

$RegistredPaths | Foreach {
  if ($_ -And -Not (Test-Path -IsValid $_)) {
    Write-Warning "$_ is registered in the path environment variable but does not exists."
  }
}

# Add missing paths to the path environment variable.
Get-Content -ErrorAction SilentlyContinue -Path $PathList | Foreach {
  if ($_) {
    $Path = $ExecutionContext.InvokeCommand.ExpandString(($_ -ireplace '^~', $env:userprofile -ireplace '%([a-zA-Z0-9]+)%', '${env:$1}'))
    if (($RegistredPaths.Contains($Path)) -And (Test-Path -IsValid $Path)) {
      if (-Not $Quiet) {
        Write-Host "$_ found in user or system 'Path' environment variable."
      }
    } Else {
      Write-Warning "$_ missing in both user and system 'Path' environment variable."
      if ($IsAdmin) {
        if ($Path.StartsWith($env:userprofile)) {
          [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariables("User").Path + ";" + $_, [System.EnvironmentVariableTarget]::User)
          if (-Not $Quiet) {
            Write-Host "$_ added to user 'Path' environment variable."
          }
        } else {
          [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariables("Machine").Path + ";" + $_, [System.EnvironmentVariableTarget]::Machine)
          if (-Not $Quiet) {
            Write-Host "$_ added to system 'Path' environment variable."
          }
        }
      }
    }
  }
}
