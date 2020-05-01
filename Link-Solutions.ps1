param ([string] $configFilePath)

Import-Module .\Config\BaseConfig.ps1 -Force
Import-Module $configFilePath -Force
Import-Module .\Helper\Functions.ps1 -Force

# if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
# {
#     Write-Warning "You do not have Administrator rights to run this script! Please re-run this script as an Administrator!"
#     break
# }

foreach ($syncProfile in $config.syncProfiles) {
	$sourcePath = Join-Path -Path $config.sourceSolutionPath -ChildPath $syncProfile.sourceChildPath
	$linkPath = Join-Path -Path $config.linkSolutionPath -ChildPath $syncProfile.linkChildPath
	$noFilter = [string]::IsNullOrEmpty($syncProfile.filter)
	
	if (!(Test-SourcePath $sourcePath) -or !(Test-LinkPath $linkPath)) {
		continue
	}
	
	$linkProfiles = @{
		'\' = New-Profile (Get-Item $sourcePath) '\'
	}

	$sourceFiles = Get-ChildItem $sourcePath
	$sourceRegexPath = $sourcePath -replace '\\', '\\'
	
	$linkFiles = Get-ChildItem $linkPath
	$linkRegexPath = $linkPath -replace '\\', '\\'
	
	Add-LinkProfiles $sourceFiles $linkProfiles $syncProfile.sourceChildPath $sourceRegexPath $noFilter $syncProfile.filter
	Add-LinkProfiles $linkFiles $linkProfiles $syncProfile.linkChildPath $linkRegexPath $noFilter $syncProfile.filter $true
	$lists = @{ }

	Show-Summary $linkProfiles $lists $sourcePath $linkPath $config.showSummary
	
	if (!$config.confirmBeforeLink -or (Read-Bool("Do you want to finish the operation?"))) {
		New-Links $lists $sourcePath $linkPath
		if($config.confirmResults) {
			Read-Host -Prompt "Press a key to continue"
		}
	}
}