<#
	.NOTES
	===========================================================================
	 Created on:   	2021/07/16
     Modified on:   2021/07/18
	 Created by:   	Sean Sauve
	 Organization: 	TSA-SAUSS
     Version:       1.1.4
	===========================================================================
	.DESCRIPTION
		Uninstalls undesirable applications that are pre-installed
#>

$PrivatePS1Files = Get-ChildItem -Name "$PSScriptRoot\Private\*.ps1"
foreach ($PS1File in $PrivatePS1Files) {
    . $PSScriptRoot\Private\$($PS1File.split(".")[0])
}

$PublicPS1Files = Get-ChildItem -Name "$PSScriptRoot\Public\*.ps1"
foreach ($PS1File in $PublicPS1Files) {
    . $PSScriptRoot\Public\$($PS1File.split(".")[0])
}

Export-ModuleMember -Function * -Alias * -Cmdlet *
