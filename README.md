# phlingerize - Make ARK a game and not a chore

Modify ARK Survival game configurations using [Phlinger](https://www.youtube.com/@Phlinger)'s setting for an improved gaming experience.

He explains his settings in this YouTube video: [Best Single Player Settings in Ark Survival Ascended in 2025](https://www.youtube.com/watch?v=vD8fxCATqhg).

`phlingerize.ps1` is a Windows Powershell script.

Basic usage:
```shell
phlingerize.ps1 <patchFileName> <targetDirectory>
```

How it works:

* It uses the name of the patch file (`patchFileName`) to figure out what should be patched by removing everying after the first non alpla-numerig character.
  * e.g. `GameUserSettings-ARK.ini` becomes `GameUserSettings.ini`
* The configuration file to be changed is then searched for in the given directory (`targetDirectory`)
* You will then be asked to confirm applying the changes.
* A copy of the file, if it doesn't already exist, is then created.
  * e.g. `GameUserSettings.ini-prephlingerize`
* Values defined in the patch file are then applied to the target file and saved.


## ARK Survival Ascended

### Update GameUserSettings.ini

```shell
phlingerize.ps1 'GameUserSettings-ARK.ini' 'C:\Program Files (x86)\Steam\steamapps\common\ARK Survival Ascended\ShooterGame\Saved\Config\Windows'
```

### Update Game.ini

```shell
phlingerize.ps1 'Game-ASA.ini' 'C:\Program Files (x86)\Steam\steamapps\common\ARK Survival Ascended\ShooterGame\Saved\Config\Windows'
```

## ARK Survival Evolved

```shell
phlingerize.ps1 'GameUserSettings-ARK.ini' 'C:\Program Files (x86)\Steam\steamapps\common\ARK\ShooterGame\Saved\Config\WindowsNoEditor'
```

# Patch files

* GameUserSettings-ARK.ini
  * For ASA and ASE
* Game-ASA.ini
  * For ASA only

The script is licenced under the GPLv3.
