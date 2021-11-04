function Remove-BloatwareWin32Passthrough {
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

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int64[]]
        $SuccessExitCodes = @(0, 1707, 3010, 1641),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $CustomSuffix,

        [Parameter()]
        [switch]
        $MissingPathEqualsSuccess,

        [Parameter()]
        [switch]
        $MissingPathEqualsPrivateUninstallString,

        [Parameter()]
        [switch]
        $UsePrivateUninstallString

    )

    $uninstallStringCount = 0

    :foreachRegistryEntry foreach ($registryEntry in $RegistryEntries) {
        $tryPrivateStringNext = $MissingPathEqualsPrivateUninstallString
        if ($UsePrivateUninstallString) {
            $uninstall = $registryEntry.PrivateUninstallString
            $tryPrivateStringNext = $false
        } else {
            $uninstall = $registryEntry.UninstallString
        }
        if(($null -eq $uninstall) -or ('' -eq $uninstall)) {
            if($tryPrivateStringNext -and ($null -ne $registryEntry.PrivateUninstallString) -and ('' -ne $registryEntry.PrivateUninstallString)) {
                $uninstall = $registryEntry.PrivateUninstallString
                $tryPrivateStringNext = $false
            }
            else {
                Write-Warning "`tRegistry entry UninstallString is null or empty"
                continue foreachRegistryEntry
            }
        }

        $uninstallStringCount += 1
        $uninstall = Format-UninstallString -UninstallString $uninstall
        if ($PSBoundParameters.ContainsKey('CustomSuffix')) {
            $uninstall = $uninstall + " $CustomSuffix"
        }
        Write-Host "`tUninstalling application with uninstall string '$uninstall'"
        & cmd.exe /c $uninstall | Out-Host

        if ($LastExitCode -in $SuccessExitCodes) {
            Write-Host "`tExit Code: $LastExitCode"
            Write-Host "`tFinished uninstalling application $Name"
        }
        else {
            if (($LastExitCode -eq 1) -and $tryPrivateStringNext) {
                Write-Warning "Exit code $LastExitCode uninstalling $Name but MissingPathEqualsPrivateUninstallString is true."
                $params = @{
                    'Name'                                    = $Name
                    'RegistryEntries'                         = $registryEntry
                    'SuccessExitCodes'                        = $SuccessExitCodes
                    'CustomSuffix'                            = $CustomSuffix
                    'MissingPathEqualsSuccess'                = $MissingPathEqualsSuccess
                    'UsePrivateUninstallString'               = $UsePrivateUninstallString
                }
                #Logs not implemented
                Remove-BloatwareWin32Passthrough @params
                return
            }
            elseif (($LastExitCode -eq 1) -and ($MissingPathEqualsSuccess)) {
                Write-Warning "Exit code $LastExitCode uninstalling $Name but MissingPathEqualsSuccess is true."
            }
            else {
                Write-Error "Exit code $LastExitCode uninstalling $Name" -ErrorAction 'Stop'
                return
            }
        }

        $newRegistryEntries = $null
        $newRegistryEntries = (Get-RegistryEntry -Name $Name)
        if ($newRegistryEntries.Count -eq 0) {
            Write-Host "$Name no longer installed."
            return
        }
    }

    if ($uninstallStringCount -eq 0) {
        Write-Error "`tNo valid uninstall strings found"
    }
}
