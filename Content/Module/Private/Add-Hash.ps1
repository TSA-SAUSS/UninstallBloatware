function Add-Hash {
    <#
        .SYNOPSIS
        Adds keys and values from one hashtable to another and returns the result.

        .DESCRIPTION
        Adds keys and values from one hashtable to another and returns the result.  Looks for KeyName in FromHashtable and adds to ToHashtable

        .PARAMETER FromHashtable
        The hashtable that has the keys to add to ToHashtable.

        .PARAMETER ToHashtable
        The hashtable that the keys will be added to.

        .PARAMETER KeyName
        String array of the keys to look for.

        .EXAMPLE
        Add-Hash -FromHashtable $fromHash -ToHashtable $toHash -KeyName @('MyKey1', 'MyKey2')

        .INPUTS
        Two hashtables and a string array.

        .OUTPUTS
        Hashtable.

        .NOTES
        Original Author: Sean Sauve
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory)]
        [hashtable]$FromHashtable,

        [Parameter(Mandatory)]
        [hashtable]$ToHashtable,

        [Parameter(Mandatory)]
        [string[]]$KeyName
    )

    foreach($singleKeyName in $KeyName) {
        Write-Verbose "Add-Hash: Looking for key (`$singleKeyName): $singleKeyName"
        if ($FromHashtable.ContainsKey($singleKeyName)) {
            Write-Verbose "Add-Hash: Adding key (from `$FromHashTable to `$ToHashTable): $singleKeyName = $($FromHashtable[$singleKeyName])"
            $ToHashtable += @{$singleKeyName = $FromHashtable[$singleKeyName]}
        }
        else {
            Write-Verbose "Add-Hash: Could not find key (`$singleKeyName in hashtable `$FromHashtable): $singleKeyName"
        }
    }

    $ToHashtable
}
