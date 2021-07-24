function Uninstall-Bloatware {
    #requires -RunAsAdministrator
    <#
        .SYNOPSIS
        Uninstalls undesirable applications that are pre-installed.

        .DESCRIPTION
        The Uninstall-Bloatware.ps1 script searches for applications in either
        Appx Provisioned, Appx, and Win32 format and removes them.

        This script expects the module and files for UninstallBloatware.psm1
        to be located in "$PSScriptRoot\Modules\"

        .PARAMETER LogDirectory
        Specifies the location to store the transcript and logs.

        If you do not specify this parameter, no transcript, tag file, or logs will be taken.

        .PARAMETER BulkRemoveAllAppxPublishers
        Specifies the publishers from which to remove Appx Provisioned and Appx
        packages.  Use the the Publisher and PublisherId output from
        Get-AppxProvisionedPackage and Get-AppxPackage in order to determine the
        publishers.

        Optional.

        .PARAMETER BloatwaresAppx
        Specifies the Appx Provisioned and Appx packages to remove.

        Optional.

        .PARAMETER BloatWaresWin32
        A string array specifying the Win32 applications to remove.  If instructions
        have not yet been written for a particular Win32 application then this script
        will use MsiExec and warn ahead of time the application requires development.

        Some applications can't be removed before dependant applications have been
        removed.  In this case, list the dependant applications first.

        Optional.

        .PARAMETER NoTranscript
        By default this script takes a transcript if you specify LogDirectory.
        Specify this switch to avoid taking a transcript.

        .PARAMETER NoTagFile
        By default this script creates the file UninstallBloatware.tag in LogDirectory
        when there were no errors.  This is useful for InTune to know if this module has run successfully.
        Specify this switch to not create the tag file.

        .PARAMETER InstructionVariableNames
        Optionally specify the variables that will be searched for.  Do not include the $ in variable names
        when specifying it in VariableNames.

        When reading JSON instruction files, Uninstall-Bloatware will search for each variable using
        up to three possible ways it could appear in the file:
            $VariableName
            $($VariableName)
            ${VariableName}

        Scope modifiers and namespaces other than Env: are not yet supported.

        Other than those in the Env: namespace, variable names that require ${} are not yet supported.

        The default value is:
            env:ProgramData
            env:ProgramFiles
            env:SystemDrive
            env:ProgramFiles(x86)
            env:CommonProgramW6432
            env:CommonProgramFiles(x86)
            env:DriverData
            env:CommonProgramFiles
            env:TEMP
            env:TMP
            env:ProgramW6432
            env:windir
            PSScriptRoot

        PSScriptRoot will be the directory of the JSON instruction file.

        When reading variables from within JSON instruction files any variable whose value contains
        a semicolon will throw an error.

        Does accepts $null or an empty string.

        .PARAMETER CustomWin32InstructionsDirectory
        Specify to add a directory to look in when searching for Win32 application
        uninstall instructions.  Instructions in this directory will override the built-in
        application instructions.

        .EXAMPLE
        PS> Uninstall-Bloatware -LogDirectory "C:\Temp" -BloatwaresWin32 @('HP Sure Click', 'HP Sure Connect')

        .EXAMPLE
        PS> Uninstall-Bloatware -LogDirectory "C:\Temp" -BulkRemoveAllAppxPublishers @('v10z8vjag6ke6', 'CN=ED346674-0FA1-4272-85CE-3187C9C86E26')

        .EXAMPLE
        PS> Uninstall-Bloatware -LogDirectory "C:\Temp" -BloatwaresAppx @('HPAudioControl', 'HPDesktopSupportUtilities')

        .NOTES
        Original Author: Sean Sauve
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$LogDirectory,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$BulkRemoveAllAppxPublishers,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$BloatwaresAppx,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$BloatwaresWin32,

        [Parameter()]
        [switch]$NoTranscript,

        [Parameter()]
        [switch]$NoTagFile,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$CustomWin32InstructionsDirectory,

        [Parameter()]
        [string[]]
        $InstructionVariableNames
    )

    if ((-not $NoTranscript) -and $PSBoundParameters.ContainsKey('LogDirectory')) {
        Write-Host "Starting transcript."
        if (-not (Test-Path $LogDirectory)) {
            New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
        }
        Start-Transcript "$LogDirectory\Transcript.log" -Append
    }

    $errorCount = 0

    if ($PSBoundParameters.ContainsKey('BulkRemoveAllAppxPublishers')) {
        Write-Host "Begin processing all Appx and Appx Provisioned packages by publisher."
        $errorCount += Remove-BloatwareAllAppxProvisionedByPublisher -PublisherId $BulkRemoveAllAppxPublishers
        $errorCount += Remove-BloatwareAllAppxByPublisher -Publisher $BulkRemoveAllAppxPublishers
    }
    else {
        Write-Host "Skipping bulk removal of Appx and Appx Provisioned packages by publisher."
    }

    foreach($bloatwareAppx in $BloatwaresAppx) {
        Write-Host "Checking for Appx or Appx Provisioned package $bloatwareAppx."
        try {
            Remove-BloatwareAppxProvisioned -PackageName $bloatwareAppx
        }
        catch {
            Write-Warning "ERROR when removing application $bloatwareAppx`:"
            Write-Warning $_.Exception.Message
            $errorCount += 1
            continue
        }

        try {
            Remove-BloatwareAppx -PackageName $bloatwareAppx
        }
        catch {
            Write-Warning "ERROR when removing application $bloatwareAppx`:"
            Write-Warning $_.Exception.Message
            $errorCount += 1
            continue
        }
    }

    if($PSBoundParameters.ContainsKey('LogDirectory')) {
        $logParam = @{'LogDirectory' = $LogDirectory}
    }
    else {
        $logParam = @{}
    }
    $getInstructionsParams = @{}
    if($PSBoundParameters.ContainsKey('CustomWin32InstructionsDirectory')) {
        $getInstructionsParams['CustomDirectory'] = $CustomWin32InstructionsDirectory
    }
    if($PSBoundParameters.ContainsKey('InstructionVariableNames')) {
        $getInstructionsParams['InstructionVariableNames'] = $InstructionVariableNames
    }
    if ($PSBoundParameters.ContainsKey('BloatwaresWin32')) {
        Write-Host "Begin processing specific Win32 apps."
        foreach($bloatware in $BloatwaresWin32) {
            try {
                $instructions = Get-BloatwareWin32Instructions -Name $bloatware @getInstructionsParams
                Remove-BloatwareWin32 @instructions @logParam
            }
            catch {
                Write-Warning "ERROR when removing application $bloatware`:"
                Write-Warning $_.Exception.Message
                $errorCount += 1
                continue
            }
        }
    }
    else {
        Write-Host "Skipping removal of Win32 apps."
    }

    if ($errorCount -eq 0) {
        if ((-not $NoTagFile) -and $PSBoundParameters.ContainsKey('LogDirectory')) {
            Write-Host "Creating a tag file so that Intune knows this was ran successfully."
            Set-Content -Path "$LogDirectory\UninstallBloatware.tag" -Value "Success"
        }
    }
    else {
        Write-Warning "$errorCount errors encountered."
    }

    if ((-not $NoTranscript) -and $PSBoundParameters.ContainsKey('LogDirectory')) {
        Write-Host "Stopping Transcript."
        Stop-Transcript
    }
}
