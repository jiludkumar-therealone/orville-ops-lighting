# 🛸 Orville Ops Lighting System (v2.0)

[![Release](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/jiludkumar-therealone/orville-ops-lighting)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4.svg)](https://github.com/jiludkumar-therealone/orville-ops-lighting)
[![Hardware](https://img.shields.io/badge/hardware-5V%20RGB%20Strip%20%28USB%29-green.svg)](https://github.com/jiludkumar-therealone/orville-ops-lighting)
[![License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

> **Starship Bridge Lighting & Ambient Operational Telemetry Synchronization for Windows 10/11 & Physical LED Strips.**  
> Inspired by the *USS Orville* planetary union bridge alert protocols.

Transform any personal Windows workstation into an immersive starship bridge that dynamically synchronizes your operating system accent colors, Windows Terminal color schemes, VS Code / Cursor / Antigravity IDE themes, and physical USB ambient LED lighting in real time.

---

## 🎨 Operational Code States

| Code State | Accent Hex | Terminal BG | Tactical Purpose |
| :--- | :--- | :--- | :--- |
| 🟢 **`Green`** | `#059669` | `#071A13` | **Active Engineering**: Authorized autonomous coding, compilation, and builds. |
| 🌸 **`Pink`** | `#DB2777` | `#1A0812` | **Planning / Standby**: Read-only codebase analysis, architecture drafting, Captain's approval. |
| 🔴 **`Red`** | `#DC2626` | `#1A0808` | **Battle Station / Anomaly**: Emergency halted state, debugging, crash telemetry triage. |
| 🔵 **`Blue`** | `#0078D4` | `#08131D` | **Watchstander / Monitor**: Outpost asset monitoring, diagnostics, field support. |
| 🟡 **`Yellow`** | `#D97706` | `#1A0E04` | **Tactical Staging**: Heightened alert, pre-deployment staging, caution. |
| 🟠 **`Amber`** | `#D97706` | `#1A0E04` | **Hardware Maintenance**: Physical server repairs, hardware provisioning. |
| 🚀 **`GoLive`** | `#2563EB` | `#0A1128` | **Production Release**: Authorized live production deployment (`wrangler deploy`, main merge). |
| ⚪ **`Restore`** | *Baseline* | *Baseline* | **Stand Down (Deep Blue)**: Restores original baseline theme, terminal palettes, and daylight schedule. |

---

## ⚡ Core Innovations & Features

*   **Zero-Residue Win32 Broadcast Engine**:
    *   Directly writes to `HKCU:\Software\Microsoft\Windows\DWM` and `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent` with 8-shade binary palettes.
    *   Dispatches Win32 `WM_SETTINGCHANGE` broadcasts targeting `ImmersiveColorSet` and `WindowsThemeElement` via `[WinThemeBroadcaster]::SendMessageTimeout`.
    *   **Eliminates residue colors**: Instantly flushes cached accent colors from **Microsoft Edge**, **Google Chrome**, Windows UWP controls, and password input focus halos without leaving ghost highlights.
*   **Zero-Dependency Terminal Sync**:
    *   Automatically configures `Microsoft.WindowsTerminal` profile defaults with matching ANSI palettes.
    *   Emits VT/OSC escape sequences (`\e]10;...\a`, `\e]11;...\a`, `\e]4;...\a`) into the active console tab for instant repaint without restarting tabs.
*   **Multi-IDE Fleet Chrome Tinting**:
    *   Auto-injects dynamic `workbench.colorCustomizations` into all detected editors:
        *   **Visual Studio Code** (`Code` and `Code - Insiders`)
        *   **Cursor IDE**
        *   **Google Antigravity IDE**
        *   **Windsurf** & **VSCodium**
*   **Physical 5V USB LED Strip Integration**:
    *   Controls physical desk/room lighting using any standard **5V 4-wire Analog RGB LED strip** (`+5V`, `G`, `R`, `B`).
    *   Transmits color telemetry over USB Serial (`COMx` at 115200 baud) with smooth cinematic hardware PWM fading.
    *   Ready-to-flash firmware included for **Arduino** and **Raspberry Pi Pico**.
*   **Audio Telemetry Alerts**:
    *   Optional frequency-synthesized acoustic cues (`-Audio` switch) for each operational state.
*   **Status & Fleet HUD**:
    *   `ops -Status` displays the currently engaged operational state, engagement timestamp, and active LED controller port.
    *   `ops -List` shows all supported fleet codes.

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
ops green              # Shift to Active Engineering Mode
ops pink               # Shift to Standby / Planning Mode
ops blue               # Shift to Watchstander / Monitoring Mode
ops red                # Shift to Battle Station / Tactical Alert Mode
ops red -Audio         # Shift with acoustic alert klaxon
ops restore            # Stand down and return to native Windows baseline

ops -Status            # View active telemetry and engagement timestamp
ops -List              # View catalog of all operational alert codes
```

---

## 💡 Physical 5V RGB LED Strip Setup

You can sync real-world desk lighting using any common **5V 4-wire Analog RGB LED Strip** (identified by copper pads marked `+5V`, `G`, `R`, `B`).

### Hardware Bill of Materials
1. **5V Analog RGB LED Strip** (Common Anode `+5V`).
2. **Microcontroller**: Arduino Nano, Uno, Pro Micro, or Raspberry Pi Pico.
3. **3x Logic-Level N-Channel MOSFETs** (e.g. IRLZ44N, 2N7000, or AO3400) or NPN transistors (e.g. TIP120, 2N2222).
4. **3x 1kΩ - 10kΩ resistors** (Gate pull-downs).

### Wiring Schematic

```
                      +5V USB Power (or External 5V 2A Adapter)
                         |
                         +--------------------+ (Common Anode +5V)
                         |                    |
                 +---------------+     [ 5V RGB LED STRIP ]
                 | Arduino / Pico|        |    |    |
                 |               |        R    G    B
                 |   PWM Pin D9  |---+    |    |    |
                 |               |  [G]   |    |    |
                 |               |  [D]---+    |    |  (MOSFET 1 - Red)
                 |               |  [S]--GND   |    |
                 |               |             |    |
                 |   PWM Pin D10 |--+         [G]   |
                 |               |  [D]--------+    |  (MOSFET 2 - Green)
                 |               |  [S]--GND        |
                 |               |                  |
                 |   PWM Pin D11 |-+               [G]
                 |               | [D]--------------+  (MOSFET 3 - Blue)
                 |   GND Pin     |-[S]--GND
                 +---------------+
```

### Flashing Firmware
*   **Arduino**: Open [`firmware/arduino/orville_rgb_strip.ino`](firmware/arduino/orville_rgb_strip.ino) in Arduino IDE, select your board and COM port, and click **Upload**.
*   **Raspberry Pi Pico**: Copy [`firmware/pico/main.py`](firmware/pico/main.py) to your Pico running MicroPython as `main.py`.

### Linking COM Port to Windows
To automatically broadcast to your LED strip, set the environment variable or pass `-LedPort`:
```powershell
# Set permanently in your environment:
[Environment]::SetEnvironmentVariable('OPS_LED_PORT', 'COM3', 'User')

# Or pass explicitly:
ops red -LedPort COM3
```

---

## 📜 Serial Protocol Reference

*   **Baud Rate**: `115200` baud, 8-N-1.
*   **Direct RGB Command**:
    ```
    SET_RGB:<R>,<G>,<B>\n
    Example: SET_RGB:5,150,105\n
    Response: ACK:RGB=5,150,105\n
    ```
*   **Named Code Command**:
    ```
    CODE:<Name>\n
    Example: CODE:Green\n
    Response: ACK:CODE=GREEN\n
    ```
*   **Health Check**:
    ```
    PING\n
    Response: ORVILLE_LED_OK\n
    ```

---

## 🛡️ License

MIT License. Designed & engineered by Jilu D Kumar.
