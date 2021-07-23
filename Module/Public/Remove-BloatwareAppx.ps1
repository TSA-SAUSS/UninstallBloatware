function Remove-BloatwareAppx {
    #requires -RunAsAdministrator
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)][string[]]$PackageName
    )

    begin {
        $allAppx = Get-AppxPackage -AllUsers
    }

    process {
        foreach($singlePackageName in $PackageName) {
            $packages = $allAppx | Where-Object Name -match $singlePackageName
            foreach($package in $packages) {
                Write-Host "Removing Appx package $singlePackageName"
                $package | Remove-AppxPackage -Allusers
                Write-Host "`tFinished removing Appx package $singlePackageName"
            }
        }
    }

    end {

    }
}
