# leetware licensing quick setup (Windows)
param(
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "leetware licensing setup" -ForegroundColor Cyan

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example — edit it before continuing." -ForegroundColor Yellow
    Write-Host "Required: DATABASE_URL, secrets, INITIAL_ADMIN_EMAIL, INITIAL_ADMIN_PASSWORD"
    exit 1
}

if (-not $SkipInstall) {
    npm install
}

npm run setup
Write-Host ""
Write-Host "Setup complete. Start the dev server with: npm run dev" -ForegroundColor Green
Write-Host "Dashboard: http://localhost:3000/dashboard"
