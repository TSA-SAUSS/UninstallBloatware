function Remove-BloatwareAppxProvisioned {
    #requires -RunAsAdministrator
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline)][string[]]$PackageName
    )

    begin {
        $allAppxProvisioned = Get-AppxProvisionedPackage -Verbose:$false -Online
    }

    process {
        foreach($singlePackageName in $PackageName) {
            $packages = $allAppxProvisioned | Where-Object DisplayName -match $singlePackageName
            foreach($package in $packages) {
                Write-Host "Removing Appx Provisioned package $singlePackageName"
                if ($PSCmdlet.ShouldProcess("$singlePackageName", 'Remove')) {
                    $package | Remove-AppxProvisionedPackage -AllUsers -Online -Verbose:$false
                }
                Write-Host "`tFinished removing Appx Provisioned package $singlePackageName"
            }
        }
    }

    end {

    }
}
