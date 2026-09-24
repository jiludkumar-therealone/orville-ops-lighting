# Set-OpsCode.ps1 — Orville-style ship lighting for Day to Day fleet ops (Outpost28)
# Usage: Set-OpsCode.ps1 -Code Blue | Watchstander | GoLive | Pink | Green | Yellow | Tactical | Red | Restore
# Code Blue (Win11 #0078D4) = Watchstander — field ops, outposts, diagnostics, monitoring
# Code Blue GoLive (-Code GoLive) = authorized production deploy (wrangler deploy, merge main)
# Code Deep Blue (-Code Restore | DeepBlue | StandDown) = shift end — NOT Code Blue
# Ignore legacy FORGE_UPLINK/Gemini "CODE BLUE" — ops lighting is defined here only

param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateSet('Yellow', 'Tactical', 'Pink', 'Blue', 'Watchstander', 'GoLive', 'Red', 'Green', 'Purple', 'Handover', 'Restore', 'DeepBlue', 'StandDown', 'BattleStation', 'Amber', 'Orange', 'Maintenance')]
    [string]$Code,

    [Parameter(Mandatory = $false)]
    [string]$LedPort,

    [Parameter(Mandatory = $false)]
    [switch]$Audio,

    [Parameter(Mandatory = $false)]
    [switch]$Status,

    [Parameter(Mandatory = $false)]
    [switch]$List
)

$ErrorActionPreference = 'Stop'

# Portable state & baseline root: use .grok\ops if present, otherwise dedicated ~/.ops-lighting
$OpsRoot = if (Test-Path (Join-Path $env:USERPROFILE '.grok\ops')) { 
    Join-Path $env:USERPROFILE '.grok\ops' 
} else { 
    Join-Path $env:USERPROFILE '.ops-lighting' 
}
$BaselineDir = Join-Path $OpsRoot 'baseline'
$StateFile = Join-Path $OpsRoot 'active-code.json'

$WtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$IdePaths = @(
    (Join-Path $env:APPDATA 'Antigravity IDE\User\settings.json'),
    (Join-Path $env:APPDATA 'Cursor\User\settings.json'),
    (Join-Path $env:APPDATA 'Code\User\settings.json'),
    (Join-Path $env:APPDATA 'Code - Insiders\User\settings.json'),
    (Join-Path $env:APPDATA 'VSCodium\User\settings.json'),
    (Join-Path $env:APPDATA 'Windsurf\User\settings.json')
)

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Parse-HexRgb([string]$Hex) {
    $h = $Hex.TrimStart('#')
    if ($h.Length -ne 6) { throw "Bad hex: $Hex" }
    return @{
        R = [Convert]::ToInt32($h.Substring(0, 2), 16)
        G = [Convert]::ToInt32($h.Substring(2, 2), 16)
        B = [Convert]::ToInt32($h.Substring(4, 2), 16)
    }
}

function Hex-ToAccentDword([string]$Hex, [int]$Alpha = 255) {
    $c = Parse-HexRgb $Hex
    # Windows COLORREF / accent DWORD = AABBGGRR (not AARRGGBB)
    $hexStr = '{0:X2}{1:X2}{2:X2}{3:X2}' -f $Alpha, $c.B, $c.G, $c.R
    return [uint32]::Parse($hexStr, [System.Globalization.NumberStyles]::AllowHexSpecifier)
}

function Hex-ToDwmAccent([string]$Hex) {
    return Hex-ToAccentDword $Hex 255
}

function Build-AccentPalette([string]$Hex) {
    $c = Parse-HexRgb $Hex
    # Win11 shell reads AccentPalette as R,G,B,A per slot (not BGR DWORDs).
    $variants = @(
        @( $c.R, $c.G, $c.B, 255 ),
        @( [math]::Max(0, $c.R - 20), [math]::Max(0, $c.G - 20), [math]::Max(0, $c.B - 20), 255 ),
        @( [math]::Min(255, $c.R + 15), [math]::Min(255, $c.G + 15), [math]::Min(255, $c.B + 15), 255 ),
        @( [math]::Max(0, $c.R - 40), [math]::Max(0, $c.G - 40), [math]::Max(0, $c.B - 40), 255 ),
        @( [math]::Min(255, $c.R + 30), [math]::Min(255, $c.G + 30), [math]::Min(255, $c.B + 30), 255 ),
        @( [math]::Max(0, $c.R - 60), [math]::Max(0, $c.G - 60), [math]::Max(0, $c.B - 60), 255 ),
        @( [math]::Min(255, $c.R + 45), [math]::Min(255, $c.G + 45), [math]::Min(255, $c.B + 45), 255 ),
        @( [math]::Max(0, $c.R - 10), [math]::Max(0, $c.G - 10), [math]::Max(0, $c.B - 10), 255 )
    )
    $bytes = New-Object byte[] 32
    for ($i = 0; $i -lt 8; $i++) {
        $bytes[$i * 4] = [byte]$variants[$i][0]     # R
        $bytes[$i * 4 + 1] = [byte]$variants[$i][1] # G
        $bytes[$i * 4 + 2] = [byte]$variants[$i][2] # B
        $bytes[$i * 4 + 3] = [byte]$variants[$i][3] # A
    }
    return $bytes
}

function Backup-Baseline {
    Ensure-Dir $BaselineDir
    if (Test-Path $WtPath) {
        Copy-Item $WtPath (Join-Path $BaselineDir 'windows-terminal-settings.json') -Force
    }
    foreach ($ide in $IdePaths) {
        if (Test-Path $ide) {
            $name = ($ide -replace '[\\:]+', '_')
            Copy-Item $ide (Join-Path $BaselineDir "ide-settings$name") -Force
        }
    }
    $dwm = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\DWM' -ErrorAction SilentlyContinue
    $pers = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -ErrorAction SilentlyContinue
    $exp = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -ErrorAction SilentlyContinue
    @{
        AccentColor = $dwm.AccentColor
        AccentColorMenu = $dwm.AccentColorMenu
        ColorizationColor = $dwm.ColorizationColor
        DwmColorPrevalence = $dwm.ColorPrevalence
        ColorPrevalence = $pers.ColorPrevalence
        EnableTransparency = $pers.EnableTransparency
        SystemUsesLightTheme = $pers.SystemUsesLightTheme
        AppsUseLightTheme = $pers.AppsUseLightTheme
        ExplorerAccentColorMenu = $exp.AccentColorMenu
        ExplorerStartColorMenu = $exp.StartColorMenu
        ExplorerAccentPalette = @($exp.AccentPalette)
        ExplorerColorPrevalence = $exp.ColorPrevalence
        EnableWindowColorization = $dwm.EnableWindowColorization
    } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $BaselineDir 'windows-accent.json') -Encoding UTF8
}

function Test-DaylightHours {
    # PowerToys Light Switch schedule on Outpost28: light 06:00–18:00
    $h = (Get-Date).Hour
    return ($h -ge 6 -and $h -lt 18)
}

function Set-DarkMode {
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    if (-not (Test-Path $path)) { return }
    Set-ItemProperty -Path $path -Name 'SystemUsesLightTheme' -Type DWord -Value 0
    Set-ItemProperty -Path $path -Name 'AppsUseLightTheme' -Type DWord -Value 0
}

function Set-LightMode {
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    if (-not (Test-Path $path)) { return }
    Set-ItemProperty -Path $path -Name 'SystemUsesLightTheme' -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name 'AppsUseLightTheme' -Type DWord -Value 1
}

function Set-PowerToysScheduleTheme {
    if (Test-DaylightHours) { Set-LightMode } else { Set-DarkMode }
}

function Set-AccentPrevalence([bool]$Enabled) {
    $val = if ($Enabled) { 1 } else { 0 }
    $pers = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    $dwm = 'HKCU:\Software\Microsoft\Windows\DWM'
    $exp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'

    Set-ItemProperty -Path $pers -Name 'ColorPrevalence' -Type DWord -Value $val
    Set-ItemProperty -Path $dwm -Name 'ColorPrevalence' -Type DWord -Value $val
    Set-ItemProperty -Path $dwm -Name 'EnableWindowColorization' -Type DWord -Value $val
    if (Test-Path $exp) {
        Set-ItemProperty -Path $exp -Name 'ColorPrevalence' -Type DWord -Value $val -ErrorAction SilentlyContinue
    }
}

function Prepare-OpsShell {
    if (Test-DaylightHours) {
        Write-Host 'Daylight hours (06:00-18:00): overriding PowerToys Light Switch -> dark for ops.'
    }
    Set-AccentPrevalence $true
    Set-DarkMode
}

function Restart-Explorer {
    $shell = Get-Process explorer -ErrorAction SilentlyContinue
    if ($shell) {
        Stop-Process -Name explorer -Force
        Start-Sleep -Milliseconds 400
    }
    # Launch explorer shell in background mode without spawning a "This PC" window
    Start-Process explorer.exe -ArgumentList "/separate" -WindowStyle Hidden -ErrorAction SilentlyContinue
    # Force system theme parameters broadcast
    rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True

    # Broadcast Immersive Color flush to eliminate residue accents in Edge/Chrome/UWP
    try {
        if (-not ([System.Management.Automation.PSTypeName]'WinThemeBroadcaster').Type) {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinThemeBroadcaster {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@ -ErrorAction SilentlyContinue
        }
        $HWND_BROADCAST = [IntPtr]0xffff
        $WM_SETTINGCHANGE = 0x001A
        $SMTO_ABORTIFHUNG = 0x0002
        $result = [UIntPtr]::Zero
        [WinThemeBroadcaster]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "ImmersiveColorSet", $SMTO_ABORTIFHUNG, 1000, [ref]$result) | Out-Null
        [WinThemeBroadcaster]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "WindowsThemeElement", $SMTO_ABORTIFHUNG, 1000, [ref]$result) | Out-Null
    } catch {}
}

function Set-WindowsAccent([string]$AccentHex) {
    $dwmAccent = Hex-ToDwmAccent $AccentHex
    $argbAccent = Hex-ToAccentDword $AccentHex 255
    $glassAccent = Hex-ToAccentDword $AccentHex 204

    Ensure-Dir 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' | Out-Null

    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'AccentColor' -Type DWord -Value $dwmAccent
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'AccentColorMenu' -Type DWord -Value $dwmAccent
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'ColorizationColor' -Type DWord -Value $glassAccent
    if (Test-Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize') {
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AutoColorization' -Type DWord -Value 0 -ErrorAction SilentlyContinue
    }

    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -Name 'AccentColorMenu' -Type DWord -Value $argbAccent
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -Name 'StartColorMenu' -Type DWord -Value $argbAccent
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -Name 'AccentPalette' -Type Binary -Value (Build-AccentPalette $AccentHex)

    Restart-Explorer
}

function Get-Palette([string]$Name) {
    switch ($Name) {
        'Yellow' {
            return @{
                label = 'TACTICAL ALERT'
                accent = '#C9A227'
                terminalBg = '#2A2618'
                terminalFg = '#F5E6B8'
                terminalCursor = '#FFD166'
                terminalScheme = 'Ops Tactical Alert'
                terminalAnsi = @{
                    black = '#2A2618'; red = '#E05252'; green = '#6BCB77'; yellow = '#FFD166'
                    blue = '#4D9DE0'; purple = '#9B59B6'; cyan = '#48CAE4'; white = '#F5E6B8'
                    brightBlack = '#4A3F2E'; brightRed = '#FF6B6B'; brightGreen = '#7DEE88'; brightYellow = '#FFE066'
                    brightBlue = '#6BB5FF'; brightPurple = '#C77DFF'; brightCyan = '#72EFDD'; brightWhite = '#FFF8F0'
                    selectionBackground = '#5C4A1A'
                }
                ide = @{
                    'titleBar.activeBackground' = '#3D3520'
                    'titleBar.activeForeground' = '#F5E6B8'
                    'activityBar.background' = '#2A2618'
                    'activityBar.foreground' = '#D4AF37'
                    'statusBar.background' = '#4A3F1A'
                    'statusBar.foreground' = '#F5E6B8'
                    'sideBar.background' = '#2F2A1C'
                    'editor.background' = '#262218'
                    'terminal.background' = '#2A2618'
                    'terminal.foreground' = '#F5E6B8'
                    'panel.background' = '#2A2618'
                    'tab.activeBackground' = '#4A3F1A'
                    'tab.inactiveBackground' = '#2A2618'
                }
            }
        }
        'Blue' {
            return @{
                label = 'CODE BLUE — WATCHSTANDER'
                accent = '#0078D4'
                terminalBg = '#0C1E33'
                terminalFg = '#E3F0FF'
                terminalCursor = '#4FA3FF'
                terminalScheme = 'Ops Code Blue Watchstander'
                terminalAnsi = @{
                    black = '#0C1E33'; red = '#F87171'; green = '#4ADE80'; yellow = '#FBBF24'
                    blue = '#0078D4'; purple = '#8B5CF6'; cyan = '#60A5FA'; white = '#E3F0FF'
                    brightBlack = '#1A3A5C'; brightRed = '#FCA5A5'; brightGreen = '#86EFAC'; brightYellow = '#FDE68A'
                    brightBlue = '#4FA3FF'; brightPurple = '#A78BFA'; brightCyan = '#93C5FD'; brightWhite = '#F8FBFF'
                    selectionBackground = '#004578'
                }
                ide = @{
                    'titleBar.activeBackground' = '#004578'
                    'titleBar.activeForeground' = '#E3F0FF'
                    'activityBar.background' = '#0C1E33'
                    'activityBar.foreground' = '#4FA3FF'
                    'statusBar.background' = '#005A9E'
                    'statusBar.foreground' = '#E3F0FF'
                    'sideBar.background' = '#0F2438'
                    'editor.background' = '#0A1929'
                    'terminal.background' = '#0C1E33'
                    'terminal.foreground' = '#E3F0FF'
                    'panel.background' = '#0C1E33'
                    'tab.activeBackground' = '#005A9E'
                    'tab.inactiveBackground' = '#0C1E33'
                }
            }
        }
        'GoLive' {
            return @{
                label = 'CODE BLUE — GO LIVE'
                accent = '#005FB8'
                terminalBg = '#0A1929'
                terminalFg = '#F0F7FF'
                terminalCursor = '#0078D4'
                terminalScheme = 'Ops Code Blue GoLive'
                terminalAnsi = @{
                    black = '#0A1929'; red = '#F87171'; green = '#4ADE80'; yellow = '#FBBF24'
                    blue = '#005FB8'; purple = '#8B5CF6'; cyan = '#4FA3FF'; white = '#F0F7FF'
                    brightBlack = '#163656'; brightRed = '#FCA5A5'; brightGreen = '#86EFAC'; brightYellow = '#FDE68A'
                    brightBlue = '#0078D4'; brightPurple = '#A78BFA'; brightCyan = '#93C5FD'; brightWhite = '#FFFFFF'
                    selectionBackground = '#004578'
                }
                ide = @{
                    'titleBar.activeBackground' = '#003D6B'
                    'titleBar.activeForeground' = '#F0F7FF'
                    'activityBar.background' = '#0A1929'
                    'activityBar.foreground' = '#0078D4'
                    'statusBar.background' = '#0078D4'
                    'statusBar.foreground' = '#FFFFFF'
                    'sideBar.background' = '#0C1E33'
                    'editor.background' = '#081420'
                    'terminal.background' = '#0A1929'
                    'terminal.foreground' = '#F0F7FF'
                    'panel.background' = '#0A1929'
                    'tab.activeBackground' = '#0078D4'
                    'tab.inactiveBackground' = '#0A1929'
                }
            }
        }
        'Pink' {
            return @{
                label = 'CODE PINK'
                accent = '#DB2777'
                terminalBg = '#1F0A14'
                terminalFg = '#FCE7F3'
                terminalCursor = '#F472B6'
                terminalScheme = 'Ops Code Pink'
                terminalAnsi = @{
                    black = '#1F0A14'; red = '#FB7185'; green = '#4ADE80'; yellow = '#FACC15'
                    blue = '#60A5FA'; purple = '#F472B6'; cyan = '#22D3EE'; white = '#FCE7F3'
                    brightBlack = '#3F1528'; brightRed = '#FDA4AF'; brightGreen = '#6EE7B7'; brightYellow = '#FDE047'
                    brightBlue = '#93C5FD'; brightPurple = '#F9A8D4'; brightCyan = '#67E8F9'; brightWhite = '#FFF1F2'
                    selectionBackground = '#9D174D'
                }
                ide = @{
                    'titleBar.activeBackground' = '#831843'
                    'titleBar.activeForeground' = '#FCE7F3'
                    'activityBar.background' = '#1F0A14'
                    'activityBar.foreground' = '#F472B6'
                    'statusBar.background' = '#9D174D'
                    'statusBar.foreground' = '#FCE7F3'
                    'sideBar.background' = '#280F1A'
                    'editor.background' = '#1A0810'
                    'terminal.background' = '#1F0A14'
                    'terminal.foreground' = '#FCE7F3'
                    'panel.background' = '#1F0A14'
                    'tab.activeBackground' = '#9D174D'
                    'tab.inactiveBackground' = '#1F0A14'
                }
            }
        }
        'Red' {
            return @{
                label = 'BATTLE STATION'
                accent = '#B91C1C'
                terminalBg = '#1A0808'
                terminalFg = '#FFDADA'
                terminalCursor = '#FF4444'
                terminalScheme = 'Ops Code Red'
                terminalAnsi = @{
                    black = '#1A0808'; red = '#EF4444'; green = '#22C55E'; yellow = '#FACC15'
                    blue = '#3B82F6'; purple = '#A855F7'; cyan = '#22D3EE'; white = '#FFDADA'
                    brightBlack = '#4A2020'; brightRed = '#FF6B6B'; brightGreen = '#4ADE80'; brightYellow = '#FDE047'
                    brightBlue = '#60A5FA'; brightPurple = '#C084FC'; brightCyan = '#67E8F9'; brightWhite = '#FFFFFF'
                    selectionBackground = '#991B1B'
                }
                ide = @{
                    'titleBar.activeBackground' = '#450A0A'
                    'titleBar.activeForeground' = '#FEE2E2'
                    'activityBar.background' = '#2A1818'
                    'activityBar.foreground' = '#F87171'
                    'statusBar.background' = '#7F1D1D'
                    'statusBar.foreground' = '#FEE2E2'
                    'sideBar.background' = '#2A1818'
                    'editor.background' = '#241414'
                    'terminal.background' = '#1A0808'
                    'terminal.foreground' = '#FFDADA'
                    'panel.background' = '#2A1818'
                    'tab.activeBackground' = '#7F1D1D'
                    'tab.inactiveBackground' = '#2A1818'
                }
            }
        }
        'Green' {
            return @{
                label = 'CODE GREEN'
                accent = '#059669'
                terminalBg = '#071A13'
                terminalFg = '#A7F3D0'
                terminalCursor = '#10B981'
                terminalScheme = 'Ops Code Green'
                terminalAnsi = @{
                    black = '#071A13'; red = '#F87171'; green = '#059669'; yellow = '#EAB308'
                    blue = '#38BDF8'; purple = '#A78BFA'; cyan = '#10B981'; white = '#A7F3D0'
                    brightBlack = '#0D2B1E'; brightRed = '#FCA5A5'; brightGreen = '#34D399'; brightYellow = '#FDE047'
                    brightBlue = '#7DD3FC'; brightPurple = '#C4B5FD'; brightCyan = '#6EE7B7'; brightWhite = '#ECFDF5'
                    selectionBackground = '#064E3B'
                }
                ide = @{
                    'titleBar.activeBackground' = '#064E3B'
                    'titleBar.activeForeground' = '#A7F3D0'
                    'activityBar.background' = '#071A13'
                    'activityBar.foreground' = '#10B981'
                    'statusBar.background' = '#047857'
                    'statusBar.foreground' = '#A7F3D0'
                    'sideBar.background' = '#071A13'
                    'editor.background' = '#041310'
                    'terminal.background' = '#071A13'
                    'terminal.foreground' = '#A7F3D0'
                    'panel.background' = '#071A13'
                    'tab.activeBackground' = '#064E3B'
                    'tab.inactiveBackground' = '#071A13'
                }
            }
        }
        'Amber' {
            return @{
                label = 'CODE AMBER — HARDWARE MAINTENANCE'
                accent = '#D97706'
                terminalBg = '#1A0E04'
                terminalFg = '#FEF3C7'
                terminalCursor = '#F59E0B'
                terminalScheme = 'Ops Code Amber'
                terminalAnsi = @{
                    black = '#1A0E04'; red = '#EF4444'; green = '#10B981'; yellow = '#F59E0B'
                    blue = '#3B82F6'; purple = '#A855F7'; cyan = '#06B6D4'; white = '#FEF3C7'
                    brightBlack = '#3D200A'; brightRed = '#F87171'; brightGreen = '#34D399'; brightYellow = '#FBBF24'
                    brightBlue = '#60A5FA'; brightPurple = '#C084FC'; brightCyan = '#22D3EE'; brightWhite = '#FFFBEB'
                    selectionBackground = '#78350F'
                }
                ide = @{
                    'titleBar.activeBackground' = '#78350F'
                    'titleBar.activeForeground' = '#FEF3C7'
                    'activityBar.background' = '#1A0E04'
                    'activityBar.foreground' = '#F59E0B'
                    'statusBar.background' = '#92400E'
                    'statusBar.foreground' = '#FEF3C7'
                    'sideBar.background' = '#241306'
                    'editor.background' = '#140A02'
                    'terminal.background' = '#1A0E04'
                    'terminal.foreground' = '#FEF3C7'
                    'panel.background' = '#1A0E04'
                    'tab.activeBackground' = '#92400E'
                    'tab.inactiveBackground' = '#1A0E04'
                }
            }
        }
        'Purple' {
            return @{
                label = 'CODE PURPLE — INTER-AGENT HANDOVER'
                accent = '#9333EA'
                terminalBg = '#190A28'
                terminalFg = '#F3E8FF'
                terminalCursor = '#C084FC'
                terminalScheme = 'Ops Code Purple Handover'
                terminalAnsi = @{
                    black = '#190A28'; red = '#F87171'; green = '#4ADE80'; yellow = '#FACC15'
                    blue = '#818CF8'; purple = '#A855F7'; cyan = '#38BDF8'; white = '#F3E8FF'
                    brightBlack = '#3B185F'; brightRed = '#FCA5A5'; brightGreen = '#86EFAC'; brightYellow = '#FDE68A'
                    brightBlue = '#A5B4FC'; brightPurple = '#C084FC'; brightCyan = '#7DD3FC'; brightWhite = '#FAF5FF'
                    selectionBackground = '#6B21A8'
                }
                ide = @{
                    'titleBar.activeBackground' = '#581C87'
                    'titleBar.activeForeground' = '#F3E8FF'
                    'activityBar.background' = '#190A28'
                    'activityBar.foreground' = '#C084FC'
                    'statusBar.background' = '#6B21A8'
                    'statusBar.foreground' = '#F3E8FF'
                    'sideBar.background' = '#230E38'
                    'editor.background' = '#140720'
                    'terminal.background' = '#190A28'
                    'terminal.foreground' = '#F3E8FF'
                    'panel.background' = '#190A28'
                    'tab.activeBackground' = '#6B21A8'
                    'tab.inactiveBackground' = '#190A28'
                }
            }
        }
    }
}

function Set-TerminalTheme($Palette) {
    if (-not (Test-Path $WtPath)) {
        Write-Warning "Windows Terminal settings not found: $WtPath"
        return
    }
    $json = Get-Content $WtPath -Raw -Encoding UTF8
    $settings = $json | ConvertFrom-Json

    $ansi = $Palette.terminalAnsi
    $scheme = [ordered]@{
        name = $Palette.terminalScheme
        background = $Palette.terminalBg
        foreground = $Palette.terminalFg
        cursorColor = $Palette.terminalCursor
        black = $ansi.black
        red = $ansi.red
        green = $ansi.green
        yellow = $ansi.yellow
        blue = $ansi.blue
        purple = $ansi.purple
        cyan = $ansi.cyan
        white = $ansi.white
        brightBlack = $ansi.brightBlack
        brightRed = $ansi.brightRed
        brightGreen = $ansi.brightGreen
        brightYellow = $ansi.brightYellow
        brightBlue = $ansi.brightBlue
        brightPurple = $ansi.brightPurple
        brightCyan = $ansi.brightCyan
        brightWhite = $ansi.brightWhite
        selectionBackground = $ansi.selectionBackground
    }

    if (-not $settings.schemes) { $settings | Add-Member -NotePropertyName schemes -NotePropertyValue @() }
    $settings.schemes = @($settings.schemes | Where-Object { $_.name -ne $Palette.terminalScheme })
    $settings.schemes += [pscustomobject]$scheme

    if (-not $settings.profiles.defaults) { $settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) }
    $settings.profiles.defaults | Add-Member -NotePropertyName colorScheme -NotePropertyValue $Palette.terminalScheme -Force
    $settings.profiles.defaults | Add-Member -NotePropertyName background -NotePropertyValue $Palette.terminalBg -Force
    $settings.profiles.defaults | Add-Member -NotePropertyName useAcrylic -NotePropertyValue $false -Force

    ($settings | ConvertTo-Json -Depth 32) | Set-Content $WtPath -Encoding UTF8
}

function Set-IdeTheme($Palette) {
    foreach ($idePath in $IdePaths) {
        if (-not (Test-Path $idePath)) { continue }
        $raw = Get-Content $idePath -Raw -Encoding UTF8
        $settings = $raw | ConvertFrom-Json
        $custom = [ordered]@{}
        foreach ($k in $Palette.ide.Keys) { $custom[$k] = $Palette.ide[$k] }
        $settings | Add-Member -NotePropertyName 'workbench.colorCustomizations' -NotePropertyValue ([pscustomobject]$custom) -Force
        $settings | Add-Member -NotePropertyName 'terminal.integrated.cursorBlinking' -NotePropertyValue $true -Force
        ($settings | ConvertTo-Json -Depth 32) | Set-Content $idePath -Encoding UTF8
        Write-Host "IDE themed: $idePath"
    }
}

function Restore-Baseline {
    $wtBackup = Join-Path $BaselineDir 'windows-terminal-settings.json'
    if (Test-Path $wtBackup) {
        Copy-Item $wtBackup $WtPath -Force
        Write-Host 'Windows Terminal restored from baseline.'
    }
    Get-ChildItem $BaselineDir -Filter 'ide-settings*' -ErrorAction SilentlyContinue | ForEach-Object {
        $origName = $_.Name -replace '^ide-settings', '' -replace '_', '\' -replace 'UsersData Entry', 'Users\Data Entry'
        # Map back from sanitized name — use stored manifest instead
    }
    foreach ($ide in $IdePaths) {
        $safe = ($ide -replace '[\\:]+', '_')
        $backup = Join-Path $BaselineDir "ide-settings$safe"
        if (Test-Path $backup) {
            Copy-Item $backup $ide -Force
            Write-Host "IDE restored: $ide"
        }
    }
    $accentFile = Join-Path $BaselineDir 'windows-accent.json'
    if (Test-Path $accentFile) {
        $a = Get-Content $accentFile -Raw | ConvertFrom-Json
        if ($null -ne $a.AccentColor) {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'AccentColor' -Type DWord -Value ([uint32]$a.AccentColor)
        }
        if ($null -ne $a.AccentColorMenu) {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'AccentColorMenu' -Type DWord -Value ([uint32]$a.AccentColorMenu)
        }
        if ($null -ne $a.ColorizationColor) {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'ColorizationColor' -Type DWord -Value ([uint32]$a.ColorizationColor)
        }
        Set-AccentPrevalence $false
        Set-PowerToysScheduleTheme
        if (Test-DaylightHours) {
            Write-Host 'PowerToys schedule: light mode restored (06:00-18:00).'
        } else {
            Write-Host 'PowerToys schedule: dark mode restored (18:00-06:00).'
        }
        if ($null -ne $a.ExplorerAccentColorMenu) {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -Name 'AccentColorMenu' -Type DWord -Value ([uint32]$a.ExplorerAccentColorMenu)
        }
        if ($null -ne $a.ExplorerStartColorMenu) {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -Name 'StartColorMenu' -Type DWord -Value ([uint32]$a.ExplorerStartColorMenu)
        }
        if ($null -ne $a.ExplorerAccentPalette) {
            $bytes = [byte[]]@($a.ExplorerAccentPalette)
            if ($bytes.Length -eq 32) {
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent' -Name 'AccentPalette' -Type Binary -Value $bytes
            }
        }
        Restart-Explorer
        Write-Host 'Windows accent restored from baseline.'
    }
    $themeManifest = Join-Path $OpsRoot 'terminal-theme.json'
    if (Test-Path $themeManifest) { Remove-Item $themeManifest -Force }
    if (Test-Path $StateFile) { Remove-Item $StateFile -Force }
}

function Show-OpsList {
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host " [*] ORVILLE OPS LIGHTING -- FLEET CODES CATALOG" -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host " [Green]        Active engineering & code synthesis (#059669)" -ForegroundColor Green
    Write-Host " [Pink]         Planning, analysis, captain authorization (#DB2777)" -ForegroundColor Magenta
    Write-Host " [Red]          Critical anomaly, alert, battle station (#DC2626)" -ForegroundColor Red
    Write-Host " [Blue]         Watchstander, monitoring, fleet telemetry (#0078D4)" -ForegroundColor Blue
    Write-Host " [Yellow]       Tactical posture, caution, staging (#D97706)" -ForegroundColor Yellow
    Write-Host " [Amber]        Hardware maintenance & repairs (#D97706)" -ForegroundColor DarkYellow
    Write-Host " [GoLive]       Authorized production deployment (#2563EB)" -ForegroundColor Cyan
    Write-Host " [Purple]       Inter-agent handover / baton pass (#9333EA)" -ForegroundColor Magenta
    Write-Host " [Restore]      Stand down, restore original baseline (#Default)" -ForegroundColor Gray
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host " Usage: .\Set-OpsCode.ps1 -Code <Name> [-LedPort COMx] [-Audio]"
    Write-Host ""
}

function Show-OpsStatus {
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host " [*] ORVILLE OPS LIGHTING -- CURRENT TELEMETRY STATUS" -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor Cyan
    if (Test-Path $StateFile) {
        try {
            $state = Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Host (" Current Status:   {0}" -f $state.label) -ForegroundColor Green
            Write-Host (" Operational Code: {0}" -f $state.code) -ForegroundColor White
            Write-Host (" Engaged At:       {0}" -f $state.at) -ForegroundColor Gray
            if ($env:OPS_LED_PORT) {
                Write-Host (" LED Controller:   {0}" -f $env:OPS_LED_PORT) -ForegroundColor Yellow
            }
        } catch {
            Write-Host " Status: Active, but state telemetry could not be read." -ForegroundColor Yellow
        }
    } else {
        Write-Host " Current Status:   STAND DOWN / BASELINE (Cold-standby)" -ForegroundColor Gray
        Write-Host " Operational Code: Restore / None" -ForegroundColor DarkGray
    }
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Play-OpsAudio([string]$OpsCode) {
    try {
        switch -Regex ($OpsCode) {
            'Red|BattleStation' {
                [Console]::Beep(880, 140); Start-Sleep -Milliseconds 60
                [Console]::Beep(880, 140); Start-Sleep -Milliseconds 60
                [Console]::Beep(880, 260)
            }
            'Green' {
                [Console]::Beep(523, 90)
                [Console]::Beep(659, 90)
                [Console]::Beep(784, 140)
            }
            'Pink' {
                [Console]::Beep(659, 110)
                [Console]::Beep(880, 130)
            }
            'Purple|Handover' {
                [Console]::Beep(659, 100); Start-Sleep -Milliseconds 40
                [Console]::Beep(830, 100); Start-Sleep -Milliseconds 40
                [Console]::Beep(1046, 160)
            }
            'Blue|Watchstander|GoLive' {
                [Console]::Beep(1046, 180)
            }
            'Yellow|Amber|Tactical|Maintenance' {
                [Console]::Beep(740, 120); Start-Sleep -Milliseconds 70
                [Console]::Beep(740, 120)
            }
            'Restore|StandDown|DeepBlue' {
                [Console]::Beep(784, 120)
                [Console]::Beep(523, 200)
            }
            default {
                [Console]::Beep(600, 100)
            }
        }
    } catch {}
}

function Send-OpsLedColor([string]$Port, [string]$Hex, [string]$CodeName) {
    $targetPort = if ($Port) { $Port } elseif ($env:OPS_LED_PORT) { $env:OPS_LED_PORT } else { $null }
    if (-not $targetPort) { return }

    try {
        $rgb = if ($CodeName -eq 'Restore') {
            @{ R = 0; G = 0; B = 0 }
        } else {
            Parse-HexRgb $Hex
        }

        # Protocol format: SET_RGB:<R>,<G>,<B>\n
        $payload = "SET_RGB:{0},{1},{2}`n" -f $rgb.R, $rgb.G, $rgb.B

        $sp = New-Object System.IO.Ports.SerialPort $targetPort, 115200, None, 8, One
        $sp.ReadTimeout = 500
        $sp.WriteTimeout = 500
        $sp.DtrEnable = $true
        $sp.RtsEnable = $true
        $sp.Open()
        $sp.Write($payload)
        Start-Sleep -Milliseconds 50
        $sp.Close()
        $sp.Dispose()
        Write-Host ("    LED Strip: Sent RGB ({0},{1},{2}) via {3}" -f $rgb.R, $rgb.G, $rgb.B, $targetPort) -ForegroundColor DarkCyan
    } catch {
        Write-Warning ("Could not transmit to LED Controller on {0}: {1}" -f $targetPort, $_.Exception.Message)
    }
}

function Set-LocalTerminalDefaults([hashtable]$Palette, [string]$WtSettingsPath, [string]$OpsRootPath) {
    if (-not (Test-Path $WtSettingsPath)) { return }
    
    $FleetProfiles = @('Orion', 'Apollo', 'Argus')
    try {
        $json = Get-Content $WtSettingsPath -Raw -Encoding UTF8
        $settings = $json | ConvertFrom-Json

        if (-not $settings.profiles.defaults) {
            $settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{})
        }

        $settings.profiles.defaults | Add-Member -NotePropertyName colorScheme -NotePropertyValue $Palette.terminalScheme -Force
        $settings.profiles.defaults | Add-Member -NotePropertyName background -NotePropertyValue $Palette.terminalBg -Force
        $settings.profiles.defaults | Add-Member -NotePropertyName useAcrylic -NotePropertyValue $false -Force

        if ($settings.profiles.list) {
            foreach ($profile in $settings.profiles.list) {
                if ($FleetProfiles -contains $profile.name) {
                    @('colorScheme', 'background') | ForEach-Object {
                        if ($profile.PSObject.Properties.Name -contains $_) {
                            $profile.PSObject.Properties.Remove($_) | Out-Null
                        }
                    }
                    $profile | Add-Member -NotePropertyName useAcrylic -NotePropertyValue $false -Force
                }
            }
        }

        for ($retry = 0; $retry -lt 5; $retry++) {
            try {
                ($settings | ConvertTo-Json -Depth 32) | Set-Content $WtSettingsPath -Encoding UTF8
                break
            } catch {
                Start-Sleep -Milliseconds 200
            }
        }
    } catch {}

    $themeManifest = Join-Path $OpsRootPath 'terminal-theme.json'
    @{
        label = $Palette.label
        scheme = $Palette.terminalScheme
        background = $Palette.terminalBg
        foreground = $Palette.terminalFg
        cursor = $Palette.terminalCursor
        ansi = $Palette.terminalAnsi
        at = (Get-Date).ToString('o')
    } | ConvertTo-Json -Depth 6 | Set-Content $themeManifest -Encoding UTF8
}

function Send-TerminalOscTheme([hashtable]$Palette) {
    function Send-Osc([string]$Sequence) {
        $esc = [char]27
        [Console]::Write("$esc]$Sequence$esc\")
    }

    function Normalize-Hex([string]$Hex) {
        if ($Hex.StartsWith('#')) { return $Hex }
        return "#$Hex"
    }

    $ansi = $Palette.terminalAnsi
    if (-not $ansi) { return }

    $bg = Normalize-Hex $Palette.terminalBg
    $fg = Normalize-Hex $Palette.terminalFg
    $cursor = Normalize-Hex $Palette.terminalCursor

    Send-Osc "11;$bg"
    Send-Osc "10;$fg"
    Send-Osc "12;$cursor"

    $slots = @(
        $ansi.black, $ansi.red, $ansi.green, $ansi.yellow,
        $ansi.blue, $ansi.purple, $ansi.cyan, $ansi.white,
        $ansi.brightBlack, $ansi.brightRed, $ansi.brightGreen, $ansi.brightYellow,
        $ansi.brightBlue, $ansi.brightPurple, $ansi.brightCyan, $ansi.brightWhite
    )

    for ($i = 0; $i -lt $slots.Count; $i++) {
        if ($slots[$i]) {
            Send-Osc ("4;{0};{1}" -f $i, (Normalize-Hex $slots[$i]))
        }
    }
}

if ($List) {
    Show-OpsList
    exit 0
}

if ($Status -or [string]::IsNullOrWhiteSpace($Code)) {
    Show-OpsStatus
    exit 0
}

# Normalize aliases
$normalized = switch ($Code) {
    'Tactical' { 'Yellow' }
    'BattleStation' { 'Red' }
    'Watchstander' { 'Blue' }
    'Orange' { 'Amber' }
    'Maintenance' { 'Amber' }
    'DeepBlue' { 'Restore' }
    'StandDown' { 'Restore' }
    'Handover' { 'Purple' }
    default { $Code }
}

Ensure-Dir $OpsRoot
Ensure-Dir $BaselineDir

if ($normalized -eq 'Restore') {
    Restore-Baseline
    Send-OpsLedColor -Port $LedPort -Hex '#000000' -CodeName 'Restore'
    if ($Audio) { Play-OpsAudio 'Restore' }
    Write-Host '>>> STAND DOWN - normal lighting restored.'
    exit 0
}

if (-not (Test-Path (Join-Path $BaselineDir 'windows-terminal-settings.json'))) {
    Backup-Baseline
    Write-Host 'Baseline snapshot saved (first alert).'
}

# GoLive keeps its own palette (not normalized to Blue)
if ($Code -eq 'GoLive') { $normalized = 'GoLive' }
$palette = Get-Palette $normalized
Prepare-OpsShell
Set-WindowsAccent $palette.accent
Set-TerminalTheme $palette
Set-LocalTerminalDefaults -Palette $palette -WtSettingsPath $WtPath -OpsRootPath $OpsRoot
Send-TerminalOscTheme -Palette $palette
Set-IdeTheme $palette
Send-OpsLedColor -Port $LedPort -Hex $palette.accent -CodeName $normalized
if ($Audio) { Play-OpsAudio $normalized }

@{ code = $normalized; label = $palette.label; accent = $palette.accent; at = (Get-Date).ToString('o') } | ConvertTo-Json | Set-Content $StateFile -Encoding UTF8

# Sync active state to Outpost32 WebUI Console
try {
    Invoke-RestMethod -Uri "http://192.168.8.124:8085/api/set_code/$normalized" -TimeoutSec 1 -ErrorAction SilentlyContinue | Out-Null
} catch {}

Write-Host (">>> {0} - ship lighting active." -f $palette.label)
Write-Host ('    Accent: {0} | Terminal: {1}' -f $palette.accent, $palette.terminalBg)
Write-Host '    Current WT tab forced via OSC. New SSH tabs inherit via profiles.defaults.'
Write-Host '    Reload IDE window for full chrome tint.'
Write-Host '    Stand down: Set-OpsCode.ps1 -Code Restore'