# Windows Terminal Beautifier - 安装脚本
# 自动美化 PowerShell 和 CMD

#Requires -RunAsAdministrator

param(
    [switch]$SkipPowerShell,
    [switch]$SkipCMD,
    [switch]$Force
)

# 颜色定义
$colors = @{
    Success = @{
        Foreground = "Green"
        Background = "Black"
    }
    Error = @{
        Foreground = "Red"
        Background = "Black"
    }
    Info = @{
        Foreground = "Cyan"
        Background = "Black"
    }
    Warning = @{
        Foreground = "Yellow"
        Background = "Black"
    }
}

# 打印带颜色的消息
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $color = $colors[$Type]
    Write-Host $Message -ForegroundColor $color.Foreground -BackgroundColor $color.Background
}

# 检查是否以管理员身份运行
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 检查网络连接
function Test-NetworkConnection {
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5
        return $true
    }
    catch {
        return $false
    }
}

# 安装 Oh My Posh
function Install-OhMyPosh {
    Write-ColorMessage "`n📦 安装 Oh My Posh..." "Info"
    
    # 检查是否已安装
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-ColorMessage "✅ Oh My Posh 已安装" "Success"
        return
    }
    
    # 安装 Oh My Posh
    try {
        winget install oh-my-posh --silent --accept-package-agreements --accept-source-agreements
        Write-ColorMessage "✅ Oh My Posh 安装成功" "Success"
    }
    catch {
        Write-ColorMessage "❌ Oh My Posh 安装失败: $_" "Error"
        exit 1
    }
}

# 安装 Nerd Fonts
function Install-NerdFonts {
    Write-ColorMessage "`n📦 安装 Nerd Fonts..." "Info"
    
    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $fontFile = "$fontsDir\CascadiaCode.zip"
    
    if (Test-Path "$fontsDir\CascadiaCodeNerdFontMono-Regular.ttf") {
        Write-ColorMessage "✅ Nerd Fonts 已安装" "Success"
        return
    }
    
    # 下载字体
    try {
        Write-ColorMessage "⬇️ 下载 Cascadia Code Nerd Font..." "Info"
        Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip" `
                          -OutFile $fontFile `
                          -UseBasicParsing
        
        # 解压字体
        Write-ColorMessage "📂 解压字体文件..." "Info"
        Expand-Archive -Path $fontFile -DestinationPath $fontsDir -Force
        
        # 安装字体
        Write-ColorMessage "🔧 安装字体..." "Info"
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.NameSpace(0x14)
        
        Get-ChildItem -Path "$fontsDir\CascadiaCode" -Filter "*.ttf" | ForEach-Object {
            $fontsFolder.CopyHere($_.FullName)
        }
        
        # 清理
        Remove-Item $fontFile -Force
        Remove-Item "$fontsDir\CascadiaCode" -Recurse -Force
        
        Write-ColorMessage "✅ Nerd Fonts 安装成功" "Success"
    }
    catch {
        Write-ColorMessage "❌ Nerd Fonts 安装失败: $_" "Error"
    }
}

# 安装 PowerShell 模块
function Install-PowerShellModules {
    Write-ColorMessage "`n📦 安装 PowerShell 模块..." "Info"
    
    $modules = @(
        @{ Name = "PSReadLine"; Version = "2.3.6" }
        @{ Name = "Terminal-Icons"; Version = "0.11.0" }
        @{ Name = "z"; Version = "1.1.13" }
    )
    
    foreach ($module in $modules) {
        if (Get-Module -Name $module.Name -ListAvailable) {
            Write-ColorMessage "✅ $($module.Name) 已安装" "Success"
            continue
        }
        
        try {
            Write-ColorMessage "⬇️ 安装 $($module.Name)..." "Info"
            Install-Module -Name $module.Name `
                           -MinimumVersion $module.Version `
                           -Scope CurrentUser `
                           -Force:$Force `
                           -SkipPublisherCheck `
                           -AllowClobber
            
            Import-Module $module.Name -Force
            Write-ColorMessage "✅ $($module.Name) 安装成功" "Success"
        }
        catch {
            Write-ColorMessage "⚠️  $($module.Name) 安装失败: $_" "Warning"
        }
    }
}

# 配置 PowerShell
function Set-PowerShellConfig {
    Write-ColorMessage "`n⚙️ 配置 PowerShell..." "Info"
    
    # 确定 PowerShell 版本
    $isPwsh7 = $PSVersionTable.PSVersion.Major -ge 7
    
    if ($isPwsh7) {
        $profilePath = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        Write-ColorMessage "📝 检测到 PowerShell 7+" "Info"
    }
    else {
        $profilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
        Write-ColorMessage "📝 检测到 PowerShell 5.1" "Info"
    }
    
    # 创建目录
    $profileDir = Split-Path $profilePath -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # 创建配置
    $configContent = @"
# PowerShell Profile - 美化配置
# 由 Windows Terminal Beautifier 自动生成

# 1. Oh My Posh 主题
# ------------------
oh-my-posh init pwsh --config "`$env:USERPROFILE\.oh-my-posh\themes\custom.omp.json" | Invoke-Expression

# 2. PSReadLine - 命令行编辑增强
# -------------------------------
Import-Module PSReadLine

# 语法高亮
Set-PSReadLineOption -Colors @{
    Command            = 'Yellow'
    Parameter          = 'Green'
    Operator           = 'Magenta'
    Variable           = 'White'
    String             = 'Cyan'
    Number             = 'Blue'
    Type               = 'DarkGray'
    Comment            = 'DarkGreen'
}

# 自动补全快捷键
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar
Set-PSReadLineKeyHandler -Key Ctrl+f -Function ForwardWord

# 3. Terminal-Icons - 文件图标
# -----------------------------
try {
    Import-Module Terminal-Icons -ErrorAction Stop
}
catch {
    # Terminal-Icons 可能未安装
}

# 4. z 模块 - 快速目录跳转
# -------------------------
try {
    Import-Module z -ErrorAction Stop
}
catch {
    # z 模块可能未安装
}

# 5. 常用别名和函数
# ------------------
# ls 别名（彩色输出）
if (-not (Get-Alias ls -ErrorAction SilentlyContinue)) {
    function ls { Get-ChildItem @args | Format-Table -AutoSize }
}
if (-not (Get-Alias ll -ErrorAction SilentlyContinue)) {
    function ll { Get-ChildItem @args | Format-Table -AutoSize }
}
if (-not (Get-Alias la -ErrorAction SilentlyContinue)) {
    function la { Get-ChildItem -Force @args | Format-Table -AutoSize }
}

# cat 别名
if (-not (Get-Alias cat -ErrorAction SilentlyContinue)) {
    function cat { Get-Content @args }
}

# which 命令
function which(`$name) { 
    Get-Command `$name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source 
}

# 快速编辑 profile
function Edit-Profile { code `$PROFILE }
Set-Alias -Name ep -Value Edit-Profile

# 快速重启 profile
function Reload-Profile { . `$PROFILE }
Set-Alias -Name rp -Value Reload-Profile

# 6. 窗口标题
# ---------------
`$host.UI.RawUI.WindowTitle = 'PowerShell'
"@
    
    # 备份旧配置
    if ((Test-Path $profilePath) -and -not $Force) {
        $backupPath = "$profilePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $profilePath $backupPath
        Write-ColorMessage "📁 已备份旧配置: $backupPath" "Info"
    }
    
    # 写入新配置
    $configContent | Out-File -FilePath $profilePath -Encoding UTF8
    Write-ColorMessage "✅ PowerShell 配置完成" "Success"
}

# 配置 Oh My Posh 主题
function Set-OhMyPoshTheme {
    Write-ColorMessage "`n🎨 配置 Oh My Posh 主题..." "Info"
    
    $themeDir = "$env:USERPROFILE\.oh-my-posh\themes"
    if (-not (Test-Path $themeDir)) {
        New-Item -ItemType Directory -Path $themeDir -Force | Out-Null
    }
    
    $themeContent = @'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 2,
  "final_space": false,
  "console_title": false,
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "newline": false,
      "segments": [
        {
          "type": "text",
          "style": "diamond",
          "foreground": "#ffffff",
          "background": "#26a69a",
          "leading_diamond": "\uE0B6",
          "trailing_diamond": "\uE0B0",
          "template": " {{ .UserName }}@{{ .HostName }}"
        },
        {
          "type": "path",
          "style": "diamond",
          "foreground": "#000000",
          "background": "#00d7ff",
          "leading_diamond": "\uE0B0",
          "trailing_diamond": "\uE0B0",
          "properties": {
            "folder_separator_icon": "/",
            "home_icon": "~",
            "style": "full"
          }
        }
      ]
    }
  ]
}
'@
    
    $themeContent | Out-File -FilePath "$themeDir\custom.omp.json" -Encoding UTF8
    Write-ColorMessage "✅ 主题配置完成" "Success"
}

# 安装和配置 Clink
function Install-Clink {
    Write-ColorMessage "`n📦 安装和配置 Clink..." "Info"
    
    # 检查是否已安装
    $clinkPath = "C:\Program Files (x86)\clink\clink.bat"
    if (Test-Path $clinkPath) {
        Write-ColorMessage "✅ Clink 已安装" "Success"
    }
    else {
        try {
            winget install chrisant996.Clink --silent --accept-package-agreements --accept-source-agreements
            Write-ColorMessage "✅ Clink 安装成功" "Success"
        }
        catch {
            Write-ColorMessage "❌ Clink 安装失败: $_" "Error"
        }
    }
}

# 配置 CMD
function Set-CMDConfig {
    Write-ColorMessage "`n⚙️ 配置 CMD..." "Info"
    
    $clinkDir = "$env:LOCALAPPDATA\clink"
    $promptLua = "$clinkDir\custom_prompt.lua"
    $settingsIni = "$clinkDir\clink_settings.ini"
    
    # 创建目录
    if (-not (Test-Path $clinkDir)) {
        New-Item -ItemType Directory -Path $clinkDir -Force | Out-Null
    }
    
    # CMD Oh My Posh 初始化代码
    $luaContent = @'
-- CMD Oh My Posh 配置
os.setenv('POSH_SESSION_ID', '35e94e25-1f50-4af9-b8aa-16d5ea1e464c')
load(io.open(os.getenv('USERPROFILE')..'\\AppData\\Local\\Packages\\ohmyposh.cli_96v55e8n804z4\\LocalCache\\Local\\oh-my-posh\\init.lua', "r"):read("*a"))()
'@
    
    # 备份旧配置
    if ((Test-Path $promptLua) -and -not $Force) {
        $backupPath = "$promptLua.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $promptLua $backupPath
        Write-ColorMessage "📁 已备份旧配置: $backupPath" "Info"
    }
    
    # 写入配置
    $luaContent | Out-File -FilePath $promptLua -Encoding UTF8
    
    # Clink 设置
    $settingsContent = @'
[lua]
script = custom_prompt.lua

[prompt]
show_guide = false
show_hidden = false

[input]
eat_ctrl_markup = true

[history]
dupe_mode = erase_prev
max_items = 10000

[clink]
prompt_info = false
autoupdate = off
update_host = false
show_update = false
welcome_text = false
color_input = false
color_prompt = true
color_state_error = #ff6b6b
color_state_warning = #feca57
color_state_success = #1dd1a1
color_arg = #54a0ff
color_cmd = #5f27cd
color_desc = #8395a7
color_filter = #ff9ff3
color_hist = #54a0ff
color_icon = #00d7ff
color_mod = #ff6b6b
color_popup = 0x80d7ff
color_popup_desc = #576574
color_selection = 0x80
color_suggestion = #8395a7
color_word = #feca57
search_mode = fuzzy
'@
    
    $settingsContent | Out-File -FilePath $settingsIni -Encoding UTF8
    
    # 设置注册表（如果 Clink 未自动配置）
    $regPath = "HKCU:\Software\Microsoft\Command Processor"
    $autorunValue = "`"$clinkPath`" inject --autorun"
    $currentValue = Get-ItemProperty -Path $regPath -Name AutoRun -ErrorAction SilentlyContinue
    
    if ($currentValue.AutoRun -ne $autorunValue) {
        Set-ItemProperty -Path $regPath -Name AutoRun -Value $autorunValue
        Write-ColorMessage "✅ CMD 注册表配置完成" "Success"
    }
    
    Write-ColorMessage "✅ CMD 配置完成" "Success"
}

# 显示完成信息
function Show-CompletionMessage {
    Write-ColorMessage "`n" "Success"
    Write-ColorMessage "╔════════════════════════════════════════════════════════╗" "Success"
    Write-ColorMessage "║                                                        ║" "Success"
    Write-ColorMessage "║        🎉 Windows Terminal 美化完成！🎉                ║" "Success"
    Write-ColorMessage "║                                                        ║" "Success"
    Write-ColorMessage "╚════════════════════════════════════════════════════════╝" "Success"
    Write-ColorMessage "`n" "Success"
    
    Write-ColorMessage "📋 接下来请执行以下操作：" "Info"
    Write-ColorMessage "`n" "Success"
    
    Write-ColorMessage "1️⃣  重启所有终端窗口" "Info"
    Write-ColorMessage "    - 关闭所有 PowerShell 和 CMD 窗口" "Success"
    Write-ColorMessage "    - 重新打开新的终端窗口" "Success"
    
    Write-ColorMessage "`n2️⃣  设置终端字体（推荐）" "Info"
    Write-ColorMessage "    - Windows Terminal: 设置 → 外观 → 字体" "Success"
    Write-ColorMessage "    - 选择 'Cascadia Code NF' 或 'FiraCode NF'" "Success"
    
    Write-ColorMessage "`n3️⃣  常用命令" "Info"
    Write-ColorMessage "    - ep       : 编辑配置文件" "Success"
    Write-ColorMessage "    - rp       : 重载配置" "Success"
    Write-ColorMessage "    - which    : 查找命令位置" "Success"
    
    Write-ColorMessage "`n✨ 享受美化后的终端吧！" "Success"
    Write-ColorMessage "`n"
}

# 主函数
function Main {
    # 显示标题
    Write-Host ""
    Write-ColorMessage "╔════════════════════════════════════════════════════════╗" "Info"
    Write-ColorMessage "║                                                        ║" "Info"
    Write-ColorMessage "║       Windows Terminal Beautifier v1.0.0               ║" "Info"
    Write-ColorMessage "║       一键美化 PowerShell 和 CMD                       ║" "Info"
    Write-ColorMessage "║                                                        ║" "Info"
    Write-ColorMessage "╚════════════════════════════════════════════════════════╝" "Info"
    Write-Host ""
    
    # 检查管理员权限
    if (-not (Test-Administrator)) {
        Write-ColorMessage "⚠️  建议以管理员身份运行以获得最佳效果" "Warning"
    }
    
    # 检查网络连接
    if (-not (Test-NetworkConnection)) {
        Write-ColorMessage "❌ 无法连接到网络，请检查网络连接" "Error"
        exit 1
    }
    
    # 询问用户
    Write-ColorMessage "`n📝 选择要美化的终端：" "Info"
    Write-ColorMessage "   1. PowerShell (推荐)" -NoNewline; Write-Host " ✓" -ForegroundColor Green
    Write-ColorMessage "   2. CMD" -NoNewline; Write-Host " ✓" -ForegroundColor Green
    Write-ColorMessage "   3. 两者都要 (默认)" "Info"
    Write-ColorMessage ""
    
    if ($SkipPowerShell -and $SkipCMD) {
        Write-ColorMessage "❌ 你选择了跳过所有终端，程序退出" "Error"
        exit 1
    }
    
    $installAll = -not $SkipPowerShell -and -not $SkipCMD
    
    # 开始安装
    if (-not $SkipPowerShell -or $installAll) {
        Install-OhMyPosh
        Install-NerdFonts
        Install-PowerShellModules
        Set-OhMyPoshTheme
        Set-PowerShellConfig
    }
    
    if (-not $SkipCMD -or $installAll) {
        Install-Clink
        Set-CMDConfig
    }
    
    # 显示完成信息
    Show-CompletionMessage
}

# 运行主函数
Main
