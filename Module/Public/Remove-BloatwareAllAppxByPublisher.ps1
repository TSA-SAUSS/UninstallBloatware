function Remove-BloatwareAllAppxByPublisher {
    #requires -RunAsAdministrator
    [OutputType([uint32])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string[]]$Publisher
    )

    [int]$errorCount = 0
    foreach($singlePublisher in $Publisher) {
        $packages = Get-AppxPackage -AllUsers | Where-Object {($_.Publisher -eq $singlePublisher) -or ($_.PublisherId -eq $singlePublisher)}
        Write-Host "$($packages.Count) Appx packages found by publisher $singlePublisher"
        $packageNames = $packages.Name | Sort-Object | Get-Unique -AsString
        foreach($packageName in $packageNames) {
            try {
                Remove-BloatwareAppx -PackageName $packageName | Out-Null
            }
            catch {
                Write-Warning "ERROR when removing application $packageName`:"
                Write-Warning $_.Exception.Message
                $errorCount += 1
                continue
            }
        }
    }

    $errorCount
}
