function Get-BloatwareWin32Instructions {
    [OutputType([hashtable[]])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $CustomDirectory,

        [Parameter()]
        [string[]]
        $InstructionVariableNames
    )

    if ($PSBoundParameters.ContainsKey('CustomDirectory')) {
        [string[]]$directories = $CustomDirectory
    }
    else {
        [string[]]$directories = @()
    }
    $directories += @("$PSScriptRoot\..\Win32Instructions")

    $foundDirectory = ''
    $foundName = ''
    ForEach($directory in $directories) {
        if(Test-Path -Path  "$directory\$Name.json") {
            Write-Verbose "Get-BloatwareWin32Instructions: found instructions for $Name at $directory\$Name.json"
            $foundDirectory = $directory
            $foundName = "$Name.json"
            break
        }
    }

    $defaultSuccessExitCodes = @(0, 1707, 3010, 1641)
    if('' -eq $foundName) {
        Write-Verbose "Get-BloatwareWin32Instructions: instructions file for $Name not found.  Using defaults."
        $instructions = @{
            'Name'                  = $Name
            'RequiresDevelopment'   = $true
            'SuccessExitCodes'      = $defaultSuccessExitCodes
        }
    }
    else {
        Write-Verbose "Get-BloatwareWin32Instructions: reading instructions file."

        $expandVariablesParams = @{
            'PSScriptRootDirectory' = $foundDirectory
            'ToRawJson'             = $true
        }
        if($PSBoundParameters.ContainsKey('InstructionVariableNames')) {
            $expandVariablesParams['VariableNames'] = $InstructionVariableNames
        }

        $content = (Get-Content -Path "$foundDirectory\$foundName" -Raw |
                    Expand-VariablesInString @expandVariablesParams)

        $instructions = ($content | ConvertFrom-Json | ConvertTo-HashTable -Verbose:$false)

        if(-not $instructions.ContainsKey('SuccessExitCodes')) {
            Write-Verbose ("Get-BloatwareWin32Instructions: " +
                            "SucessExitCodes not contained in instructions file.  Using defaults")
            $instructions['SuccessExitCodes'] = @(0, 1707, 3010, 1641)
        }
    }

    $instructions
}
