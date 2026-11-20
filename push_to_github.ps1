param(
    [string]$RepoUrl = "https://github.com/ntz-panupong/POCPTA.git",
    [string]$CommitMessage = "Update POCPTA",
    [string]$Token = "",
    [switch]$AskToken
)

$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Push-WithToken {
    param([string]$TargetUrl, [string]$Pat)
    $cleanPat = $Pat.Trim()
    $authUrl = $TargetUrl -replace '^https://', "https://x-access-token:$cleanPat@"
    & git -c credential.helper= push -u $authUrl main
    if ($LASTEXITCODE -ne 0) {
        throw "git push with token failed with exit code $LASTEXITCODE"
    }
    Invoke-Git branch --set-upstream-to=origin/main main
}

if (-not (Test-Path ".git")) {
    Invoke-Git init
}

Invoke-Git add -A
$changes = & git status --porcelain
if ($changes) {
    Invoke-Git commit -m $CommitMessage
}

$hasOrigin = & git remote | Select-String -Pattern "^origin$" -Quiet
if (-not $hasOrigin) {
    Invoke-Git remote add origin $RepoUrl
} else {
    Invoke-Git remote set-url origin $RepoUrl
}

Invoke-Git branch -M main

if ($AskToken -and [string]::IsNullOrWhiteSpace($Token)) {
    $sec = Read-Host "Enter GitHub Personal Access Token (PAT)" -AsSecureString
    $Token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    )
}

if (-not [string]::IsNullOrWhiteSpace($Token)) {
    Push-WithToken -TargetUrl $RepoUrl -Pat $Token
} else {
    & git push -u origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Git push failed (exit code $LASTEXITCODE)."
        $sec = Read-Host "Enter GitHub Personal Access Token (PAT) to retry (or press Enter to cancel)" -AsSecureString
        $Token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        )
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw "git push aborted."
        }
        Push-WithToken -TargetUrl $RepoUrl -Pat $Token
    }
}

Write-Host "Successfully pushed POCPTA to $RepoUrl" -ForegroundColor Green
