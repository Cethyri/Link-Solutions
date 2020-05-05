
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
		if (!$whatIf) {
			New-Item -ItemType SymbolicLink -Path $linkPath -Target $sourcePath
		}
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
		file      = $file
		relPath   = $relPath
		action    = [LinkAction]::link
		fileCount = 0
	}
}

function global:Get-ShouldInclude ([System.IO.FileSystemInfo] $file, [bool] $isDirectory, [hashtable] $linkProfile, [LinkAction] $dirAction) {
	$filter = !$linkProfile.doFilter -or $file.Name -like $linkProfile.filter
	$action = ($dirAction -ne [LinkAction]::exclude) -and ($dirAction -ne [LinkAction]::avoid)
	return ($isDirectory -or $filter) -and $action
}

# Input

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
	$result = $null

	while ($null -eq $result) {
		Write-ColorInfo "`"$($fileName)`" is not in the source files. What would you like to do?" "Blue" "Continue"
		Write-ColorInfo "(i) Include and copy the $($infoType) to the source directory." "Blue" "Continue"
		Write-ColorInfo "(e) Exclude and delete the $($infoType)." "Blue" "Continue"
		Write-ColorInfo "(a) Avoid linking this $($infoType) by modifying the link targets." "Blue" "Continue"
		if ($isDirectory) {
			Write-ColorInfo "(n) Avoid linking this folder, but still consider it's contents" "Blue" "Continue"
		}
		$input = Read-Host
		switch ($input) {
			'i' { $result = [LinkAction]::include }
			'e' { $result = [LinkAction]::exclude }
			'a' { $result = [LinkAction]::avoid }
			'n' { $result = if ($isDirectory) { [LinkAction]::none } else { $null } }
			default { $result = $null }
		}
	}
	return $result
}

function global:Add-LinkProfiles ([System.IO.FileSystemInfo[]] $files, [hashtable] $linkProfiles, [string] $childPath, [string] $regexPath, [hashtable] $linkProfile, [bool] $inLinkDirectory = $false) {
	for ($i = 0; $i -lt $files.Length; ++$i) {
		$file = $files[$i]
		$isDirectory = $file -is [System.IO.DirectoryInfo]
		
		$relPath = $file.FullName -replace $regexPath, ''
		$relDirPath = Split-Path $relPath
		
		$include = Get-ShouldInclude $file $isDirectory $linkProfile $linkProfiles[$relDirPath].action
		
		# initial check if this file/filder can be included
		if ($include) {
			$avoid = $linkProfile.doAvoid -and $file.name -like $linkProfile.avoid

			# initial check if this file/filder can be included
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

						if ($linkProfiles[$relPath].action -eq [LinkAction]::none) {
							$files += Get-ChildItem $file.FullName
						}
					}
					$include = $linkProfiles[$relPath].action -eq [LinkAction]::include
				}
			}
			
			if ($include) {
				if ($isDirectory) {
					$files += Get-ChildItem $file.FullName
				}
				$linkProfiles[$relDirPath].fileCount++
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
		$dirPath = Split-Path $dirPath
		$linkProfiles[$dirPath].action = [LinkAction]::none
	}
}

function global:Get-ActionLists([hashtable] $linkProfiles) {
	$lists = @{
		link    = @()
		include = @()
		exclude = @()
		avoid   = @()
	}
	
	foreach ($profile in $linkProfiles.Values) {
		$relDirPath = Split-Path $profile.relPath

		$isTopLink = ($profile.relPath -eq '\') -or $linkProfiles[$relDirPath].action -eq [LinkAction]::none
		$shouldLink = ($profile.action -eq [LinkAction]::link -or $profile.action -eq [LinkAction]::include)
		if ($shouldLink -and $isTopLink) {
			$lists.link += $profile
		}

		if ($profile.action -eq [LinkAction]::include) {
			$lists.include += $profile
		}

		if ($profile.action -eq [LinkAction]::exclude) {
			$lists.exclude += $profile
		}

		$isTopAvoid = $linkProfiles[$relDirPath].fileCount -gt 0
		$canAvoid = $profile.action -eq [LinkAction]::avoid -or $profile.action -eq [LinkAction]::none
		if ($canAvoid -and $isTopAvoid) {
			$lists.avoid += $profile
			Write-ColorInfo ("    " + $profile.relPath) "Yellow" $infoAction
		}
	}

	$lists.link    = $lists.link    | Sort-Object { $_.relPath }
	$lists.include = $lists.include | Sort-Object { $_.relPath }
	$lists.exclude = $lists.exclude | Sort-Object { $_.relPath }
	$lists.avoid   = $lists.avoid   | Sort-Object { $_.relPath }

	return $lists
}

function global:Show-Summary([hashtable] $lists, [string] $sourcePath, [string] $linkPath) {
	Write-ColorInfo "----------Summary----------" "Green"
	Write-ColorInfo "Source: $($sourcePath)" "Green"
	Write-ColorInfo "Link: $($linkPath)" "Green"
	Write-ColorInfo "`n"

	Show-List $lists.link    'Linking:'   'Blue'
	Show-List $lists.include 'Including:' 'Green'
	Show-List $lists.exclude 'Excluding:' 'Red'
	Show-List $lists.avoid   'Avoiding:'  'Yellow'

	Write-Information "`n" -InformationAction
}

function global:Show-List([hashtable[]] $list, [string] $label, [ConsoleColor] $color) {
	if ($list.Length -gt 0) {
		Write-ColorInfo $label
		foreach ($profile in $lists.avoid) {
			Write-ColorInfo ("    " + $profile.relPath) $color
		}
	}
}

function global:New-Links([hashtable] $lists, [string] $sourcePath, [string] $linkPath) {
	foreach ($profile in $lists.include) {
		$copyTargetPath = Join-Path -Path $sourcePath -ChildPath $profile.relPath
		$copyTargetDirPath = Split-Path $copyTargetPath
		if (!(Test-Path $copyTargetDirPath)) {
			if (!$whatIf) {
				New-Item -Path (Split-Path $copyTargetDirPath) -Name (Split-Path $copyTargetDirPath -Leaf) -ItemType "directory" | Out-Null
			}
		}
		$copyPath = $profile.file.FullName
		if (!$whatIf) {
			Copy-Item -Path $copyPath -Destination $copyTargetPath
		}
		Write-ColorInfo "`"$($copyPath)`" copied to `"$($copyTargetPath)`"." "Green" "Continue"

	}
	foreach ($profile in $lists.link) {
		$linkItemPath = (Join-Path -Path $linkPath -ChildPath $profile.relPath)
		$targetPath = (Join-Path -Path $sourcePath -ChildPath $profile.relPath)

		if ((Test-Path $linkItemPath)) {
			if ((Get-Item $linkItemPath).LinkType -ne "SymbolicLink") {
				
				if (!$whatIf) {
					Remove-Item $linkItemPath -Recurse -Force
					New-Item -ItemType SymbolicLink -Path $linkItemPath -Target $targetPath | Out-Null
				}
				
				Write-ColorInfo "Symbolic link created at `"$($linkItemPath)`", linked to `"$($targetPath)`"." "Blue" "Continue"
			}
			else {
				Write-ColorInfo "`"$($linkItemPath)`" is already a symlink. Skipping." "Yellow" "Continue"
			}
		}
		else {
			if (!$whatIf) {
				New-Item -ItemType SymbolicLink -Path $linkItemPath -Target $targetPath | Out-Null
			}
		}
	}
}

function global:Write-ColorInfo([string] $message, [ConsoleColor] $color = "White", [string] $infoAction = "Continue") {
	$writeInfo = [HostInformationMessage]@{
		Message         = $message
		ForegroundColor = $color
	}
	Write-Information $writeInfo -InformationAction $infoAction
}