# 🛸 Orville Ops Lighting System

> **Starship Bridge Lighting & Ambient Operational State Synchronization for Windows 10/11.**  
> Inspired by the *USS Orville* planetary union bridge alert protocols.

Transform your Windows workstation into an immersive starship bridge that dynamically synchronizes your operating system accent colors, Windows Terminal color schemes, VS Code / Cursor / Antigravity IDE themes, and physical USB ambient LED lighting in real time.

---

## 🎨 Operational Code States

| Code State | Hex Accent | Terminal Palette | Tactical Purpose |
| :--- | :--- | :--- | :--- |
| 🟢 **`Code Green`** | `#22C55E` | Emerald Matrix | **Active Engineering**: Autonomous coding, active builds, system creation. |
| 🌸 **`Code Pink`** | `#DB2777` | Neon Magenta | **Planning / Standby**: Architecture review, deep design, read-only analysis. |
| 🔵 **`Code Blue`** | `#0078D4` | Deep Watchstander | **Monitor / Watchstander**: Diagnostics, telemetry inspection, field support. |
| 🔴 **`Code Red`** | `#EF4444` | Tactical Alert | **Critical Anomaly**: Halts operations, error debugging, emergency response. |
| 🟡 **`Code Yellow`** | `#C9A227` | Amber Alert | **Caution / Fleet Deployment**: Staging, pre-flight checks, pending approvals. |
| 💿 **`Code Silver`** | `#94A3B8` | Lunar Slate | **Milestone Locked**: Autonomous git staging & version lock. |
| 🔵 **`Code Restore`** | Baseline | System Default | **Stand Down / Cold Standby**: Restores native Windows accent and daylight themes. |

---

## ⚡ Features & Architecture

*   **Native Windows 11 DWM Integration**:
    *   Directly writes to `HKCU:\Software\Microsoft\Windows\DWM` and `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent`.
    *   Generates an 8-shade harmonious `AccentPalette` binary matrix.
*   **Zero-Residue Win32 Broadcast Engine**:
    *   Broadcasts `WM_SETTINGCHANGE` with `lParam = "ImmersiveColorSet"` across all top-level windows via `SendMessageTimeout`.
    *   Instantly flushes cached accent colors from **Microsoft Edge**, **Google Chrome**, Windows UWP controls, and password input focus halos without leaving ghost residue colors.
*   **Windows Terminal Auto-Theming**:
    *   Automatically updates `Microsoft.WindowsTerminal` `settings.json` profiles with custom ANSI schemes.
    *   Uses VT/OSC escape sequences (`\e]10;...\a`, `\e]11;...\a`) to force immediate background/foreground changes in open tabs without requiring a terminal restart.
*   **Multi-IDE Fleet Chrome Tinting**:
    *   Synchronizes active titlebars, status bars, activity bars, and editor backgrounds across:
        *   **Visual Studio Code**
        *   **Cursor IDE**
        *   **Google Antigravity IDE**
*   **Ambient Physical LED Strip Ready**:
    *   Easily bridges to 5V RGB LED strips via USB serial (Arduino / Raspberry Pi Pico / ESP32) for physical room/desk alert lighting.

---

## 🚀 Quickstart Installation

### 1. Clone the Repository
```powershell
git clone https://github.com/jiludkumar-therealone/orville-ops-lighting.git "$HOME\orville-ops-lighting"
cd "$HOME\orville-ops-lighting"
```

### 2. Run Setup
```powershell
powershell -ExecutionPolicy Bypass -File ".\Install-OpsLighting.ps1"
```
This registers the global `ops` command in your PowerShell profile.

### 3. Usage
Simply type from any PowerShell or Windows Terminal window:
```powershell
ops green       # Shift to Active Engineering Mode
ops pink        # Shift to Planning / Architecture Mode
ops blue        # Shift to Watchstander / Monitoring Mode
ops red         # Shift to Tactical Alert Mode
ops restore     # Stand down and return to native Windows baseline
```

---

## 💡 Physical LED Strip Integration (Optional)

To sync physical desk lighting with the bridge codes:
1. Connect a standard **5V 4-wire Analog RGB LED strip** (`+5V`, `G`, `R`, `B`) to an Arduino Nano or Raspberry Pi Pico running a simple serial listener via 3 N-channel MOSFETs.
2. In `Set-OpsCode.ps1`, enable the serial broadcast block to transmit RGB hex codes to the COM port on state changes.

---

## 📜 License
MIT License. Created by Jilu D Kumar.
