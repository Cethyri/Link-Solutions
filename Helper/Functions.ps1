
using namespace System.Management.Automation

function global:Test-SourcePath([string] $sourcePath) {
	if (!(Test-Path $sourcePath)) {
		Write-Warning "The source `"$($sourcePath)`" was not found. Skipping.`n"
		return $false
	}
	elseif (!((Get-Item $sourcePath) -is [System.IO.DirectoryInfo])) {
		Write-Warning "The source `"$($sourcePath)`" is not a directory. Skipping.`n"
		return $false
	}

	return $true
}

function global:Test-LinkPath([string] $linkPath) {
	if (!(Test-Path $linkPath)) {
		New-Item -ItemType SymbolicLink -Path $linkPath -Target $sourcePath
		Write-ColorInfo "Symbolic link created at `"$($linkItemPath)`", linked to `"$($targetPath)`"." "Blue" "Continue"
		return $false
	}
	# else {
	# 	Write-Warning "`"$($linkPath)`" already exists, attempting to resolve before creating links.`n"
	# }

	return $true
}

function global:New-Profile ([System.IO.FileSystemInfo] $file, [string] $relPath) {
	return @{
		file    = $file
		relPath = $relPath
		action  = [LinkAction]::link
	}
}

function global:Get-ShouldInclude ([System.IO.FileSystemInfo] $file, [bool] $isDirectory, [hashtable] $syncProfile, [LinkAction] $dirAction) {
	$filter = !$syncProfile.doFilter -or $file.Name -like $syncProfile.filter
	$action = ($dirAction -ne [LinkAction]::exclude) -and ($dirAction -ne [LinkAction]::avoid)
	return ($isDirectory -or $filter) -and $action
}

enum LinkAction {
	include
	exclude
	avoid
	link
	none
}

function global:Read-Bool ([string] $message) {
	$input = ""

	while ($input -ne 'y' -and $input -ne 'n') {
		Write-ColorInfo ($message + " yes (y) or no (n)") "Blue" "Continue"
		$input = Read-Host
	}

	return $input -eq 'y'
}

function global:Read-LinkAction ([string] $fileName, [bool] $isDirectory) {
	$input = ""
	$infoType = if ($isDirectory) { 'folder and its contents' } else { 'file' }

	$message = "`"$($fileName)`" is not in the source files. What would you like to do?`nInclude (i) and copy the $($infoType) to the source directory.`nExclude (e) and delete the $($infoType).`nAvoid   (a) linking this $($infoType) by modifying the link targets."
	while ($input -ne "i" -and $input -ne "e" -and $input -ne "a") {
		Write-ColorInfo $message "Blue" "Continue"
		$input = Read-Host
	}

	switch ($input) {
		'i' { return [LinkAction]::include }
		'e' { return [LinkAction]::exclude }
		'a' { return [LinkAction]::avoid }
	}
	return $input -eq $trueVal
}

function global:Add-LinkProfiles ([System.IO.FileSystemInfo[]] $files, [hashtable] $linkProfiles, [string] $childPath, [string] $regexPath, [hashtable] $syncProfile, [bool] $inLinkDirectory = $false) {
	for ($i = 0; $i -lt $files.Length; ++$i) {
		$file = $files[$i]
		$isDirectory = ($file -is [System.IO.DirectoryInfo])
		
		$relPath = $file.FullName -replace $regexPath, ''
		$relDirPath = (Split-Path $relPath)
		
		$include = Get-ShouldInclude $file $isDirectory $syncProfile $linkProfiles[$relDirPath].action
		
		if ($include) {
			$avoid = $syncProfile.doAvoid -and $file.name -like $syncProfile.avoid
			if ($avoid) {
				$include = $false
			}
			if (!$linkProfiles.Contains($relPath)) {
				$linkProfiles[$relPath] = New-Profile $file $relPath
				
				if (!$avoid -and $inLinkDirectory) {
					if ($config.avoidByDefault) {
						$linkProfiles[$relPath].action = [LinkAction]::avoid
					}
					else {
						$linkProfiles[$relPath].action = Read-LinkAction (Join-Path -Path $childPath -ChildPath $relPath) $isDirectory
					}
					$include = $linkProfiles[$relPath].action -eq [LinkAction]::include
				}
			}
			
			if ($include) {
				if ($isDirectory) {
					$files += Get-ChildItem $file.FullName
				}
			}
			else {
				Invoke-Unlink $linkProfiles $relPath
			}
		}
		else {
			Invoke-Unlink $linkProfiles $relPath
		}
	}
}

function global:Invoke-Unlink ([hashtable] $linkProfiles, [string] $relPath) {
	$dirPath = $relPath
	if ($linkProfiles.Contains($relPath)) {
		$linkProfiles[$relPath].action = [LinkAction]::avoid
	}
	while ($dirPath -ne '\') {
		$dirPath = (Split-Path $dirPath)
		$linkProfiles[$dirPath].action = [LinkAction]::none
	}
}

function global:Show-Summary([hashtable] $linkProfiles, [hashtable] $lists, [string] $sourcePath, [string] $linkPath, [bool] $showSummary) {
	if ($showSummary) {
		$infoAction = "Continue"
	}
	else {
		$infoAction = "SilentlyContinue"
	}

	$message = "----------Summary----------`nSource: $($sourcePath)`nLink: $($linkPath)`n"
	Write-ColorInfo $message "Green" $infoAction
	
	$lists.link = @()
	$lists.include = @()
	$lists.exclude = @()
	$lists.avoid = @()
	
	Write-ColorInfo 'Linking:' "White" $infoAction
	foreach ($profile in $linkProfiles.Values) {
		$isTopLink = ($profile.relPath -eq '\') -or $linkProfiles[(Split-Path $profile.relPath)].action -eq [LinkAction]::none
		$shouldLink = ($profile.action -eq [LinkAction]::link -or $profile.action -eq [LinkAction]::include)
		if ($shouldLink -and $isTopLink) {
			$lists.link += $profile
			Write-ColorInfo ("    " + $profile.relPath) "Blue" $infoAction
		}
	}
	if (!$config.avoidByDefault) {
		Write-ColorInfo 'Including:' "White" $infoAction
		foreach ($profile in $linkProfiles.Values) {
			if ($profile.action -eq [LinkAction]::include) {
				$lists.include += $profile
				Write-ColorInfo ("    " + $profile.relPath) "Green" $infoAction
			}
		}
		Write-ColorInfo 'Excluding:' "White" $infoAction
		foreach ($profile in $linkProfiles.Values) {
			if ($profile.action -eq [LinkAction]::exclude) {
				$lists.exclude += $profile
				Write-ColorInfo ("    " + $profile.relPath) "Red" $infoAction
			}
		}
	}

	Write-ColorInfo 'Avoiding:' "White" $infoAction
	foreach ($profile in $linkProfiles.Values) {
		if ($profile.action -eq [LinkAction]::avoid) {
			$lists.avoid += $profile
			Write-ColorInfo ("    " + $profile.relPath) "Yellow" $infoAction
		}
	}

	Write-Information "`n" -InformationAction $infoAction
}


function global:New-Links([hashtable] $lists, [string] $sourcePath, [string] $linkPath) {
	foreach ($profile in $lists.include) {
		$copyTargetPath = Join-Path -Path $sourcePath -ChildPath $profile.relPath
		$copyTargetDirPath = Split-Path $copyTargetPath
		if (!(Test-Path $copyTargetDirPath)) {
			New-Item -Path (Split-Path $copyTargetDirPath) -Name (Split-Path $copyTargetDirPath -Leaf) -ItemType "directory" | Out-Null
		}
		$copyPath = $profile.file.FullName
		Copy-Item -Path $copyPath -Destination $copyTargetPath
		Write-ColorInfo "`"$($copyPath)`" copied to `"$($copyTargetPath)`"." "Green" "Continue"

	}
	foreach ($profile in $lists.link) {
		$linkItemPath = (Join-Path -Path $linkPath -ChildPath $profile.relPath)
		$targetPath = (Join-Path -Path $sourcePath -ChildPath $profile.relPath)

		if ((Test-Path $linkItemPath)) {
			if ((Get-Item $linkItemPath).LinkType -ne "SymbolicLink") {
				Remove-Item $linkItemPath -Recurse -Force

				New-Item -ItemType SymbolicLink -Path $linkItemPath -Target $targetPath | Out-Null
				
				Write-ColorInfo "Symbolic link created at `"$($linkItemPath)`", linked to `"$($targetPath)`"." "Blue" "Continue"
			}
			else {
				Write-ColorInfo "`"$($linkItemPath)`" is already a symlink. Skipping." "Yellow" "Continue"
			}
		}
		else {
			New-Item -ItemType SymbolicLink -Path $linkItemPath -Target $targetPath | Out-Null
		}
	}
}

function global:Write-ColorInfo([string] $message, [ConsoleColor] $color, [string] $infoAction) {
	$writeInfo = [HostInformationMessage]@{
		Message         = $message
		ForegroundColor = $color
	}
	Write-Information $writeInfo -InformationAction $infoAction
}