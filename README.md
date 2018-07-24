# powershell4dev

## Install a webdev environment on Windows

- Install Chocolatey (package manager for Windows).
- Install Windows desktop softwares listed in [config\\chocolatey.lst](config/chocolatey.lst).
- Install Ruby GEM packages listed in [config\\gem.lst](config/gem.lst).
- Install Node NPM packages listed in [config\\npm.lst](config/npm.lst).
- Install MSYS2 Pacman packages listed in [config\\pacman.lst](config/pacman.lst).
- Add paths listed in [config\\path.lst](config/path.lst) to the path environement variable.
- Install dependencies (NPM, Bower, GEM, etc...) for each project listed in [config\\project.lst](config/project.lst).

```powershell
install.ps1 [-Config "custom"]
```


## Update Windows softwares and local projets dependencies

- Update Windows softwares with Chocolatey.
- Update global NPM packages.
- Update Packman packages.
- Update Ruby GEM packages.
- Update dependencies (NPM, Bower, GEM, etc...) for each project listed in [config\\project.lst](config/project.lst)
- Check paths listed in the path environement variable.

```powershell
update.ps1 [-Config "custom"]
```


## Path environment variable verification

- Check the validity of each path registered in both user and system 'Path'.
- Add paths listed in [config\\path.lst](config/path.lst) to user or system 'Path' if not already present.


```powershell
check-path-env.ps1 [-Config "custom"][-PathList "\custom\path\path.lst"]
```
