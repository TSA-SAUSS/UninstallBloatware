function Remove-BloatwareAllAppxByPublisher {
    #requires -RunAsAdministrator
    [OutputType([uint32])]
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false
    )]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Publisher,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$BulkRemoveAllAppxExcludedApps
    )

    [int]$errorCount = 00
    $packageTypeFilters = @(
        'Bundle'
        'Resource'
        'Framework'
        'Main'
    )
    foreach($singlePublisher in $Publisher) {
        foreach ($packageTypeFilter in $packageTypeFilters) {
            $packages = Get-AppxPackage -AllUsers -PackageTypeFilter $packageTypeFilter |
                Where-Object {($_.Publisher -eq $singlePublisher) -or ($_.PublisherId -eq $singlePublisher)}
            if ($PSBoundParameters.ContainsKey('BulkRemoveAllAppxExcludedApps')) {
                $packages = $packages | Where-Object Name -NotIn $BulkRemoveAllAppxExcludedApps
                Write-Host "$($packages.Count) unexcluded Appx packages ($packageTypeFilter) found by publisher $singlePublisher"
            }
            else {
                Write-Host "$($packages.Count) Appx packages ($packageTypeFilter) found by publisher $singlePublisher"
            }
            $packageNames = $packages.Name | Sort-Object | Get-Unique -AsString
            foreach($packageName in $packageNames) {
                try {
                    if ($PSCmdlet.ShouldProcess("$packageName", 'Remove')) {
                        Remove-BloatwareAppx -PackageName $packageName -PackageTypeFilter $packageTypeFilter | Out-Null
                    }
                }
                catch {
                    Write-Warning "ERROR when removing application $packageName`:"
                    Write-Warning $_.Exception.Message
                    $errorCount += 1
                }
            }
        }
    }

    $errorCount
}
