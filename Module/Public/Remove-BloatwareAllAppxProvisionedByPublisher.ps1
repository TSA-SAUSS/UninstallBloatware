function Remove-BloatwareAllAppxProvisionedByPublisher {
    #requires -RunAsAdministrator
    [OutputType([uint32])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$PublisherId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$BulkRemoveAllAppxExcludedApps
    )

    [int]$errorCount = 0
    foreach($singlePublisherId in $PublisherId) {
        $packages = Get-AppxProvisionedPackage -Online -Verbose:$false | Where-Object PublisherId -eq $singlePublisherId
        if ($PSBoundParameters.ContainsKey('BulkRemoveAllAppxExcludedApps')) {
            $packages = $packages | Where-Object Name -NotIn $BulkRemoveAllAppxExcludedApps
            Write-Host "$($packages.Count) unexcluded Appx Provisioned packages found by publisher $singlePublisherId"
        }
        else {
            Write-Host "$($packages.Count) Appx Provisioned packages found by publisher $singlePublisherId"
        }
        $packageNames = $packages.DisplayName | Sort-Object | Get-Unique -AsString
        foreach($packageName in $packageNames) {
            try {
                Remove-BloatwareAppxProvisioned -PackageName $packageName | Out-Null
            }
            catch {
                Write-Warning "ERROR when removing application $packageName`:"
                Write-Warning $_.Exception.Message
                $errorCount += 1
            }
        }
    }

    $errorCount
}
