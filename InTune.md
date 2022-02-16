# Uninstall Bloatware

## Description

Uninstalls "bloatware" that comes preinstalled on computers.

## Instructions

To use this module in InTune:

1. Install .NET Core SDK and IntuneAppBuilder using the instructions here https://github.com/simeoncloud/IntuneAppBuilder.
2. Customize UninstallBloatwareSample.ps1 using the instructions here https://github.com/TSA-SAUSS/UninstallBloatware/blob/main/README.md.
3. Run New-InTuneWinPackage.ps1 to create the Content.portal.intunewin file.
4. Create the Win32 app in InTune using the settings below.  If you've changed the filename of UninstallBloatwareSample.ps1 or the log folder, adjust your Win32 app settings accordingly.

## Custom Settings

Runs the script Uninstall-Bloatware.ps1

The installation script stores logs in C:\ProgramData\UninstallBloatware

The file C:\ProgramData\UninstallBloatware\UninstallBloatware.tag will be added to the computer after a successfull run.

## App Information

| Property        | Value                                                                                                                       |
| --------------- | --------------------------------------------------------------------------------------------------------------------------- |
| INTUNEWIN file  | ./Output/Content.portal.intunewin                |
| Name            | Uninstall Bloatware                                                                                                         |
| Description     | Uninstall Bloatware                                                                                                         |
| Publisher       | The Salvation Army                                                                                                          |
| App Version     | 1.1.7                                                                                                                       |
| Category        | Computer Management                                                                                                         |
| Information URL | https://github.com/TSA-SAUSS/InTuneApps/blob/master/Win32/UninstallBloatware/README.md                                      |

## Program

| Property                | Value                                                                                   |
| ----------------------- | --------------------------------------------------------------------------------------- |
| Install Command         | %SYSTEMROOT%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\UninstallBloatwareSample.ps1  |
| Uninstall Command       | cmd.exe /c del %PROGRAMDATA%\UninstallBloatware\UninstallBloatware.tag |
| Install Behavior        | System                                                                                  |
| Device restart behavior | No specific action                                                                      |
| Return Codes            | 0: Success<br>1707: Success<br>3010: Soft Reboot<br>1641: Hard Reboot<br>1618: Retry<br>1605: Unknown Product |

## Requirements

| Property                      | Value           |
| ----------------------------- | --------------- |
| Operating system architecture | 64-bit          |
| Minimum operating system      | Windows 10 1607 |

## Detection Rules

Rules Format: Manually configure detection rules

### Rule 1

| Property                                       | Value                                                   |
| ---------------------------------------------- | ------------------------------------------------------- |
| Type                                           | File                                                    |
| Path                                           | %PROGRAMDATA%\UninstallBloatware                        |
| File or folder                                 | UninstallBloatware.tag                                  |
| Detection method                               | File or folder exists                                   |
| Associated with a 32-bit app on 64-bit clients | No                                                      |

## Dependencies

None

## Supersedence

None

## Assignments

Recommend this be installed for all Autopilot computers.
