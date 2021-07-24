# UninstallBloatware

Using this module, you can easily specify a list of applications to remove, whether they are traditional Win32 applications or modern AppX packages.  Since not every Win32 application can be removed without a little extra work, the module was designed to allow instructions for specific applications to be pulled from a JSON file.

## Why is this needed?

This project was created to remove pre-installed applications by computer manufacturers, typically referred to as "bloatware."  As recently as two or three years ago, the typical best practices within most companies were to freshly reimage new computers with a custom image, thereby removing the applications that weren't needed or wanted, and adding applications and settings that were needed through a "baked-in" image.  However, with the advent of Windows Autopilot, many organizations are direct shipping computers to the end-user, and customizing the operating system's programs and settings programmatically.

The only way to remove some bloatware when direct shipping computers to end-users is to remove the applications manually or deploy custom scripts.  That is the goal of this project: to make an extensible tool that can be used by InTune to uninstall applications.

### When is this not needed?
* Windows in-box apps.  Use InTune to remove them.
* Applications that remove with simple MsiExec commands.  There are many good ways to do this, and winget will hopefully make it even easier when winget is fully released.

## License

This module is being released under an MIT license.  Please consider giving back with any code improvements or complex instruction files that might be valuable to other organizations.

## Usage - ExecutionPolicy

Your ExecutionPolicy will need to be RemoteSigned or Bypass.
```powershell
Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned'
```

In most cases, if your ExecutionPolicy is RemoteSigned you will need to make sure that you unblock these files.  Download the source as a zip file and unblock the entire zip file before extracting it.

```powershell
Unblock-File .\UninstallBloatware-main.zip
```

## Usage - Sample

To get started using this module, check out UninstallBloatwareSample.ps1 and customize it to meet your needs.

## Parameters

### BloatwaresAppx - Uninstall Appx Packages by Name

First of all, InTune can uninstall in-box Windows applications that will allow those applications to be reprovisioned at a later date without reimaging the device if you change your mind.  For that reason, this module is not recommended for uninstalling in-box apps for organizations with InTune.

UninstallBloatware will run a regex match against package names.  UninstallBloatware will uninstall both Appx and AppX provisioned packages; it makes no difference.

To run UninstallBloatware to uninstall AppX packages, you can specify the package name.
```powershell
Import-Module .\Module\UninstallBloatware.psm1
Uninstall-Bloatware -BloatwaresAppx @('HPAudioControl')
```
### BulkRemoveAllAppxPublishers - Uninstall Appx Packages by Publisher
To remove all AppX by a certain publisher, you can specify their publisher ID.  UninstallBloatware will run a regex match for that publisher.

To uninstall all AppX according to the publisher Id:
```powershell
Import-Module .\Module\UninstallBloatware.psm1
Uninstall-Bloatware -BulkRemoveAllAppxPublishers @('v10z8vjag6ke6', 'CN=ED346674-0FA1-4272-85CE-3187C9C86E26')
```


### BloatwaresWin32 - Uninstall Win32 Applications

To run UninstallBloatware to uninstall Win32 applications:
```powershell
Import-Module .\Module\UninstallBloatware.psm1
Uninstall-Bloatware -LogDirectory "C:\Temp" -BloatwaresWin32 @('HP Sure Click', 'HP Sure Connect')
```

If the application uninstalls with typical MSI parameters, it does not need to have a JSON file.  If that works for all of your applications, then you may want to check out 'winget uninstall' once it's released.

If the application uninstall requires specific steps or instructions beyond msiexec, those instructions will need to be stored in a directory specified by the parameter CustomWin32InstructionsDirectory, or in ./Module/Win32Instructions/.

### LogDirectory - Where to Store Logs

Specifies the location to store the transcript and logs.
If you do not specify this parameter, no transcript, tag file, or logs will be taken.

### CustomWin32InstructionsDirectory - Where custom instructions are stored

Specify to add a directory to look in when searching for Win32 application uninstall instructions.  Instructions in this directory will override the built-in application instructions.
```powershell
Uninstall-Bloatware -LogDirectory "C:\Temp" -BloatwaresWin32 @('HP Sure Click', 'HP Sure Connect') -CustomWin32InstructionsDirectory @('C:\Temp')
```

### NoTranscript - Don't take a transcript

By default this script takes a transcript if you specify LogDirectory.  Specify this switch to avoid taking a transcript.

### NoTagFile - Don't create a tag file

By default this script creates the file UninstallBloatware.tag in LogDirectory when there were no errors.  This is useful for InTune to know if this module has run successfully.  Specify this switch to not create the tag file.

### InstructionVariableNames - Custom set of variable names that can be used in the instruction files

Optionally specify the variables that will be searched for.  Do not include the $ in variable names when specifying it in VariableNames.

When reading JSON instruction files, Uninstall-Bloatware will search for each variable using up to three possible ways it could appear in the file:
    $VariableName
    $($VariableName)
    ${VariableName}

Scope modifiers and namespaces other than Env: are not yet supported.

Other than those in the Env: namespace, variable names that require ${} are not yet supported.

The default value is:
```powershell
@(
    'env:ProgramData'
    'env:ProgramFiles'
    'env:SystemDrive'
    'env:ProgramFiles(x86)'
    'env:CommonProgramW6432'
    'env:CommonProgramFiles(x86)'
    'env:DriverData'
    'env:CommonProgramFiles'
    'env:TEMP'
    'env:TMP'
    'env:ProgramW6432'
    'env:windir'
    'PSScriptRoot'
)
```

PSScriptRoot will be the directory of the JSON instruction file.

When reading variables from within JSON instruction files, any variable whose value contains a semicolon will throw an error.

Does accepts $null or an empty string, which will effectively disable the ability to store variables in the instructions files.

## Customizing - Instruction Files

Instruction files help specify custom parameters or steps that need to be taken to remove the more pesky Win32 applications.  Name the file the same as the application but with the .json extension.  Store it in either ./Module/Win32Instructions/ or a directory specified in CustomWin32InstructionsDirectory.

Some parameters can be specified for any Win32 application, while some parameters are only available to some types of uninstallers (Passthrough, Installshield, or Custom).

This module supports using environment variables, or really any variable, in your instructions files.  Format these variable names are either ${env:variablename}, $($env:variablename), or $env:variablename.  Note that ${env:ProgramFiles(x86)}, and any other variable name that would normally require braces, can only be specified using the braces notation.  Use $PSScriptRoot in the instructions to refer to the location of the JSON instructions file itself.

To specify a custom list of variables allowed in the instructions files, use the parameter InstructionVariableNames on Uninstall-Bloatware.
```powershell
Uninstall-Bloatware -LogDirectory "C:\Temp" -BloatwaresWin32 @('HP Sure Click', 'HP Sure Connect') -InstructionVariableNames @('env:ProgramData', 'myVariableName')
```

### Common Parameters

| Parameter | Type | Description
| --- | --- | --- |
| Name | string | The name of the application. |
| DeleteRegistryKey | string array | Registry keys to delete before uninstalling the application. |
| DeleteUninstallKeyAfterRemove | boolean | Specify to delete the uninstall registry entries for this application after a successful uninstall.<br>Some applications don't always do this. |
| SuccessExitCodes | integer array | Specify if the application returns non-standard exit codes even when the uninstall is a success.  The default value is @(0, 1707, 3010, 1641) |
| RequiresDevelopment | boolean | Specify if the application's uninstall is not fully tested.  If no instructions files are found, the application will have this set by default |


### MSI Parameters

MSI is used if the application can be silently uninstalled with the ProductGuid stored in the registry and MsiExec.  MSI is the default way Win32 applications are uninstalled if no parameter is used and works for most well-formed applications.  MSI is the preferred method, and you should try it first.

Parameters:

| Parameter | Type | Description
| --- | --- | --- |
| FalseDoubleEntry | boolean | Some applications have two registry entries.  Specifying this avoids warnings if one of them doesn't work well |
| CustomSuffix | string | Arguments to be added to the end of the MsiExec uninstall command. |

### Passthrough

Use this method if the UninstallString value stored in the application's registry key doesn't contain the ProductGuid but contains the path of the EXE and arguments to uninstall the application.

| Parameter | Type | Description
| --- | --- | --- |
| Passthrough | boolean | Specify to ensure that the module knows unambiguously to use the Passthrough methodology. |
| CustomSuffix | string | Arguments to be added to the end of the UninstallString value. |
| MissingPathEqualsSuccess | boolean | If set to true and running the UninstallString returns 1 (file not found), that will be considered as<br>a success |
| MissingPathEqualsPrivateUninstallString | boolean | If set to true and running the UninstallString returns 1 (file not found), use the<br>PrivateUninstallString instead |
| UsePrivateUninstallString | boolean | Always use the PrivateUninstallString to remove the application. |

### InstallShield

InstallShield applications can often be slightly tricky to uninstall silently.  This method requires an ISS answer file.  UninstallBloatware will read an ISS answer template file and use it to uninstall the application silently.  The template file can contain the text $GUID and $Version, which will be replaced at run time with the proper ProductGUID and DisplayVersion, provided the parameters to do this are true.

| Parameter | Type | Description
| --- | --- | --- |
| InstallShield | boolean | Specify to ensure that the module knows unambiguously to use the InstallShield methodology. |
| ISSTemplate | string | Path to the ISS template file.  By using $PSScriptRoot, you can specify the path relative to the JSON instructions file.  |
| ReplaceGUID | boolean | After reading the ISS template file, replace all occurrences of $GUID with the application's ProductGUID. |
| ReplaceVersion | boolean | After reading the ISS template file, replaces all occurrences of $Version with the application's version. |
