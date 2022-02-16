function Get-RegistryEntry {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $regPaths = @(
        'hklm:\software\microsoft\windows\currentversion\uninstall',
        'hklm:\software\wow6432node\microsoft\windows\currentversion\uninstall'
    )
    $entries = (Get-ChildItem -Path $regPaths | Get-ItemProperty | Where-Object DisplayName -eq $Name)
    $entries
}
