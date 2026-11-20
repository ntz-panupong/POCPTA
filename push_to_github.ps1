param(
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (git remote | Select-String -Pattern "^origin$" -Quiet)) {
    git remote add origin $RepoUrl
} else {
    git remote set-url origin $RepoUrl
}

git branch -M main
git push -u origin main
Write-Host "Successfully pushed POCPTA to $RepoUrl" -ForegroundColor Green
