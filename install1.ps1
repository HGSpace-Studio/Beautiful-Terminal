# Windows Terminal Beautifier - 卸载脚本

#Requires -RunAsAdministrator

param(
    [switch]$Force
)

$colors = @{
    Success = @{ Foreground = "Green"; Background = "Black" }
    Error = @{ Foreground = "Red"; Background = "Black" }
    Info = @{ Foreground = "Cyan"; Background = "Black" }
    Warning = @{ Foreground = "Yellow"; Background = "Black" }
}

function Write-ColorMessage {
    param([string]$Message, [string]$Type = "Info")
    $color = $colors[$Type]
    Write-Host $Message -ForegroundColor $color.Foreground -BackgroundColor $color.Background
}

Write-ColorMessage "`n🗑️  Windows Terminal Beautifier 卸载程序" "Warning"
Write-Host ""

if (-not $Force) {
    $confirmation = Read-Host "确定要卸载吗？[y/N]"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-ColorMessage "取消卸载" "Info"
        exit 0
    }
}

Write-ColorMessage "📝 开始卸载..." "Info"

# 1. 删除 PowerShell 配置
$pwshProfiles = @(
    "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
)

foreach ($profile in $pwshProfiles) {
    if (Test-Path $profile) {
        Write-ColorMessage "🗑️  删除: $profile" "Info"
        Remove-Item $profile -Force
    }
}

# 2. 删除 Oh My Posh 主题
$themePath = "$env:USERPROFILE\.oh-my-posh\themes\custom.omp.json"
if (Test-Path $themePath) {
    Write-ColorMessage "🗑️  删除主题: $themePath" "Info"
    Remove-Item $themePath -Force
}

# 3. 删除 CMD 配置
$clinkDir = "$env:LOCALAPPDATA\clink"
if (Test-Path "$clinkDir\custom_prompt.lua") {
    Write-ColorMessage "🗑️  删除 CMD 配置" "Info"
    Remove-Item "$clinkDir\custom_prompt.lua" -Force
}

# 4. 恢复注册表
$regPath = "HKCU:\Software\Microsoft\Command Processor"
try {
    Remove-ItemProperty -Path $regPath -Name AutoRun -ErrorAction SilentlyContinue
    Write-ColorMessage "✅ 注册表已恢复" "Success"
}
catch {
    # 注册表项可能不存在
}

Write-ColorMessage "`n✅ 卸载完成！" "Success"
Write-ColorMessage "请重启终端窗口使更改生效。`n" "Info"
