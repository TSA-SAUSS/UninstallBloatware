
function Test-VariableName {
   <#
        .SYNOPSIS
        Tests if the variable name will need to be wrapped in ${} to be valid.

        .DESCRIPTION
        Tests if the variable name will need to be wrapped in ${} to be valid.
        Do not include the '$'.

        .PARAMETER Name
        The variable name to test.

        .EXAMPLE
        Test-VariableName -Name 'MyVariableName'

        .INPUTS
        Name, a string

        .OUTPUTS
        Boolean.  True means the variable name is valid without using ${}.

        .NOTES
        Original Author: Sean Sauve
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name
    )

    if($Name.IndexOf("env:") -eq 0) {
        $testingName = $Name.Substring(4)
    } else {
        $testingName = $Name
    }

    if(($null -eq $testingName) -or ('' -eq $testingName)) {
        $false
        return
    }

    $validUnicodeCategories = @(
        0 #Lu UppercaseLetter
        1 #Ll LowercaseLetter
        2 #Lt TitlecaseLetter
        3 #Lm ModifierLetter
        4 #Lo OtherLetter
        8 #Nd DecimalDigitNumber
    )

    $validOtherChars = @('_', '?')

    foreach($char in $testingName.ToCharArray()) {
        if(([Globalization.CharUnicodeInfo]::GetUnicodeCategory($char) -notin $validUnicodeCategories) -and ($char -notin $validOtherChars)) {
            $false
            return
        }
    }

    $true
}
