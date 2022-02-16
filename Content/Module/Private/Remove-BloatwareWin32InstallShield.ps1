function Remove-BloatwareWin32InstallShield {
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false
    )]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $RegistryEntries,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $LogDirectory,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ISSTemplate,

        [Parameter()]
        [switch]
        $ReplaceGUID,

        [Parameter()]
        [switch]
        $ReplaceVersion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int64[]]
        $SuccessExitCodes = @(0, 1707, 3010, 1641)
    )

    $uninstallStringCount = 0

    if ($PSBoundParameters.ContainsKey('LogDirectory')) {
        $tempDirectory = $LogDirectory
    }
    else {
        $tempDirectory = $PSScriptRoot
    }

    if($registryEntries.Count -gt 1) {
        if(($registryEntries.UninstallString | Select-Object -Unique).Count -eq 1) {
            $registryEntries | Select-Object -First 1
        }
    }

    :foreachRegistryEntry foreach ($registryEntry in $RegistryEntries) {
        $uninstall = $registryEntry.UninstallString
        if(($null -eq $uninstall) -or ('' -eq $uninstall)) {
            Write-Warning "`tRegistry entry UninstallString is null or empty"
            continue foreachRegistryEntry
        }
        $uninstall = Format-UninstallString -UninstallString $uninstall
        if($uninstall.IndexOf(".exe`"") -eq -1) {
            Write-Warning "`tRegistry entry UninstallString ($uninstall) could not be parsed"
            continue foreachRegistryEntry
        }

        $issContent = Get-Content $ISSTemplate
        if ($ReplaceGUID) {
            $issContent = $issContent.Replace('$GUID', $registryEntry.ProductGuid)
        }
        if ($ReplaceVersion) {
            $issContent = $issContent.Replace('$VERSION', $registryEntry.DisplayVersion)
        }

        $issFile = "$tempDirectory\ISSFile-$($Name.Replace(' ', '')).iss"
        $issContent | Out-File $issFile

        $setup = $uninstall.Substring(0, $uninstall.IndexOf(".exe") + 5)
        $uninstall = "$setup /s /f1`"$issFile`""
        if ($PSBoundParameters.ContainsKey('LogDirectory')) {
            $issLog = "$LogDirectory\$($Name.Replace(' ', ''))-$(Get-Date -Format 'yyyyMMdd-HH-mm').log"
            $uninstall = $uninstall + " /f2`"$issLog`""
        }

        $uninstallStringCount += 1
        Write-Host "`tUninstalling application with uninstall string '$uninstall'"
        if ($PSCmdlet.ShouldProcess("$Name", 'Uninstall')) {
            & cmd.exe /c $uninstall | Out-Host
            if ($LastExitCode -in $SuccessExitCodes) {
                Write-Host "`tExit Code: $LastExitCode"
                Write-Host "`tFinished uninstalling application with uninstall string '$uninstall'"
            }
            else {
                Write-Error "Exit code $LastExitCode uninstalling $Name" -ErrorAction 'Stop'
                return
            }
        }

        $newRegistryEntries = $null
        $newRegistryEntries = @(Get-RegistryEntry -Name $Name)
        if ($newRegistryEntries.Count -eq 0) {
            Write-Host "$Name no longer installed."
            return
        }
    }

    if ($uninstallStringCount -eq 0) {
        Write-Error "`tNo valid uninstall strings found"
    }
}
