param(
    [string]$RepoUrl = "https://github.com/ntz-panupong/POCPTA.git",
    [string]$CommitMessage = "Update POCPTA"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".git")) {
    git init
}

git add -A
if (git status --porcelain) {
    git commit -m $CommitMessage
}

if (-not (git remote | Select-String -Pattern "^origin$" -Quiet)) {
    git remote add origin $RepoUrl
} else {
    git remote set-url origin $RepoUrl
}

git branch -M main
git push -u origin main
Write-Host "Successfully pushed POCPTA to $RepoUrl" -ForegroundColor Green
