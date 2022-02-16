Function New-InTuneWinPackage {
    [CmdletBinding()]
    param (
        [string]$AppSubfolderName
    )

    try {
        $dotnetVersion = & dotnet --version
    } catch {
        Write-Error "Cannot find .NET Core SDK.  Please install version 3.1 or higher"
    }
    if ($dotnetVersion -lt 3.1.408) {
        Write-Error "Requires .NET Core SDK version 3.1 or higher."
    }
    if (-not ((dotnet tool list --global) -like "*intuneappbuilder.console*")) {
        Write-Error "Intuneappbuilder is not installed.  Please see instructions to install it here: https://github.com/simeoncloud/IntuneAppBuilder"
    }

    Write-Host "------Making intunewin file------"
    if ($PSBoundParameters.ContainsKey('AppSubfolderName')) {
        $appFolder = "$PSScriptRoot\$AppSubfolderName"
    }
    else {
        $appFolder = "$PSScriptRoot"
    }
    IntuneAppBuilder pack --source $appFolder\Content --output $appFolder\Output

    Write-Host ""
    Write-Host "Review the JSON file 'Content.intunewin.json'."
    Write-Host "When ready upload 'Content.portal.intunewin' to the InTune portal"
}

New-InTuneWinPackage
