function Remove-BloatwareWin32Custom {
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
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
        [string[]]
        $CustomPaths,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $CustomArguments,

        [Parameter(ParameterSetName = 'MissingPathEqualsSuccess')]
        [Parameter(ParameterSetName = 'MissingPathEqualsPassthrough', Mandatory)]
        [Parameter(ParameterSetName = 'MissingPathEqualsMsi', Mandatory)]
        [Parameter(ParameterSetName = 'ForcingUninstall')]
        [ValidateNotNullOrEmpty()]
        $RegistryEntries,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $LogDirectory,

        [Parameter(ParameterSetName = 'MissingPathEqualsPassthrough')]
        [Parameter(ParameterSetName = 'MissingPathEqualsMsi')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CustomSuffix,

        [ValidateNotNullOrEmpty()]
        [int64[]]
        $SuccessExitCodes = @(0, 1707, 3010, 1641),

        [Parameter(ParameterSetName = 'ForcingUninstall')]
        [Parameter(ParameterSetName = 'MissingPathEqualsSuccess', Mandatory)]
        [switch]
        $MissingPathEqualsSuccess,

        [Parameter(ParameterSetName = 'ForcingUninstall')]
        [Parameter(ParameterSetName = 'MissingPathEqualsPassthrough', Mandatory)]
        [switch]
        $MissingPathEqualsPassthrough,

        [Parameter(ParameterSetName = 'ForcingUninstall')]
        [Parameter(ParameterSetName = 'MissingPathEqualsMsi', Mandatory)]
        [switch]
        $MissingPathEqualsMsi,

        [Parameter(ParameterSetName = 'ForcingUninstall', Mandatory)]
        [switch]
        $ForcingUninstall
    )

    $customPath = $null
    foreach($customPathTest in $CustomPaths) {
        if (Test-Path $customPathTest) {
            Write-Verbose "Remove-BloatwareWin32Custom: found path $customPathTest"
            $customPath = $customPathTest
        }
    }

    if ($null -eq $customPath) {
        if ($MissingPathEqualsSuccess) {
            Write-Warning "CustomPaths not found when uninstalling $Name but MissingPathEqualsSuccess is true"
            return
        }
        elseif ($ForcingUninstall) {
            Write-Host "$Name not installed."
            return
        }
        elseif ($MissingPathEqualsMsi) {
            Write-Warning "CustomPaths not found when uninstalling $Name, attempting msi"
            $params = @{'Name' = $Name}
            $params = Add-Hash -FromHashtable $PSBoundParameters -ToHashtable $params -KeyName @(
                'RegistryEntries'
                'LogDirectory'
                'WarnOnMissingInstallStringEveryTime'
                'CustomSuffix'
                'SuccessExitCodes'
            )
            Remove-BloatwareWin32Msi @params
            return
        }
        elseif ($MissingPathEqualsPassthrough) {
            Write-Warning "CustomPaths not found when uninstalling $Name, attempting passthrough"
            $params = @{'Name' = $Name}
            $params = Add-Hash -FromHashtable $PSBoundParameters -ToHashtable $params -KeyName @(
                'RegistryEntries'
                'SuccessExitCodes'
                'MissingPathEqualsSuccess'
                'CustomSuffix'
            )
            #Logs not implemented
            Remove-BloatwareWin32Passthrough @params
            return
        }
        else {
            Write-Error "CustomPaths not found when uninstalling $Name" -ErrorAction 'Stop'
            return
        }
    }

    $uninstall = "`"$CustomPath`""
    if ($PSBoundParameters.ContainsKey('CustomArguments')) {
        $uninstall = "$uninstall $CustomArguments"
    }
    Write-Host "`tUninstalling application with command '$uninstall'"
    if ($PSCmdlet.ShouldProcess("$Name", 'Uninstall')) {
        & cmd.exe /c $uninstall | Out-Host
        if ($LastExitCode -in $SuccessExitCodes) {
            Write-Host "`tExit Code: $LastExitCode"
            Write-Host "`tFinished uninstalling application $Name"
        }
        else {
            Write-Error "Exit code $LastExitCode uninstalling $Name" -ErrorAction 'Stop'
        }
    }
}
