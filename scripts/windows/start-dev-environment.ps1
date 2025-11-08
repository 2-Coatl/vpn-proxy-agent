# Windows Development Environment Startup Script
# Usage: .\start-dev-environment.ps1

Write-Host "=============================================="
Write-Host "  STARTING DEVELOPMENT ENVIRONMENT"
Write-Host "=============================================="
Write-Host ""

# Check SSH
Write-Host "[1/5] Checking SSH..."
if (Get-Command ssh -ErrorAction SilentlyContinue) {
    Write-Host "   [OK] SSH available"
} else {
    Write-Host "   [ERROR] SSH not found"
    exit 1
}

# Check VS Code
Write-Host "[2/5] Checking VS Code..."
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "   [OK] VS Code available"
} else {
    Write-Host "   [WARN] VS Code not found"
}

# Start SSH Tunnel
Write-Host "[3/5] Starting SSH tunnel..."
$tunnel = Get-Process -Name ssh -ErrorAction SilentlyContinue | 
    Where-Object {$_.CommandLine -like "*-D 1080*"}
    
if (-not $tunnel) {
    ssh -D 1080 -f -N vpn-server
    Start-Sleep -Seconds 2
    
    $verify = netstat -an | Select-String "1080.*LISTENING"
    if ($verify) {
        Write-Host "   [OK] Tunnel started on localhost:1080"
    } else {
        Write-Host "   [ERROR] Failed to start tunnel"
        exit 1
    }
} else {
    Write-Host "   [OK] Tunnel already active"
}

# Test connectivity
Write-Host "[4/5] Testing connectivity..."
try {
    $response = curl.exe --socks5 localhost:1080 -s -o nul -w "%{http_code}" https://api.anthropic.com
    if ($response -match "200|405") {
        Write-Host "   [OK] APIs accessible"
    } else {
        Write-Host "   [WARN] APIs returned code: $response"
    }
} catch {
    Write-Host "   [ERROR] API test failed"
}

# Configure environment
Write-Host "[5/5] Configuring environment..."
$env:HTTP_PROXY = "socks5://localhost:1080"
$env:HTTPS_PROXY = "socks5://localhost:1080"
Write-Host "   [OK] Environment variables set"

Write-Host ""
Write-Host "=============================================="
Write-Host "  ENVIRONMENT READY"
Write-Host "=============================================="
Write-Host ""
Write-Host "Commands:"
Write-Host "  VS Code Remote: code --remote ssh-remote+vpn-server"
Write-Host "  Stop tunnel: Get-Process ssh | Stop-Process"
Write-Host ""
