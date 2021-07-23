function Remove-BloatwareAppxProvisioned {
    #requires -RunAsAdministrator    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)][string[]]$PackageName
    )

    begin {
        $allAppxProvisioned = Get-AppxProvisionedPackage -Online
    }

    process {
        foreach($singlePackageName in $PackageName) {
            $packages = $allAppxProvisioned | Where-Object DisplayName -match $singlePackageName
            foreach($package in $packages) {
                Write-Host "Removing Appx Provisioned package $singlePackageName"
                $package | Remove-AppxProvisionedPackage -AllUsers -Online
                Write-Host "`tFinished removing Appx Provisioned package $singlePackageName"
            }
        }
    }

    end {
        
    }
}
