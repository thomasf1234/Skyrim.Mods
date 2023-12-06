# Skyrim.Mods

To install first create a zip of the mod directory i.e `TFBase.zip` (send to compressed zip).

Secondly run the following powershell script and enter `i` when prompted:
```
> .\ManualInstaller.ps1 TFBase
Please choose install[i] or un-install[u]: i
```

This will copy the files into the Skyrim directory, and backup any files that will be overwritten. 

To uninstall simply call the script again and enter `u` for uninstall. This will only work when the mod has been installed via the script
```
> .\ManualInstaller.ps1 TFBase
Please choose install[i] or un-install[u]: u
```