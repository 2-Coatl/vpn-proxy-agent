# Windows Development Environment Stop Script
Write-Host "Stopping development environment..."

# Stop SSH tunnels
Get-Process ssh -ErrorAction SilentlyContinue | 
    Where-Object {$_.CommandLine -like "*-D 1080*"} | 
    Stop-Process -Force

# Clear environment variables
Remove-Item Env:\HTTP_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:\HTTPS_PROXY -ErrorAction SilentlyContinue

Write-Host "[OK] Environment stopped"
