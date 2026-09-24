# 🛸 Orville Ops Lighting System (v2.1)

[![Release](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/jiludkumar-therealone/orville-ops-lighting)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4.svg)](https://github.com/jiludkumar-therealone/orville-ops-lighting)
[![Hardware](https://img.shields.io/badge/hardware-5V%20RGB%20Strip%20%28USB%29-green.svg)](https://github.com/jiludkumar-therealone/orville-ops-lighting)
[![License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

> **Starship Bridge Lighting & Ambient Operational Telemetry Synchronization for Windows 10/11 & Physical LED Strips.**  
> Inspired by planetary union bridge alert protocols from the *USS Orville*.

Transform any Windows workstation into an immersive starship bridge that dynamically synchronizes operating system accent colors, Windows Terminal color palettes, IDE themes (VS Code, Cursor, Antigravity, Windsurf), and physical USB ambient LED lighting in real time.

---

## 🎨 Operational Code Taxonomy

| Code State | Accent Hex | Terminal BG | Acoustic Cue | Tactical Purpose |
| :--- | :--- | :--- | :--- | :--- |
| 🟢 **`Green`** | `#059669` | `#071A13` | 523Hz ➔ 659Hz ➔ 784Hz | **Active Engineering**: Authorized autonomous coding, file mutations, builds, and compilation. |
| 🌸 **`Pink`** | `#DB2777` | `#1A0812` | 659Hz ➔ 880Hz | **Standby / Planning**: Read-only codebase analysis, architectural planning, awaiting Captain's approval. |
| 🔮 **`Purple`** | `#9333EA` | `#190A28` | 659Hz ➔ 830Hz ➔ 1046Hz | **Inter-Agent Handover**: Active baton pass / handover to a peer bridge officer or specialized AI subagent. |
| 🔴 **`Red`** | `#DC2626` | `#1A0808` | 880Hz Klaxon (3x) | **Battle Station / Anomaly**: Critical halt; build crashes, terminal faults, or emergency triage. |
| 🔵 **`Blue`** | `#0078D4` | `#08131D` | 1046Hz Steady Ping | **Watchstander / Monitor**: Outpost asset monitoring, background telemetry, field diagnostic support. |
| 🟡 **`Yellow`** | `#D97706` | `#1A0E04` | 740Hz Dual Pulse | **Tactical Staging**: Heightened alert, pre-deployment dry runs, caution state. |
| 🟠 **`Amber`** | `#D97706` | `#1A0E04` | 740Hz Dual Pulse | **Hardware Maintenance**: Physical server servicing, rack repairs, offline hardware provisioning. |
| 🚀 **`GoLive`** | `#2563EB` | `#0A1128` | 1046Hz High Tone | **Production Release**: Authorized live production deployment (`wrangler deploy`, main merge). |
| ⚪ **`Restore`** | *Baseline* | *Baseline* | 784Hz ➔ 523Hz (Desc) | **Stand Down (Deep Blue)**: Restores original baseline theme, terminal palettes, and daylight schedule. |

---

## 🔮 Code Purple: Inter-Agent Handover Protocol

**Code Purple** (`#9333EA`, deep violet terminal `#190A28`) governs bridge handover when a task shifts between autonomous agents (e.g. Lead Tactical Engineer Antigravity, Chief Engineering Officer Grok, or subagent bridge stations):

```
┌────────────────────────────────────────────────────────┐
│               BRIDGE ALERT: CODE PURPLE                │
│    Accent: #9333EA  |  BG: #190A28  |  Cursor: #C084FC  │
└──────────────────────────┬─────────────────────────────┘
                           │
         ┌─────────────────┴─────────────────┐
         ▼                                   ▼
┌──────────────────┐               ┌──────────────────┐
│ Handover Packet  │               │ Turn Coordinator │
│ .grok/bridge/    │               │ .grok/bridge/    │
│ inbox/TASK-*.md  │               │ active/TURN.json │
└──────────────────┘               └──────────────────┘
         │                                   │
         └─────────────────┬─────────────────┘
                           ▼
┌────────────────────────────────────────────────────────┐
│     3-Tone Ascending Acoustic Chime (E5-G#5-C6)        │
│          Baton Passed to Incoming Officer              │
└────────────────────────────────────────────────────────┘
```

1. **Trigger Conditions**:
   - Explicit Captain's order (e.g., *"hand over the task to grok"*).
   - Specialized officer delegation (UI design, deep math modeling, kernel debugging).
   - Context window ceiling or token quota exhaustion (e.g. approaching weekly rate limits).
2. **Handshake Artifacts**:
   - **Handover Task Packet**: Generated at `~/.grok/bridge/inbox/TASK-<timestamp>-<slug>.md` with technical diagnosis, suspected failure modes, and required actions.
   - **Turn Token**: `~/.grok/bridge/active/TURN.json` flipped to the receiving agent (e.g., `"current_turn": "Grok"`, `"ops_code": "Purple"`).
   - **Handoff Log**: Appended to `~/.grok/bridge/HANDOFF.md`.
3. **Telemetry Confirmation**:
   - System theme repaints in royal purple, acoustic chime emits `659Hz -> 830Hz -> 1046Hz`, and physical USB strip illuminates in violet (`SET_RGB:147,51,234`).

---

## ⚡ Core Innovations & Features

* **Zero-Residue Win32 Broadcast Engine**:
  * Directly writes 8-shade binary palettes into `HKCU:\Software\Microsoft\Windows\DWM` and `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent`.
  * Emits `WM_SETTINGCHANGE` broadcasts targeting `ImmersiveColorSet` and `WindowsThemeElement` via `[WinThemeBroadcaster]::SendMessageTimeout`.
  * **Eliminates residue highlights**: Flushes cached accent colors from **Microsoft Edge**, **Google Chrome**, UWP titlebars, and password focus halos without leaving ghost accents.
* **Zero-Restart Terminal Repaint**:
  * Automatically configures `Microsoft.WindowsTerminal` profile defaults with matching ANSI palettes.
  * Emits VT/OSC escape sequences (`\e]10;...\a`, `\e]11;...\a`, `\e]4;...\a`) into the active console tab for instant repaint without closing sessions.
* **Multi-IDE Fleet Chrome Tinting**:
  * Auto-injects dynamic `workbench.colorCustomizations` into all detected editors:
    * **Google Antigravity IDE**
    * **Visual Studio Code** (`Code` & `Code - Insiders`)
    * **Cursor IDE**
    * **Windsurf** & **VSCodium**
* **Physical 5V USB LED Strip Integration**:
  * Direct serial communication over USB (`COMx` at 115200 baud) with smooth PWM fading.
  * Ready-to-flash firmware for **Arduino** and **Raspberry Pi Pico**.
* **Synthesized Acoustic Telemetry**:
  * Multi-frequency acoustic alerts (`-Audio` switch) synthesized through the hardware console beeper.
* **Fleet HUD & Telemetry**:
  * `ops -Status` displays current operational state, engagement timestamp, and active LED COM port.
  * `ops -List` shows the full fleet operational catalog.

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

### 3. Usage Examples
```powershell
# Core operational code shifts
ops green              # Active Engineering mode
ops pink               # Standby / Planning mode
ops purple             # Inter-Agent Handover mode
ops blue               # Watchstander / Monitoring mode
ops red                # Battle Station / Anomaly alert
ops yellow             # Tactical staging mode
ops amber              # Hardware maintenance mode
ops golive             # Authorized production release
ops restore            # Stand down and return to baseline

# Audio-enabled alerts
ops red -Audio         # Shift with 3x acoustic klaxon
ops purple -Audio      # Shift with 3-tone handover chime

# Hardware LED strip targeting
ops purple -LedPort COM3

# Telemetry inspection
ops -Status            # View current active code and timestamp
ops -List              # View full fleet code catalog
```

---

## 💡 Physical 5V RGB LED Strip Setup

You can sync real-world bridge lighting using any standard **5V 4-wire Analog RGB LED Strip** (`+5V`, `G`, `R`, `B`).

### Hardware Bill of Materials
1. **5V Analog RGB LED Strip** (Common Anode `+5V`).
2. **Microcontroller**: Arduino Nano, Uno, Pro Micro, or Raspberry Pi Pico.
3. **3x Logic-Level N-Channel MOSFETs** (e.g. IRLZ44N, 2N7000, AO3400) or NPN transistors (TIP120, 2N2222).
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
* **Arduino**: Open [`firmware/arduino/orville_rgb_strip.ino`](firmware/arduino/orville_rgb_strip.ino) in Arduino IDE, select your board and COM port, and click **Upload**.
* **Raspberry Pi Pico**: Copy [`firmware/pico/main.py`](firmware/pico/main.py) to your Pico running MicroPython as `main.py`.

### Linking COM Port to Windows
To automatically broadcast to your LED strip without passing `-LedPort` each time:
```powershell
[Environment]::SetEnvironmentVariable('OPS_LED_PORT', 'COM3', 'User')
```

---

## 📜 Serial Protocol Reference

* **Baud Rate**: `115200` baud, 8-N-1.
* **Direct RGB Command**:
  ```
  SET_RGB:<R>,<G>,<B>\n
  Example: SET_RGB:147,51,234\n
  Response: ACK:RGB=147,51,234\n
  ```
* **Named Code Command**:
  ```
  CODE:<Name>\n
  Example: CODE:Purple\n
  Response: ACK:CODE=PURPLE\n
  ```
* **Health Check**:
  ```
  PING\n
  Response: ORVILLE_LED_OK\n
  ```

---

## 🛡️ License

MIT License. Designed & engineered by Jilu D Kumar.
