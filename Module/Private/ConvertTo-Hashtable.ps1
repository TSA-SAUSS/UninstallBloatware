function ConvertTo-Hashtable {
    <#
        .SYNOPSIS
        Converts an object to a hashtable

        .DESCRIPTION
        Converts an object to a hashtable

        .PARAMETER InputObject
        The object you want to convert to a hashtable

        .EXAMPLE
        Get-Content -Path './myfile.json' -Raw | ConvertFrom-Json | ConvertTo-HashTable

        .INPUTS
        InputObject

        .OUTPUTS
        Hashtable.

        .NOTES
        Original Author: Adam Bertram
        Original Link: https://4sysops.com/archives/convert-json-to-a-powershell-hash-table
        Updated by Sean Sauve
    #>

    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {

        if ($null -eq $InputObject) {
            return $null
        }

        if ($InputObject -is [system.collections.ienumerable] -and $InputObject -isnot [string]) {
            Write-Verbose "ConvertTo-Hashtable: `$InputObject is an array or collection.  Convert each to hash table when applicable."
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )
            $collection
        }
        elseif ($InputObject -is [psobject]) {
            Write-Verbose "ConvertTo-Hashtable: `$InputObject has properties that need enumeration."
            $hashtable = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hashtable[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hashtable
        }
        else {
            Write-Verbose "ConvertTo-Hashtable: `$InputObject is already a hashtable."
            $InputObject
        }
    }
}
