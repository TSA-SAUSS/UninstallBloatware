function Remove-BloatwareAppx {
    #requires -RunAsAdministrator
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$PackageName,

        [string[]]$PackageTypeFilter = $null
    )

    begin {
        if ($null -eq $PackageTypeFilter) {
            $packageTypeFilters = @(
                'Bundle'
                'Resource'
                'Framework'
                'Main'
            )
        }
        else {
            $packageTypeFilters = $PackageTypeFilter
        }
    }

    process {
        foreach($singlePackageName in $PackageName) {
            foreach ($singlePackageTypeFilter in $packageTypeFilters) {
                $packages = Get-AppxPackage -AllUsers -PackageTypeFilter $singlePackageTypeFilter  |
                    Where-Object Name -match $singlePackageName
                foreach($package in $packages) {
                    Write-Host "Removing Appx ($singlePackageTypeFilter) package $singlePackageName"
                    $package | Remove-AppxPackage -Allusers
                    Write-Host "`tFinished removing Appx ($singlePackageTypeFilter) package $singlePackageName"
                }
            }
        }
    }

    end {

    }
}
