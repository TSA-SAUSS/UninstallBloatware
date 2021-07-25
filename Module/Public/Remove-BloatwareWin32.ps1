function Remove-BloatwareWin32 {
    #requires -RunAsAdministrator
    [CmdletBinding(DefaultParameterSetName = 'MSI')]
    param (
        [Parameter(ParameterSetName = 'MSI', Mandatory)]
        [Parameter(ParameterSetName = 'Passthrough', Mandatory)]
        [Parameter(ParameterSetName = 'InstallShield', Mandatory)]
        [Parameter(ParameterSetName = 'Custom', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'MSI')]
        [Parameter(ParameterSetName = 'Passthrough')]
        [Parameter(ParameterSetName = 'InstallShield')]
        [Parameter(ParameterSetName = 'Custom')]
        [ValidateNotNullOrEmpty()]
        [string]
        $LogDirectory,

        [Parameter(ParameterSetName = 'MSI')]
        [Parameter(ParameterSetName = 'Passthrough')]
        [Parameter(ParameterSetName = 'InstallShield')]
        [Parameter(ParameterSetName = 'Custom')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DeleteRegistryKey,

        [Parameter(ParameterSetName = 'MSI')]
        [Parameter(ParameterSetName = 'Passthrough')]
        [Parameter(ParameterSetName = 'InstallShield')]
        [Parameter(ParameterSetName = 'Custom')]
        [switch]
        $DeleteUninstallKeyAfterRemove,

        [Parameter(ParameterSetName = 'MSI')]
        [Parameter(ParameterSetName = 'Passthrough')]
        [Parameter(ParameterSetName = 'InstallShield')]
        [Parameter(ParameterSetName = 'Custom')]
        [ValidateNotNullOrEmpty()]
        [int64[]]
        $SuccessExitCodes,

        [Parameter(ParameterSetName = 'Custom')]
        [Parameter(ParameterSetName = 'Passthrough')]
        [switch]
        $MissingPathEqualsSuccess,

        [Parameter(ParameterSetName = 'MSI')]
        [Parameter(ParameterSetName = 'Passthrough')]
        [Parameter(ParameterSetName = 'InstallShield')]
        [Parameter(ParameterSetName = 'Custom')]
        [switch]
        $RequiresDevelopment,

        [Parameter(ParameterSetName = 'MSI')]
        [switch]
        $FalseDoubleEntry,

        [Parameter(ParameterSetName = 'MSI')]
        [Parameter(ParameterSetName = 'Passthrough')]
        [Parameter(ParameterSetName = 'Custom')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CustomSuffix,

        [Parameter(ParameterSetName = 'Passthrough')]
        [switch]
        $Passthrough,

        [Parameter(ParameterSetName = 'Passthrough')]
        [switch]
        $MissingPathEqualsPrivateUninstallString,

        [Parameter(ParameterSetName = 'Passthrough')]
        [switch]
        $UsePrivateUninstallString,

        [Parameter(ParameterSetName = 'InstallShield')]
        [switch]
        $InstallShield,

        [Parameter(ParameterSetName = 'InstallShield', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ISSTemplate,

        [Parameter(ParameterSetName = 'InstallShield')]
        [switch]
        $ReplaceGUID,

        [Parameter(ParameterSetName = 'InstallShield')]
        [switch]
        $ReplaceVersion,

        [Parameter(ParameterSetName = 'Custom')]
        [switch]
        $Custom,

        [Parameter(ParameterSetName = 'Custom', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $CustomPaths,

        [Parameter(ParameterSetName = 'Custom')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CustomArguments,

        [Parameter(ParameterSetName = 'Custom')]
        [switch]
        $MissingPathEqualsPassthrough,

        [Parameter(ParameterSetName = 'Custom')]
        [switch]
        $MissingPathEqualsMsi,

        [Parameter(ParameterSetName = 'Custom')]
        [switch]
        $ForceUninstallWithoutRegistry
    )

    $regPaths = @(
        'hklm:\software\microsoft\windows\currentversion\uninstall',
        'hklm:\software\wow6432node\microsoft\windows\currentversion\uninstall'
    )
    $registryEntries = (Get-ChildItem -Path $regPaths | Get-ItemProperty | Where-Object DisplayName -eq $Name)

    $forcingUninstall = (($registryEntries.Count -eq 0) -and $ForceUninstallWithoutRegistry)

    if (($registryEntries.Count -eq 0) -and (-not $forcingUninstall)) {
        Write-Host "$Name not installed."
        return
    }

    if ($forcingUninstall) {
        Write-Verbose "0 copies of $Name found but `$ForceUninstallWithoutRegistry is set."
    }
    else {
        Write-Host "Found $($registryEntries.Count) copies of $Name"
    }

    if ($RequiresDevelopment) {
        Write-Warning "`tApplication $Name uninstall is untested.  Attempting to uninstall anyway."
    }

    if ($PSBoundParameters.ContainsKey('DeleteRegistryKey')) {
        foreach($key in $DeleteRegistryKey) {
            if (Test-Path $key) {
                Write-Host "`tDeleting key: $key"
                Remove-Item -Path $key -Force -Recurse
            }
            elseif (-not $forcingUninstall) {
                Write-Host "`tCould not find key specified in arguments: $key"
            }
        }
    }

    $params = @{'Name' = $Name}
    $params = Add-Hash -FromHashtable $PSBoundParameters -ToHashtable $params -Verbose:$false -KeyName @(
        'LogDirectory'
        'SuccessExitCodes'
        'CustomSuffix'
        'MissingPathEqualsSuccess'
        'MissingPathEqualsPrivateUninstallString'
        'UsePrivateUninstallString'
        'ISSTemplate'
        'ReplaceGUID'
        'ReplaceVersion'
        'CustomPaths'
        'CustomArguments'
        'MissingPathEqualsSuccess'
        'MissingPathEqualsPassthrough'
        'MissingPathEqualsMsi'
    )

    if (-not $forcingUninstall) {
        $params += @{'RegistryEntries' = $registryEntries}
    }

    if ($PSCmdlet.ParameterSetName -eq 'MSI') {
        if ($FalseDoubleEntry) {
            Write-Host "`tApplication should use a standard uninstall string, but may have a false double entry in the registry."
        }
        else {
            Write-Host "`tApplication should use a standard uninstall string."
            $params += @{'WarnOnMissingInstallStringEveryTime' = $true}
        }

        Write-Verbose "Remove-BloatwareWin32: using these parameters to pass down:"
        foreach($key in $params.GetEnumerator()) {
            Write-Verbose "$($key.Name) : $($key.Value)"
        }

        Remove-BloatwareWin32Msi @params
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Passthrough') {
        Write-Host "`tApplication uses a custom command to uninstall stored in the UninstallString"

        Write-Verbose "Remove-BloatwareWin32: using these parameters to pass down:"
        foreach($key in $params.GetEnumerator()) {
            Write-Verbose "$($key.Name) : $($key.Value)"
        }

        #Logs not implemented
        Remove-BloatwareWin32Passthrough @params
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'InstallShield') {
        Write-Host "`tApplication uses an InstallShield ISS file to uninstall."

        Write-Verbose "Remove-BloatwareWin32: using these parameters to pass down:"
        foreach($key in $params.GetEnumerator()) {
            Write-Verbose "$($key.Name) : $($key.Value)"
        }

        Remove-BloatwareWin32InstallShield @params
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Custom') {
        if (-not $forcingUninstall) {
            Write-Host "`tApplication uses a custom uninstaller."
        }
        $params['ForcingUninstall'] = $forcingUninstall

        Write-Verbose "Remove-BloatwareWin32: using these parameters to pass down:"
        foreach($key in $params.GetEnumerator()) {
            Write-Verbose "$($key.Name) : $($key.Value)"
        }

        #Logs not implemented
        Remove-BloatwareWin32Custom @params
    }

    if ($DeleteUninstallKeyAfterRemove) {
        foreach($regEntry in $registryEntries) {
            if (Test-Path $regEntry.PSPath) {
                Write-Host "`tDeleting registry key $($regEntry.PSPath)"
                Remove-Item -Path $regEntry.PSPath -Force -Recurse
            }
        }
    }
}
