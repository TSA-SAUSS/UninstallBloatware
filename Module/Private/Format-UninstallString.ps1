function Format-UninstallString {
    <#
        .SYNOPSIS
        Wraps the path of an executable file in quotes.

        .DESCRIPTION
        Wraps the path of an executable file in quotes.

        .PARAMETER UninstallString
        A string that could have '.exe' in it.

        .EXAMPLE
        Format-UninstallString -UninstallString "C:\Program Files\HP\HP Velocity\Uninstall.exe -s -fixyourmessHP"

        .INPUTS
        String

        .OUTPUTS
        String

        .NOTES
        Original Author: Sean Sauve
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string]$UninstallString
    )

    $exePosition = $UninstallString.IndexOf('.exe')
    $quotePosition = $UninstallString.IndexOf('"')

    if (($exePosition -ne -1) -and (($quotePosition -eq -1) -or ($quotePosition -gt $exePosition))){
        Write-Verbose "Format-UninstallString: no quotation mark or first quotation mark is after '.exe'."
        Write-Verbose "wraping the string in quotes from the beginning of the string to the end of '.exe'"
        $output = '"' + $UninstallString.Substring(0, $exePosition + 4) + '"' + $UninstallString.Substring($exePosition + 4)
        $output
    }
    else {
        $UninstallString
    }
}
