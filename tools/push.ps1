#Requires -Version 5.1
<#
.SYNOPSIS
  Build and push the SPCS image to a Snowflake image repository.
.DESCRIPTION
  Auto-detects Podman or Docker, then builds, tags, and pushes the
  agent-multicontext container image. Sources .env.local for credentials
  if present, otherwise prompts interactively.
#>
[CmdletBinding()]
param(
    [string]$ImageTag = 'latest'
)

$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir
$ImageName   = 'agent-multicontext'

# Source .env.local if it exists (key=value lines, supports op read)
$EnvFile = Join-Path $ProjectRoot '.env.local'
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#')) {
            $line = $line -replace '^export\s+', ''
            if ($line -match '^([^=]+)=(.*)$') {
                $key = $Matches[1].Trim()
                $val = $Matches[2].Trim().Trim('"').Trim("'")
                if ($val -match '^\$\((.+)\)$') {
                    $val = Invoke-Expression $Matches[1]
                }
                Set-Item -Path "Env:$key" -Value $val
            }
        }
    }
}

# Auto-detect container runtime
$Runtime = $null
if (Get-Command podman -ErrorAction SilentlyContinue) {
    $Runtime = 'podman'
} elseif (Get-Command docker -ErrorAction SilentlyContinue) {
    $Runtime = 'docker'
} else {
    Write-Error @"
No container runtime found.

Install one of:
  Windows: winget install RedHat.Podman
  macOS:   brew install podman
  Linux:   sudo apt install podman (or dnf install podman)

Docker also works but requires a commercial license for business use.
"@
}

Write-Host "Using container runtime: $Runtime"

# Prompt for repo URL if not set
if (-not $env:SNOWFLAKE_IMAGE_REPO_URL) {
    Write-Host ''
    Write-Host 'Copy the image_repo_url from the last result of deploy_all.sql.'
    Write-Host 'It looks like: <orgname>-<acctname>.registry.snowflakecomputing.com/snowflake_example/agent_multicontext/images'
    Write-Host ''
    $env:SNOWFLAKE_IMAGE_REPO_URL = Read-Host 'Snowflake image repository URL'
}

# Normalize: strip trailing slashes and common copy-paste extras
# (catches pasting the full image path instead of just the repo URL)
$env:SNOWFLAKE_IMAGE_REPO_URL = $env:SNOWFLAKE_IMAGE_REPO_URL.TrimEnd('/')
$env:SNOWFLAKE_IMAGE_REPO_URL = $env:SNOWFLAKE_IMAGE_REPO_URL -replace "/$ImageName/images$", ''
$env:SNOWFLAKE_IMAGE_REPO_URL = $env:SNOWFLAKE_IMAGE_REPO_URL -replace "/$ImageName$", ''

$RegistryHost = ($env:SNOWFLAKE_IMAGE_REPO_URL -split '/')[0]

# Prompt for username if not set
if (-not $env:SNOWFLAKE_USERNAME) {
    Write-Host ''
    $env:SNOWFLAKE_USERNAME = Read-Host 'Snowflake username'
}

# Prompt for PAT if not set
if (-not $env:SNOWFLAKE_REGISTRY_PAT) {
    Write-Host ''
    Write-Host 'Generate a PAT in Snowsight: User menu > Programmatic Access Tokens'
    Write-Host ''
    $secPat = Read-Host 'Snowflake PAT' -AsSecureString
    $env:SNOWFLAKE_REGISTRY_PAT = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPat)
    )
}

$FullImageTag = "$($env:SNOWFLAKE_IMAGE_REPO_URL)/$($ImageName):$($ImageTag)"

Write-Host ''
Write-Host 'Building image...'
& $Runtime build -t "${ImageName}:${ImageTag}" $ProjectRoot
if ($LASTEXITCODE -ne 0) { throw "Build failed" }

Write-Host "Tagging as $FullImageTag..."
& $Runtime tag "${ImageName}:${ImageTag}" $FullImageTag
if ($LASTEXITCODE -ne 0) { throw "Tag failed" }

Write-Host "Authenticating to $RegistryHost..."
$env:SNOWFLAKE_REGISTRY_PAT | & $Runtime login $RegistryHost `
    --username $env:SNOWFLAKE_USERNAME `
    --password-stdin
if ($LASTEXITCODE -ne 0) { throw "Login failed" }

Write-Host 'Pushing image...'
& $Runtime push $FullImageTag
if ($LASTEXITCODE -ne 0) { throw "Push failed" }

Write-Host ''
Write-Host "Done. Image pushed to: $FullImageTag"
Write-Host 'You can now run deploy_spcs.sql in Snowsight.'
