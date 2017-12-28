####### The starting point for the script is the bottom #######

###############################################################
########################## FUNCTIONS ##########################
###############################################################
function Invoke-All-Command
{
	Dependencies-Command
	$msBuild = FindMSBuild
	$msBuildArguments = "/t:Rebuild /nr:false"
	if ($msBuild -eq $null)
	{
		Write-Output "Unable to locate an appropriate version of MSBuild."
	}
	else
	{
		$proc = Start-Process $msBuild $msBuildArguments -NoNewWindow -PassThru -Wait
		if ($proc.ExitCode -ne 0)
		{
			Write-Output "Build failed. If just the development tools failed to build, try installing Visual Studio. You may also still be able to run the game."
		}
		else
		{
			Write-Output "Build succeeded."
		}
	}
}

function Invoke-Clean-Command
{
	$msBuild = FindMSBuild
	$msBuildArguments = "/t:Clean /nr:false"
	if ($msBuild -eq $null)
	{
		Write-Output "Unable to locate an appropriate version of MSBuild."
	}
	else
	{
		$proc = Start-Process $msBuild $msBuildArguments -NoNewWindow -PassThru -Wait
		Remove-Item *.dll
		Remove-Item *.dll.config
		Remove-Item mods/*/*.dll
		Remove-Item *.pdb
		Remove-Item mods/*/*.pdb
		Remove-Item *.exe
		Remove-Item ./*/bin -r
		Remove-Item ./*/obj -r
		if (Test-Path thirdparty/download/)
		{
			Remove-Item thirdparty/download -Recurse -Force
		}
		Write-Output "Clean complete."
	}
}

function Invoke-Version-Command
{
	if ($command.Length -gt 1)
	{
		$version = $command[1]
	}
	elseif (Get-Command 'git' -ErrorAction SilentlyContinue)
	{
		$gitRepo = git rev-parse --is-inside-work-tree
		if ($gitRepo)
		{
			$version = git name-rev --name-only --tags --no-undefined HEAD 2>$null
			if ($version -eq $null)
			{
				$version = "git-" + (git rev-parse --short HEAD)
			}
		}
		else
		{
			Write-Output "Not a git repository. The version will remain unchanged."
		}
	}
	else
	{
		Write-Output "Unable to locate Git. The version will remain unchanged."
	}

	if ($version -ne $null)
	{
		$version | out-file ".\VERSION"
		$mods = @("mods/ra/mod.yaml", "mods/cnc/mod.yaml", "mods/d2k/mod.yaml", "mods/ts/mod.yaml", "mods/modcontent/mod.yaml", "mods/all/mod.yaml")
		foreach ($mod in $mods)
		{
			$replacement = (Get-Content $mod) -Replace "Version:.*", ("Version: {0}" -f $version)
			Set-Content $mod $replacement

			$prefix = $(Get-Content $mod) | Where-Object { $_.ToString().EndsWith(": User") }
			if ($prefix -and $prefix.LastIndexOf("/") -ne -1)
			{
				$prefix = $prefix.Substring(0, $prefix.LastIndexOf("/"))
			}
			$replacement = (Get-Content $mod) -Replace ".*: User", ("{0}/{1}: User" -f $prefix, $version)
			Set-Content $mod $replacement
		}
		Write-Output ("Version strings set to '{0}'." -f $version)
	}
}

function Invoke-Dependencies-Command
{
	Set-Location thirdparty
	./fetch-thirdparty-deps.ps1
	Copy-Item download/*.dll ..
	Copy-Item download/GeoLite2-Country.mmdb.gz ..
	Copy-Item download/windows/*.dll ..
	Set-Location ..
	Write-Output "Dependencies copied."
}

function Test-Command
{
	if (Test-Path OpenRA.Utility.exe)
	{
		Write-Output "Testing mods..."
		Write-Output "Testing Tiberian Sun mod MiniYAML..."
		./OpenRA.Utility.exe ts --check-yaml
		Write-Output "Testing Dune 2000 mod MiniYAML..."
		./OpenRA.Utility.exe d2k --check-yaml
		Write-Output "Testing Tiberian Dawn mod MiniYAML..."
		./OpenRA.Utility.exe cnc --check-yaml
		Write-Output "Testing Red Alert mod MiniYAML..."
		./OpenRA.Utility.exe ra --check-yaml
	}
	else
	{
		UtilityNotFound
	}
}

function Invoke-Check-Command {
	if (Test-Path OpenRA.Utility.exe)
	{
		Write-Output "Checking for explicit interface violations..."
		./OpenRA.Utility.exe all --check-explicit-interfaces
	}
	else
	{
		UtilityNotFound
	}

	if (Test-Path OpenRA.StyleCheck.exe)
	{
		Write-Output "Checking for code style violations in OpenRA.Platforms.Default..."
		./OpenRA.StyleCheck.exe OpenRA.Platforms.Default
		Write-Output "Checking for code style violations in OpenRA.Game..."
		./OpenRA.StyleCheck.exe OpenRA.Game
		Write-Output "Checking for code style violations in OpenRA.Mods.Common..."
		./OpenRA.StyleCheck.exe OpenRA.Mods.Common
		Write-Output "Checking for code style violations in OpenRA.Mods.Cnc..."
		./OpenRA.StyleCheck.exe OpenRA.Mods.Cnc
		Write-Output "Checking for code style violations in OpenRA.Mods.D2k..."
		./OpenRA.StyleCheck.exe OpenRA.Mods.D2k
		Write-Output "Checking for code style violations in OpenRA.Utility..."
		./OpenRA.StyleCheck.exe OpenRA.Utility
		Write-Output "Checking for code style violations in OpenRA.Test..."
		./OpenRA.StyleCheck.exe OpenRA.Test
	}
	else
	{
		Write-Output "OpenRA.StyleCheck.exe could not be found. Build the project first using the `"all`" command."
	}
}

function Invoke-Check-Scripts-Command
{
	if ((Get-Command "luac.exe" -ErrorAction SilentlyContinue) -ne $null)
	{
		Write-Output "Testing Lua scripts..."
		foreach ($script in Get-ChildItem "mods/*/maps/*/*.lua")
		{
			luac -p $script
		}
		foreach ($script in Get-ChildItem "lua/*.lua")
		{
			luac -p $script
		}
		Write-Output "Check completed!"
	}
	else
	{
		Write-Output "luac.exe could not be found. Please install Lua."
	}
}

function Invoke-Docs-Command
{
	if (Test-Path OpenRA.Utility.exe)
	{
		./make.ps1 version
		./OpenRA.Utility.exe all --docs | Out-File -Encoding "UTF8" DOCUMENTATION.md
		./OpenRA.Utility.exe all --weapon-docs | Out-File -Encoding "UTF8" WEAPONS.md
		./OpenRA.Utility.exe all --lua-docs | Out-File -Encoding "UTF8" Lua-API.md
		./OpenRA.Utility.exe all --settings-docs | Out-File -Encoding "UTF8" Settings.md
	}
	else
	{
		UtilityNotFound
	}
}

function FindMSBuild
{
	$key = "HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\4.0"
	$property = Get-ItemProperty $key -ErrorAction SilentlyContinue
	if ($property -eq $null -or $property.MSBuildToolsPath -eq $null)
	{
		return $null
	}

	$path = Join-Path $property.MSBuildToolsPath -ChildPath "MSBuild.exe"
	if (Test-Path $path)
	{
		return $path
	}

	return $null
}

function UtilityNotFound
{
	Write-Output "OpenRA.Utility.exe could not be found. Build the project first using the `"all`" command."
}
###############################################################
############################ Main #############################
###############################################################
if ($args.Length -eq 0)
{
	Write-Output "Command list:"
	Write-Output ""
	Write-Output "  all             Builds the game and its development tools."
	Write-Output "  dependencies    Copies the game's dependencies into the main game folder."
	Write-Output "  version         Sets the version strings for the default mods to the latest"
	Write-Output "                  version for the current Git branch."
	Write-Output "  clean           Removes all built and copied files. Use the 'all' and"
	Write-Output "                  'dependencies' commands to restore removed files."
	Write-Output "  test            Tests the default mods for errors."
	Write-Output "  check           Checks .cs files for StyleCop violations."
	Write-Output "  check-scripts   Checks .lua files for syntax errors."
	Write-Output "  docs            Generates the trait and Lua API documentation."
	Write-Output ""
	$command = (Read-Host "Enter command").Split(' ', 2)
}
else
{
	$command = $args
}

$execute = $command
if ($command.Length -gt 1)
{
	$execute = $command[0]
}

switch ($execute)
{
	"all" { All-Command }
	"dependencies" { Dependencies-Command }
	"version" { Version-Command }
	"clean" { Clean-Command }
	"test" { Test-Command }
	"check" { Check-Command }
	"check-scripts" { Check-Scripts-Command }
	"docs" { Docs-Command }
	Default { Write-Output ("Invalid command '{0}'" -f $command) }
}

#In case the script was called without any parameters we keep the window open
if ($args.Length -eq 0)
{
	Write-Output "Press enter to continue."
	while ($true)
	{
		if ([System.Console]::KeyAvailable)
		{
			break
		}
		Start-Sleep -Milliseconds 50
	}
}
