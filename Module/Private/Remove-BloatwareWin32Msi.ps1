function Remove-BloatwareWin32Msi {
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

        [Parameter()]
        [switch]
        $WarnOnMissingInstallStringEveryTime,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $CustomSuffix,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int64[]]
        $SuccessExitCodes = @(0, 1707, 3010, 1641)
    )

    $uninstallStringCount = 0
    foreach ($registryEntry in $RegistryEntries) {
        If ($registryEntry.UninstallString) {
            Write-Verbose "Remove-BloatwareWin32Msi: using UninstallString $($registryEntry.UninstallString)"
            $reGuid = '\{?(([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12})\}?'
            if ($registryEntry.UninstallString -match $reGuid) {

                $uninstall = "MsiExec.exe /qn /norestart /X{$($matches[1])}"
                if ($PSBoundParameters.ContainsKey('LogDirectory')) {
                    $msiLog = "$LogDirectory\$($Name.Replace(' ', ''))-$(Get-Date -Format 'yyyyMMdd-HH-mm').log"
                    $uninstall = $uninstall + " /L*V `"$msiLog`""
                }
                if ($PSBoundParameters.ContainsKey('CustomSuffix')) {
                    $uninstall = "$uninstall $CustomSuffix"
                }

                $uninstallStringCount += 1
                Write-Host "`tUninstalling application with uninstall string '$uninstall'"
                if ($PSCmdlet.ShouldProcess("$Name", 'Uninstall')) {
                    & cmd.exe /c $uninstall | Out-Host

                    if ($LastExitCode -in $SuccessExitCodes) {
                        Write-Host "`tExit Code: $LastExitCode"
                        Write-Host "`tFinished uninstalling application $Name"
                    }
                    else {
                        Write-Error "Exit code $LastExitCode uninstalling $Name" -ErrorAction 'Stop'
                        return
                    }
                }
            }
            elseif ($WarnOnMissingInstallStringEveryTime) {
                Write-Warning "`tApplication uninstall string doesn't contain a standard GUID.  Maybe there are two entries?"
            }
        }
        elseif ($warnOnMissingInstallStringEveryTime)  {
                Write-Warning "`tApplication does not have an uninstall string.  Maybe there are two entries?"
        }

        $newRegistryEntries = $null
        $newRegistryEntries = @(Get-RegistryEntry -Name $Name)
        if ($newRegistryEntries.Count -eq 0) {
            Write-Host "$Name no longer installed"
            return
        }
    }
    if ($uninstallStringCount -eq 0) {
        Write-Warning "`tNo valid uninstall strings found"
    }
}
