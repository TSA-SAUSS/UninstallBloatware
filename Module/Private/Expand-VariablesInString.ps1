function Expand-VariablesInString {
    <#
        .SYNOPSIS
        Reads a string and looks for environment variable names to replace with their values.

        .DESCRIPTION
        Reads a string and looks for environment variable names to replace with their values.
        Supports the use of $PSScriptRoot with the parameter PSScriptRootDirectory.
        See the parameter help for PSScriptRootDirectory for the implementation details.

        .PARAMETER PSScriptRootDirectory
        Replaces occurances of $PSScriptRoot with a custom directory that you specify.

        .PARAMETER VariableNames
        Specify to restrict the variables that will be searched for.  Do not include the $ in variable names
        when specifying it in VariableNames.

        This function will search for each variable using up to three possible ways it could appear:
            $VariableName
            $($VariableName)
            ${VariableName}

        Scope modifiers and namespaces other than env: are not yet supported.

        Other than those in the Env: namespace, variable names that require ${} are not yet supported.

        Default value is:
            env:ProgramData
            env:ProgramFiles
            env:SystemDrive
            env:ProgramFiles(x86)
            env:CommonProgramW6432
            env:CommonProgramFiles(x86)
            env:DriverData
            env:CommonProgramFiles
            env:TEMP
            env:TMP
            env:ProgramW6432
            env:windir
            PSScriptRoot

        Does accepts $null or an empty string.

        .PARAMETER AllowSemicolonInValues
        Specify this parameter to allow the use of the semicolon in variable values.  When set to false and a
        semicolon is found in a variable's value that is being expanded, this function will throw an error.

        .PARAMETER ToRawJson
        Formats the values expand by this function to include escapte characters needed for raw JSON data.

        .EXAMPLE
        Expand-VariablesInString -String "$ProgramData\Microsoft"

        .EXAMPLE
        Expand-VariablesInString -String "$PSScriptRoot\file.txt" -PSScriptRootDirectory "C:\Temp"

        .EXAMPLE
        Expand-VariablesInString -String "$ProgramData\Microsoft" -ToRawJson

        .EXAMPLE
        Expand-VariablesInString -String "$ProgramData\Microsoft" -VariableNames @('env:ProgramData')

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
        [Parameter(ValueFromPipeline, Mandatory, Position=0)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]
        $String,

        [Parameter()]
        [string[]]
        $VariableNames = @(
            'env:ProgramData'
            'env:ProgramFiles'
            'env:SystemDrive'
            'env:ProgramFiles(x86)'
            'env:CommonProgramW6432'
            'env:CommonProgramFiles(x86)'
            'env:DriverData'
            'env:CommonProgramFiles'
            'env:TEMP'
            'env:TMP'
            'env:ProgramW6432'
            'env:windir'
            'PSScriptRoot'
        ),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$PSScriptRootDirectory,

        [Parameter()]
        [switch]$ToRawJson,

        [Parameter()]
        [switch]$AllowSemicolonInValues
    )

    begin {
        $jsonEscChars = @{
            "\"     = '\\'
            "`b"    = '\b'
            "`f"    = '\f'
            "`n"    = '\n'
            "`r"    = '\r'
            "`t"    = '\t'
            '"'     = '\"'
        }

        if(($null -eq $VariableNames) -or ('' -eq $VariableNames)) {
            Write-Verbose "Expand-VariablesInString: VariableNames is null or empty"
            return
        }

        $variables = @{}
        foreach($variable in $VariableNames) {
            if($null -eq $variable -or '' -eq $variable) {
                Write-Error 'Expand-VariablesInString: null or empty variable name.'
            }
            if($variable -like 'env:*') {
                $variables[$variable] = [Environment]::GetEnvironmentVariable($variable.Replace('env:',''))
            }
            elseif($variable.IndexOf(':') -ne -1) {
                Write-Error 'Expand-VariablesInString: scope modifiers and namespaces other than env: are not yet supported.'
            }
            elseif(-not (Test-VariableName -Name $variable)) {
                Write-Error 'Expand-VariablesInString: variable names (other than env:*) that require ${} are not yet supported.'
            }
            elseif(-not (Test-Path -Path "Variable:\$variable")) {
                Write-Verbose "Expand-VariablesInString: variable not found"
                $variables[$variable] = $null
            }
            elseif($variable -eq 'PSScriptRoot') {
                if($PSBoundParameters.ContainsKey('PSScriptRootDirectory')) {
                    Write-Verbose "Expand-VariablesInString: Using PSScriptRootDirectory $PSScriptRootDirectory"
                    $variables['PSScriptRoot'] = $PSScriptRootDirectory
                } else {
                    Write-Warning "Expand-VariablesInString: PSScriptRootDirectory is not specified"
                    $variables['PSScriptRoot'] = $null
                }
            }
            else {
                $variables[$variable] = Get-Variable -Name $variable -ValueOnly
            }
        }

        $formatedVariables = @{}
        foreach($variable in $($variables.Keys)){
            if(($null -eq $variables[$variable]) -or ('' -eq $variables[$variable])) {
                continue
            }
            $value = $variables[$variable]
            if($ToRawJson) {
                foreach($escChar in $jsonEscChars.GetEnumerator()) {
                    $value = $value.Replace($escChar.Name, $escChar.Value)
                }
            }
            $formatedVariables["`${$variable}"] = $value
            $variableNameDoesntRequireBraces = Test-VariableName -Name $variable
            if($variableNameDoesntRequireBraces) {
                $formatedVariables["`$(`$$variable)"] = $value
                $formatedVariables["`$$variable"] = $value
            }
        }

        $sortedVariables = $formatedVariables.GetEnumerator() | Sort-Object {$_.Name.Length} -Descending
    }

    process {
        foreach($singleString in $String) {
            if(($null -eq $VariableNames) -or ('' -eq $VariableNames)) {
                Write-Verbose "Expand-VariablesInString: VariableNames is null or empty"
                $singleString
                return
            }
            if(($null -eq $singleString) -or ('' -eq $singleString)) {
                Write-Verbose "Expand-VariablesInString: string is null or empty."
                $singleString
                return
            }
            if($singleString.IndexOf("$") -eq -1) {
                Write-Verbose "Expand-VariablesInString: string does not contain `$."
                $singleString
                return
            }
            foreach($variable in $sortedVariables) {
                if($singleString.IndexOf($variable.Name) -ne -1) {
                    Write-Verbose "Expand-VariablesInString: found $($variable.Name), replacing with $($variable.Value)"
                    if($variable.Value.IndexOf(';') -ne -1) {
                        Write-Error ("Expand-VariablesInString: $($variable.Name) contains a semicolon" +
                                        " and AllowSemicolonInValues is not true.  Value of $($variable.Name): $($variable.Value)")
                        return
                    }
                    else {
                        $singleString = $singleString.Replace($variable.Name, $variable.Value)
                    }
                }
            }
            $singleString
        }
    }

    end {

    }
}
