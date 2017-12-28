mkdir download/windows -Force >$null

Set-Location download

if (!(Test-Path "nuget.exe"))
{
	Write-Output "Fetching NuGet."
	# Work around PowerShell's Invoke-WebRequest not being available on some versions of PowerShell by using the BCL.
	# To do that we need to work around further and use absolute paths because DownloadFile is not aware of PowerShell's current directory.
	$target = Join-Path $pwd.ToString() "nuget.exe"
	(New-Object System.Net.WebClient).DownloadFile("http://nuget.org/nuget.exe", $target)
}

if (!(Test-Path "StyleCopPlus.dll"))
{
	Write-Output "Fetching StyleCopPlus from NuGet."
	./nuget.exe install StyleCopPlus.MSBuild -Version 4.7.49.5 -ExcludeVersion -Verbosity quiet
	Copy-Item StyleCopPlus.MSBuild/tools/StyleCopPlus.dll .
	Remove-Item StyleCopPlus.MSBuild -Recurse
}

if (!(Test-Path "StyleCop.dll"))
{
	Write-Output "Fetching StyleCop files from NuGet."
	./nuget.exe install StyleCop.MSBuild -Version 4.7.49.0 -ExcludeVersion -Verbosity quiet
	Copy-Item StyleCop.MSBuild/tools/StyleCop*.dll .
	Remove-Item StyleCop.MSBuild -Recurse
}

if (!(Test-Path "ICSharpCode.SharpZipLib.dll"))
{
	Write-Output "Fetching ICSharpCode.SharpZipLib from NuGet."
	./nuget.exe install SharpZipLib -Version 0.86.0 -ExcludeVersion -Verbosity quiet
	Copy-Item SharpZipLib/lib/20/ICSharpCode.SharpZipLib.dll .
	Remove-Item SharpZipLib -Recurse
}

if (!(Test-Path "MaxMind.Db.dll"))
{
	Write-Output "Fetching MaxMind.Db from NuGet."
	./nuget.exe install MaxMind.Db -Version 2.0.0 -ExcludeVersion -Verbosity quiet
	Copy-Item MaxMind.Db/lib/net45/MaxMind.Db.* .
	Remove-Item MaxMind.Db -Recurse
}

if (!(Test-Path "SharpFont.dll"))
{
	Write-Output "Fetching SharpFont from NuGet."
	./nuget.exe install SharpFont -Version 4.0.1 -ExcludeVersion -Verbosity quiet
	Copy-Item SharpFont/lib/net45/SharpFont* .
	Copy-Item SharpFont/config/SharpFont.dll.config .
	Remove-Item SharpFont -Recurse
	Remove-Item SharpFont.Dependencies -Recurse
}

if (!(Test-Path "nunit.framework.dll"))
{
	Write-Output "Fetching NUnit from NuGet."
	./nuget.exe install NUnit -Version 3.0.1 -ExcludeVersion -Verbosity quiet
	Copy-Item NUnit/lib/net40/nunit.framework* .
	Remove-Item NUnit -Recurse
}

if (!(Test-Path "windows/SDL2.dll"))
{
	Write-Output "Fetching SDL2 from libsdl.org"

	# Download zip:
	$zipFileName = "SDL2-2.0.5-win32-x86.zip"
	$target = Join-Path $pwd.ToString() $zipFileName
	(New-Object System.Net.WebClient).DownloadFile("https://www.libsdl.org/release/" + $zipFileName, $target)

	# Extract zip:
	$shell_app=new-object -com shell.application
	$currentPath = (Get-Location).Path
	$zipFile = $shell_app.namespace($currentPath + "\$zipFileName")
	$destination = $shell_app.namespace($currentPath + "\windows")
	$destination.Copyhere($zipFile.items())

	# Remove junk files:
	Remove-Item SDL2-2.0.5-win32-x86.zip
	Remove-Item -path "$currentPath\windows\README-SDL.txt"
}

if (!(Test-Path "Open.Nat.dll"))
{
	Write-Output "Fetching Open.Nat from NuGet."
	./nuget.exe install Open.Nat -Version 2.1.0 -ExcludeVersion -Verbosity quiet
	Copy-Item Open.Nat/lib/net45/Open.Nat.dll .
	Remove-Item Open.Nat -Recurse
}

if (!(Test-Path "windows/lua51.dll"))
{
	Write-Output "Fetching Lua 5.1 from NuGet."
	./nuget.exe install lua.binaries -Version 5.1.5 -ExcludeVersion -Verbosity quiet
	Copy-Item lua.binaries/bin/win32/dll8/lua5.1.dll ./windows/lua51.dll
	Remove-Item lua.binaries -Recurse
}

if (!(Test-Path "windows/freetype6.dll"))
{
	Write-Output "Fetching FreeType2 from NuGet."
	./nuget.exe install SharpFont.Dependencies -Version 2.6.0 -ExcludeVersion -Verbosity quiet
	Copy-Item SharpFont.Dependencies/bin/msvc9/x86/freetype6.dll ./windows/freetype6.dll
	Remove-Item SharpFont.Dependencies -Recurse
}

if (!(Test-Path "windows/soft_oal.dll"))
{
	Write-Output "Fetching OpenAL Soft from NuGet."
	./nuget.exe install OpenAL-Soft -Version 1.16.0 -ExcludeVersion -Verbosity quiet
	Copy-Item OpenAL-Soft/bin/Win32/soft_oal.dll windows/soft_oal.dll
	Remove-Item OpenAL-Soft -Recurse
}

if (!(Test-Path "FuzzyLogicLibrary.dll"))
{
	Write-Output "Fetching FuzzyLogicLibrary from NuGet."
	./nuget.exe install FuzzyLogicLibrary -Version 1.2.0 -ExcludeVersion -Verbosity quiet
	Copy-Item FuzzyLogicLibrary/bin/Release/FuzzyLogicLibrary.dll .
	Remove-Item FuzzyLogicLibrary -Recurse
}

if (!(Test-Path "SDL2-CS.dll"))
{
	Write-Output "Fetching SDL2-CS from GitHub."
	$target = Join-Path $pwd.ToString() "SDL2-CS.dll"
	(New-Object System.Net.WebClient).DownloadFile("https://github.com/OpenRA/SDL2-CS/releases/download/20161223/SDL2-CS.dll", $target)
}

if (!(Test-Path "OpenAL-CS.dll"))
{
	Write-Output "Fetching OpenAL-CS from GitHub."
	$target = Join-Path $pwd.ToString() "OpenAL-CS.dll"
	(New-Object System.Net.WebClient).DownloadFile("https://github.com/OpenRA/OpenAL-CS/releases/download/20151227/OpenAL-CS.dll", $target)
}

if (!(Test-Path "Eluant.dll"))
{
	Write-Output "Fetching Eluant from GitHub."
	$target = Join-Path $pwd.ToString() "Eluant.dll"
	(New-Object System.Net.WebClient).DownloadFile("https://github.com/OpenRA/Eluant/releases/download/20160124/Eluant.dll", $target)
}

if (!(Test-Path "GeoLite2-Country.mmdb.gz") -Or (((get-date) - (get-item "GeoLite2-Country.mmdb.gz").LastWriteTime) -gt (new-timespan -days 30)))
{
	Write-Output "Updating GeoIP country database from MaxMind."
	$target = Join-Path $pwd.ToString() "GeoLite2-Country.mmdb.gz"
	(New-Object System.Net.WebClient).DownloadFile("http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.mmdb.gz", $target)
}

if (!(Test-Path "rix0rrr.BeaconLib.dll"))
{
	Write-Output "Fetching rix0rrr.BeaconLib from NuGet."
	./nuget.exe install rix0rrr.BeaconLib -Version 1.0.1 -ExcludeVersion -Verbosity quiet
	Copy-Item rix0rrr.BeaconLib/lib/net40/rix0rrr.BeaconLib.dll .
	Remove-Item rix0rrr.BeaconLib -Recurse
}

Set-Location ..
