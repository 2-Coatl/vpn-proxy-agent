# Windows System Diagnostic Script
Write-Host "=============================================="
Write-Host "  WINDOWS SYSTEM DIAGNOSTIC"
Write-Host "=============================================="
Write-Host ""

# System Info
Write-Host "System:"
Write-Host "   OS: $([System.Environment]::OSVersion.VersionString)"
Write-Host "   PowerShell: $($PSVersionTable.PSVersion)"
Write-Host ""

# SSH
Write-Host "SSH:"
if (Get-Command ssh -ErrorAction SilentlyContinue) {
    $sshVersion = ssh -V 2>&1 | Out-String
    Write-Host "   [OK] Installed: $sshVersion"
    
    if (Test-Path ~\.ssh\config) {
        Write-Host "   [OK] Config exists"
        $hosts = Get-Content ~\.ssh\config | Select-String "^Host " | ForEach-Object { $_ -replace "Host ", "      - " }
        Write-Host "   Configured hosts:"
        Write-Host $hosts
    }
} else {
    Write-Host "   [ERROR] SSH not installed"
}
Write-Host ""

# Tunnel
Write-Host "SOCKS5 Tunnel:"
$tunnel = netstat -an | Select-String "127.0.0.1:1080.*LISTENING"
if ($tunnel) {
    Write-Host "   [OK] Active on localhost:1080"
} else {
    Write-Host "   [WARN] Not active"
}
Write-Host ""

# VS Code
Write-Host "VS Code:"
if (Get-Command code -ErrorAction SilentlyContinue) {
    $codeVersion = code --version | Select-Object -First 1
    Write-Host "   [OK] Installed: $codeVersion"
} else {
    Write-Host "   [WARN] Not installed"
}
Write-Host ""

# Docker
Write-Host "Docker:"
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        $dockerVersion = docker --version
        Write-Host "   [OK] $dockerVersion"
    } catch {
        Write-Host "   [WARN] Installed but not running"
    }
} else {
    Write-Host "   [WARN] Not installed"
}
Write-Host ""

# Git
Write-Host "Git:"
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVersion = git --version
    Write-Host "   [OK] $gitVersion"
} else {
    Write-Host "   [WARN] Not installed"
}
Write-Host ""

# Connectivity
Write-Host "Connectivity:"
Write-Host "   Google: " -NoNewline
try {
    $null = Test-Connection google.com -Count 1 -Quiet
    Write-Host "[OK]"
} catch {
    Write-Host "[ERROR]"
}

if ($tunnel) {
    Write-Host "   API via Proxy: " -NoNewline
    try {
        $response = curl.exe --socks5 localhost:1080 -s -o nul -w "%{http_code}" https://api.anthropic.com
        if ($response -match "200|405") {
            Write-Host "[OK]"
        } else {
            Write-Host "[ERROR] ($response)"
        }
    } catch {
        Write-Host "[ERROR]"
    }
}

Write-Host ""
Write-Host "=============================================="
