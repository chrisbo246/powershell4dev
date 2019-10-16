[CmdletBinding()]
param(
  [parameter(Mandatory = $False, Position = 1)][string]$Config = "auto-generated",
  [parameter(Mandatory = $False)][string]$ChocolateyList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\chocolatey.lst"),
  [parameter(Mandatory = $False)][string]$PacmanList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\pacman.lst"),
  [parameter(Mandatory = $False)][string]$NpmList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\npm.lst"),
  [parameter(Mandatory = $False)][string]$YarnList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\yarn.lst"),
  [parameter(Mandatory = $False)][string]$GemList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\gem.lst"),
  [parameter(Mandatory = $False)][string]$PathList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\path.lst"),
  [parameter(Mandatory = $False)][string]$ProjectList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\project.lst"),
  [parameter(Mandatory = $False)][string]$AtomList = (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config\$Config\atom.lst"),
  [parameter(Mandatory = $False)][switch]$Quiet
)

$Location = Get-Location

#& (Join-Path -Path $Location -ChildPath "cleanup.ps1")

If (Get-Command "chocolatey" -ErrorAction SilentlyContinue) {
  Write-Host "Listing installed Chocolatey packages to $ChocolateyList." -foreground cyan
  New-Item -Path $ChocolateyList -ItemType File -Force | Out-Null
  (choco list --local-only | Select -SkipLast 1) -Replace '\s.*$', '' | Out-File -FilePath $ChocolateyList -Encoding UTF8 -Force
}

If (Get-Command "pacman" -ErrorAction SilentlyContinue) {
  Write-Host "Listing installed Pacman packages to $PacmanList." -foreground cyan
  New-Item -Path $PacmanList -ItemType File -Force | Out-Null
  #(pacman -Qe) -Replace '\s.*$', '' | Out-File -FilePath $PacmanList -Encoding UTF8 -Force
  pacman -Qe | ConvertFrom-Csv -Delimiter ' ' -Header 'Name', 'Version' | Select -Property 'Name' | Out-File -FilePath $PacmanList -Encoding UTF8 -Force
}

If (Get-Command "gem" -ErrorAction SilentlyContinue) {
  Write-Host "Listing installed GEM packages to $GemList." -foreground cyan
  New-Item -Path $GemList -ItemType File -Force | Out-Null
  gem query --local --no-versions --quiet | Out-File -FilePath $GemList -Encoding UTF8 -Force
}

If (Get-Command "yarn" -ErrorAction SilentlyContinue) {
  Write-Host "Listing installed Yarn (NPM) packages to $YarnList." -foreground cyan
  New-Item -Path $YarnList -ItemType File -Force | Out-Null
  (yarn global list --depth=0 | Select-String -Pattern "^\s+- ") -Replace '^\s+- ', '' | Out-File -FilePath $YarnList -Encoding UTF8 -Force
}

If (Get-Command "npm" -ErrorAction SilentlyContinue) {
  Write-Host "Listing installed NPM packages to $NpmList." -foreground cyan
  New-Item -Path $NpmList -ItemType File -Force | Out-Null
  (npm list -g --depth=0 | Select -Skip 1 | Select -SkipLast 1) -Replace '^.*\s(.*)@.*$', '$1' | Out-File -FilePath $NpmList -Encoding UTF8 -Force
}

If (Get-Command "apm" -ErrorAction SilentlyContinue) {
  Write-Host "Listing installed APM (atom) packages to $AtomList." -foreground cyan
  New-Item -Path $AtomList -ItemType File -Force | Out-Null
  apm list --installed --bare | Out-File -FilePath $AtomList -Encoding UTF8 -Force
}
