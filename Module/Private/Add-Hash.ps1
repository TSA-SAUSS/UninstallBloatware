function Add-Hash {
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
