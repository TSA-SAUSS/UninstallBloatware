function Remove-BloatwareAllAppxProvisionedByPublisher {
    #requires -RunAsAdministrator
    [OutputType([uint32])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string[]]$PublisherId
    )

    [int]$errorCount = 0
    foreach($singlePublisherId in $PublisherId) {
        $packages = Get-AppxProvisionedPackage -Online | Where-Object PublisherId -eq $singlePublisherId
        Write-Host "$($packages.Count) Appx provisioned packages found by publisher $singlePublisherId"
        $packageNames = $packages.DisplayName | Sort-Object | Get-Unique -AsString
        foreach($packageName in $packageNames) {
            try {
                Remove-BloatwareAppxProvisioned -PackageName $packageName | Out-Null
            }
            catch {
                Write-Warning "ERROR when removing application $packageName`:"
                Write-Warning $_.Exception.Message
                $errorCount += 1
                Continue
            }
        }
    }

    $errorCount
}
