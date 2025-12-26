# Release script for HideConsole
# Updates version in hide.c and resource.rc, commits and tags

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Ensure we're in the script's directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Check if git working directory is clean
$gitStatus = git status --porcelain 2>$null
if ($gitStatus) {
    Write-Host "Git working directory is not clean. Please commit changes before releasing." -ForegroundColor Red
    exit 1
}

# Extract current version from hide.c
$hideC = Get-Content "hide.c" -Raw
if ($hideC -match '#define VERSION "(\d+)\.(\d+)\.(\d+)"') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $current = "$major.$minor.$patch"
} else {
    Write-Host "Failed to read current version from hide.c" -ForegroundColor Red
    exit 1
}

Write-Host "Current version: $current" -ForegroundColor Cyan

# Calculate next versions
$versions = @{
    Patch = "$major.$minor.$($patch + 1)"
    Minor = "$major.$($minor + 1).0"
    Major = "$($major + 1).0.0"
}

# Interactive menu
$choices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&Patch", "$($versions.Patch) - bug fixes")
    [System.Management.Automation.Host.ChoiceDescription]::new("Mi&nor", "$($versions.Minor) - new features")
    [System.Management.Automation.Host.ChoiceDescription]::new("&Major", "$($versions.Major) - breaking changes")
    [System.Management.Automation.Host.ChoiceDescription]::new("&Cancel", "Abort release")
)

$choice = $Host.UI.PromptForChoice("Select version bump", "Current: $current", $choices, 0)

switch ($choice) {
    0 { $newVersion = $versions.Patch }
    1 { $newVersion = $versions.Minor }
    2 { $newVersion = $versions.Major }
    3 {
        Write-Host "Release cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`nUpdating to version $newVersion..." -ForegroundColor Green

# Parse new version for resource.rc format
$vParts = $newVersion.Split('.')
$rcVersion = "$($vParts[0]),$($vParts[1]),$($vParts[2]),0"
$rcVersionStr = "$($vParts[0]).$($vParts[1]).$($vParts[2]).0"

# Update hide.c
$hideC = $hideC -replace '#define VERSION "[^"]+"', "#define VERSION `"$newVersion`""
Set-Content "hide.c" $hideC -NoNewline -Encoding UTF8
Write-Host "Updated hide.c"

# Update resource.rc
$resourceRc = Get-Content "resource.rc" -Raw
$resourceRc = $resourceRc -replace 'FILEVERSION\s+[\d,]+', "FILEVERSION     $rcVersion"
$resourceRc = $resourceRc -replace 'PRODUCTVERSION\s+[\d,]+', "PRODUCTVERSION  $rcVersion"
$resourceRc = $resourceRc -replace '"FileVersion",\s*"[^"]+"', "`"FileVersion`", `"$rcVersionStr`""
$resourceRc = $resourceRc -replace '"ProductVersion",\s*"[^"]+"', "`"ProductVersion`", `"$rcVersionStr`""
Set-Content "resource.rc" $resourceRc -NoNewline -Encoding UTF8
Write-Host "Updated resource.rc"

# Git commit and tag
git add hide.c resource.rc
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to stage files" -ForegroundColor Red
    exit 1
}

git commit -m "v$newVersion"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to commit" -ForegroundColor Red
    exit 1
}

git tag "v$newVersion"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create tag" -ForegroundColor Red
    exit 1
}

Write-Host "`nSuccessfully committed and tagged v$newVersion" -ForegroundColor Green
Write-Host "`nTo publish the release, run:" -ForegroundColor Cyan
Write-Host "  git push && git push --tags" -ForegroundColor White
