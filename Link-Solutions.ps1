param ([string] $configFilePath, [switch] $whatIf)

Import-Module .\Config\BaseConfig.ps1 -Force
Import-Module $configFilePath -Force
Import-Module .\Helper\Functions.ps1 -Force

$global:whatIf = $whatIf

if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") -and !$whatIf)
{
    Write-Warning "You do not have Administrator rights to run this script! Please re-run this script as an Administrator!"
    break
}

foreach ($linkProfile in $config.linkProfiles) {
	$sourcePath = Join-Path -Path $config.sourceSolutionPath -ChildPath $linkProfile.sourceChildPath
	$linkPath = Join-Path -Path $config.linkSolutionPath -ChildPath $linkProfile.linkChildPath
	$linkProfile.doFilter = ![string]::IsNullOrEmpty($linkProfile.filter)
	$linkProfile.doAvoid = ![string]::IsNullOrEmpty($linkProfile.avoid)
	
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
	
	Add-LinkProfiles $sourceFiles $linkProfiles $linkProfile.sourceChildPath $sourceRegexPath $linkProfile
	Add-LinkProfiles $linkFiles $linkProfiles $linkProfile.linkChildPath $linkRegexPath $linkProfile $true
	$lists = @{ }

	Show-Summary $linkProfiles $lists $sourcePath $linkPath $config.showSummary
	
	if (!$config.confirmBeforeLink -or (Read-Bool("Do you want to finish the operation?"))) {
		New-Links $lists $sourcePath $linkPath
		if ($config.confirmResults) {
			Read-Host -Prompt "Press a key to continue"
		}
	}
}