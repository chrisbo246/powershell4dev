# powershell4dev

Automatically install a webdev environment on Windows 10 and update your projects dependencies.


## Install a webdev environement on Windows

- Install Chocolatey (package manager for Windows).
- Install Windows softwares listed in [config\\chocolatey.lst](config/chocolatey.lst).
- Install Ruby GEM packages listed in [config\\gem.lst](config/gem.lst).
- Install Node NPM packages listed in [config\\npm.lst](config/npm.lst).
- Install Pacman packages listed in [config\\pacman.lst](config/pacman.lst).
- Add paths listed in [config\\path.lst](config/path.lst) to the path environement variable.
- Install dependencies (NPM, Bower, GEM, etc...) for each project listed in [config\\path.lst](config/project.lst).

```powershell
install.ps1
```


## Update softwares and projets dependencies

- Update Windows softwares with Chocolatey.
- Update global NPM packages.
- Update Packman packages.
- Update Ruby GEM packages.
- Update dependencies (NPM, Bower, GEM, etc...) for each project listed in [config\\path.lst](config/project.lst)
- Check paths listed in the path environement variable.

```powershell
update.ps1
```
