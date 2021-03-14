# Link-Solutions

## Summary

This project is intended to solve the problem of working on multiple files across multiple solutions. Specifically it was built for ~~REDACTED~~, but it can be expanded via config. The script uses <u>symbolic links</u> to ensure shared content is synced across every project. You could use this for working on webpages used as content in other projects, or syncing dlls immediatly after you build a dependancy.

## Running

1. **Link-Solutions.ps1** requires a single argument for the path to the config file you want to use (you may use `-configFilePath` to be verbose). Use the `-whatIf` switch to see what the effect of the command would be without any permanent changes.

2. Depending on how the base configurations are set you may need to select actions for <u>unmatched</u> files or folders (and their contents)
	- <u>Include</u> and copy to the source directory.
	- <u>Exclude</u> and delete.
	- <u>Avoid</u> linking by modifying the link targets.
	- <u>None</u>, avoid linking a folder, but still consider it's contents

3. You can look over the script output to confirm that all appropriate files are linked.

4. Once the script is finished, confirm that your files are syncing across projects. Be sure to make additions to the solution's .gitignore to ignore any symbolic links, you don't need or want to push these up to the repo.

5. When adding files or folders to the source project, if anything is not syncing, run the script again to add <u>symlinks</u> for the new content.

## Configuration

There are two configuration files needed to run the **Link-Solutions.ps1** script.

1. **BaseConfig.ps1** is loaded automatically and  sets the following config values:

	- `[hashtable] $config`  
		The global config variable. Contains:

		- `[bool] avoidByDefault`  
			`$true` automatically uses the <u>avoid</u> action for each <u>unmatched</u> file.  
			`$false` prompts for an action for each <u>unmatched</u> file.

		- `[bool] confirmBeforeLink`  
			`$true` requires confirmation before <u>symlinks</u> are created for each <u>link profile</u>.  
			`$false` creates <u>symlinks</u> without confirmation.

		- `[bool] confirmResults`  
			`$true` pauses to view the output of <u>symlink</u> creation before moving on to the next <u>link profile</u>.  
			`$false` does not pause between the output of each <u>link profile</u>.

		- `[bool] showSummary`  
			`$true` shows the summary of files to be <u>linked</u>, <u>included</u>, <u>excluded</u>, or <u>avoided</u>.  
			`$false` hides the summary.

2. An additional config file is required for any two solutions you want to link. For example linking A to B and linking A to C requires two separate config files. This file must set the following variables:
	
	- `[string] $config.sourceSolutionPath`  
		The directory path to the source code (dependancy) you want to link. This solution should "own" the files (.aspx, .cs, .dlls, etc.) you are linking.  
		ex: `"Y:\Solutions\My-Original-Solution"`

	- `[string] $config.linkSolutionPath`  
		The directory path to the solution which consumes the files you want linked. This solution should rely on the source solution as a dependancy for the linked .dlls or content.  
		ex: `"Y:\Solutions\My-New-Solution"`

	- `[hashtable] $config.linkProfiles`  
		A list of profiles for every directory or file that needs to be linked. Each profile contains:

		- `[string] sourceChildPath`  
			The path from the **source** solution to the directory or file to be linked.  
			ex: `"bin\core"`

		- `[string] linkChildPath`  
			The path from the **link** solution to the directory or file to be linked.  
			ex: `"MyProject\bin"`

		- `[string] filter`  
			Files must match this filter statement to be linked, files that don't match will be <u>avoided</u>. Can be unset or blank to not use a filter.  
			ex: `"Web.Core.*"`

		- `[string] avoid`  
			Files matching this statement will be <u>avoided</u>. Can be unset or blank to not avoid any files.  
			ex: `"*.token"`

## Visual Example

```
✅ - Link
❌ - No Link

Source                          Link
│                               ❌├───bin                        
│                               ❌├───HealthCheck                
├───Include                     ❌├───Include                    
│    │                          ❌│   ├───Common                    
│   ├───JavaScript              ✅│   ├───JavaScript                
│   └───nuget.ignore            ✅│   └───nuget.ignore            
├───Interface                   ❌├───Interface                    
│   │                           ❌│   ├───Common                    
│   ├───Dashboard               ✅│   ├───Dashboard                
│   ├───Favorites               ✅│   ├───Favorites                
│   ├───Organization            ✅│   ├───Organization            
│   ├───PendingTask             ✅│   ├───PendingTask            
│   ├───ScreenShare             ✅│   ├───ScreenShare            
│   ├───Training                ✅│   ├───Training                
│   ├───UserRegistration        ✅│   ├───UserRegistration        
│   ├───Dashboard.aspx          ✅│   ├───Dashboard.aspx            
│   ├───Dashboard.aspx.cs       ✅│   ├───Dashboard.aspx.cs        
│   ├───GuideMe.aspx            ✅│   ├───GuideMe.aspx            
│   ├───GuideMe.aspx.cs         ✅│   ├───GuideMe.aspx.cs        
│   ├───GuideMe.Config          ✅│   ├───GuideMe.Config            
│   ├───Home.aspx               ✅│   ├───Home.aspx                
│   ├───Home.aspx.cs            ✅│   ├───Home.aspx.cs            
│   └───Home.Config             ✅│   └───Home.Config            
│                               ❌├───Platform                    
├───WebControls                 ❌├───WebControls                
│   │                           ❌│   ├───Common                    
│   ├───Organization            ✅│   ├───Organization            
│   └───UserRegistration        ✅│   └───UserRegistration        
│                               ❌├───default.config                
│                               ❌├───Global.asax                
│                               ❌├───packages.config            
│                               ❌├───web.config                    
│                               ❌└───Global.asax                
```

## Important Notes

If a file is tracked in the link project it should not be linked, this will overwrite any tracked changes. It is in issue if the same file is tracked in multiple solutions, so if this is the case you should bring this up with your team lead for discussion.

## <u>Glossary</u>

- **<u>Symlink</u>** or **<u>Symbolic Link</u>**: a term for any file that contains a reference to another file or directory in the form of an absolute or relative path and that affects pathname resolution.

- **<u>Unmatched</u>**: Refers to a file or folder in the link directory with no corresponding item in the source directory.

- **<u>Link Profile</u>**: A definition for a folder structure or file in both the source and link directory that need to be linked.

- **<u>Action</u>**: Determines how to handle an <u>unmatched</u> item (file or folder and its contents)

	- **<u>Link</u>**: creates a symbolic link between the source and link item.
	- **<u>Include</u>**: copies the item to the source directory and then links the item.
	- **<u>Exclude</u>**: deletes the item.
	- **<u>Avoid</u>**: avoids linking an item, forces its parent directory to not be linked and all sibling items to be linked instead.
	- **<u>None</u>**: only allowed for directories, similar to avoid but the folder's content is still considered for linking.
