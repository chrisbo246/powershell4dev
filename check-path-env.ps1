[CmdletBinding()]
param(
  # Use a custom config directory
  [parameter(Mandatory = $False, Position = 1)][string]$Config = "default",
  # Path to pat list verification file.
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\path.lst"),
  # Add missing paths and remove duplicate values
  [parameter(Mandatory = $False)][switch]$Fix,
  # Skip tasks requiring user input when running as scheduled task.
  [parameter(Mandatory = $False)][switch]$Quiet
)

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")



function Get-RealPath {

  [CmdletBinding()]
  param(
    [parameter(Mandatory = $True, Position = 1)][string]$Path
  )

  If ($Path) {
    # Replace environment variable notations
    $Path = $ExecutionContext.InvokeCommand.ExpandString(($Path -ireplace '%([a-zA-Z0-9]+)%', '${env:$1}'))
  }
  If ($Path) {
    # Resolve ~ and *
    $Path = ((Resolve-Path -Path $Path -ErrorAction SilentlyContinue).Path)
  }
  If ($Path) {
    # Add trailing backslash for unification
    Join-Path -Path $Path -ChildPath '\'
  }

}




If (-Not $Quiet) {
  Write-Host "Starting of 'Path' environment variable verifications." -foreground cyan
}



$RealRegisteredPaths = @()
$Paths = (([Environment]::GetEnvironmentVariables("User").Path + ';' + [Environment]::GetEnvironmentVariables("Machine").Path) -Split ';')
$Paths | % {
  If ($_) {
    $Path = (Get-RealPath -Path $_)
    If ($Path) {

      If ($RealRegisteredPaths -Contains $Path) {

        # Duplicate path
        If ($Fix -And $IsAdmin) {
          # Remove entry
          If (-Not $Quiet) {
            Write-Host "$_ entry removed from the 'Path' environment variable."
          }
        } ElseIf (-Not $Quiet) {
          Write-Warning "$_ is registered several times in the path environment variable."
        }

      } Else {

        # Valid path
        If (-Not $Quiet) {
          Write-Verbose "$_ is a valid path."
        }
        $RealRegisteredPaths += $Path

      }

    } Else {

      # Invalid path
      If ($Fix -And $IsAdmin) {
        # Remove entry
        If (-Not $Quiet) {
          Write-Host "$_ entry removed from the 'Path' environment variable."
        }
      } ElseIf (-Not $Quiet) {
        Write-Warning "$_ is registered in the path environment variable but does not exists."
      }

    }
  }
}



$RealListedPaths = @()
$Paths = (Get-Content -ErrorAction SilentlyContinue -Path $PathList)
$Paths | % {
  If ($_) {
    $Path = (Get-RealPath -Path $_)
    If ($Path) {
      If ($RealListedPaths -Contains $Path) {

        # Duplicate path
        If ($Fix -And $IsAdmin) {
          # Remove entry
          #If (-Not $Quiet) {
          #	Write-Host "$_ entry removed from $PathList."
          #}
        } ElseIf (-Not $Quiet) {
          Write-Verbose "$_ is listed several times in $PathList."
        }

      } Else {

        # Valid path
        If (-Not $Quiet) {
          Write-Verbose "$_ is a valid path."
        }

        If ($RealRegisteredPaths -Contains $Path) {

          If (-Not $Quiet) {
            Write-Verbose "$_ found in user or system 'Path' environment variable."
          }

        } Else {

          Write-Warning "$_ missing in both user and system 'Path' environment variable."

          # Add missing path
          If ($Fix -And $IsAdmin) {
            If ($_.StartsWith($env:userprofile)) {
              [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariables("User").Path + ";" + $_, [System.EnvironmentVariableTarget]::User)
              If (-Not $Quiet) {
                Write-Host "$_ added to user 'Path' environment variable."
              }
            } Else {
              [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariables("Machine").Path + ";" + $_, [System.EnvironmentVariableTarget]::Machine)
              If (-Not $Quiet) {
                Write-Host "$_ added to system 'Path' environment variable."
              }
            }
          }

        }

      }
    } Else {

      # Invalid path
      If ($Fix -And $IsAdmin) {
        # Remove entry
        #If (-Not $Quiet) {
        #	Write-Host "$_ entry removed from $PathList."
        #}
      } ElseIf (-Not $Quiet) {
        Write-Verbose "$_ is listed in $PathList but does not exists."
      }

    }
  }
}
