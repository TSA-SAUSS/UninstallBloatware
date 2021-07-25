function Remove-BloatwareWin32InstallShield {
    [CmdletBinding()]
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

    foreach ($registryEntry in $RegistryEntries) {
        $uninstall = $RegistryEntries.UninstallString
        if ($null -eq $uninstall) {
            Write-Warning "`tRegistry entry UninstallString is null"
            continue
        }
        if($uninstall.IndexOf(".exe`"") -eq -1) {
            Write-Warning "`tRegistry entry UninstallString ($uninstall) could not be parsed"
            continue
        }
        $uninstall = Format-UninstallString -UninstallString $uninstall
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

    if ($uninstallStringCount -eq 0) {
        Write-Error "`tNo valid uninstall strings found"
    }
}
