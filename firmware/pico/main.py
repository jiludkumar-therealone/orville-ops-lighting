"""
🛸 Orville Ops Lighting — Raspberry Pi Pico (RP2040) MicroPython Controller
Hardware Wiring:
-------------------------------------------------------------
LED Strip Pin | Connection
-------------------------------------------------------------
+5V           | VBUS (Pin 40) for 5V from USB
R (Red)       | Drain of N-FET 1 (Gate -> Pico GP16, Source -> GND)
G (Green)     | Drain of N-FET 2 (Gate -> Pico GP17, Source -> GND)
B (Blue)      | Drain of N-FET 3 (Gate -> Pico GP18, Source -> GND)
GND           | Pico GND (Pin 38 or Pin 3)
-------------------------------------------------------------

Protocol:
  115200 baud USB CDC Serial
  Commands:
    SET_RGB:r,g,b\n   (e.g. SET_RGB:5,150,105)
    CODE:<Name>\n     (e.g. CODE:Green, CODE:Red)
"""

import sys
import select
import time
from machine import Pin, PWM

# Setup PWM channels on GP16, GP17, GP18 (1 kHz frequency)
pwm_r = PWM(Pin(16))
pwm_g = PWM(Pin(17))
pwm_b = PWM(Pin(18))

for pwm in (pwm_r, pwm_g, pwm_b):
    pwm.freq(1000)
    pwm.duty_u16(0)

cur_r, cur_g, cur_b = 0.0, 0.0, 0.0
target_r, target_g, target_b = 40.0, 40.0, 40.0

def set_target(r, g, b):
    global target_r, target_g, target_b
    target_r = max(0.0, min(255.0, float(r)))
    target_g = max(0.0, min(255.0, float(g)))
    target_b = max(0.0, min(255.0, float(b)))

def process_cmd(cmd):
    cmd = cmd.strip()
    if cmd.startswith("SET_RGB:"):
        parts = cmd[8:].split(",")
        if len(parts) == 3:
            try:
                r, g, b = int(parts[0]), int(parts[1]), int(parts[2])
                set_target(r, g, b)
                sys.stdout.write(f"ACK:RGB={r},{g},{b}\n")
            except ValueError:
                pass
    elif cmd.startswith("CODE:"):
        code = cmd[5:].strip().upper()
        if code == "GREEN":
            set_target(5, 150, 105)
        elif code == "PINK":
            set_target(219, 39, 119)
        elif code in ("RED", "BATTLESTATION"):
            set_target(220, 38, 38)
        elif code in ("BLUE", "WATCHSTANDER"):
            set_target(0, 120, 212)
        elif code == "GOLIVE":
            set_target(37, 99, 235)
        elif code in ("YELLOW", "TACTICAL", "AMBER", "MAINTENANCE"):
            set_target(217, 119, 6)
        elif code in ("RESTORE", "STANDDOWN", "DEEPBLUE"):
            set_target(0, 0, 0)
        sys.stdout.write(f"ACK:CODE={code}\n")

# Main loop
sys.stdout.write("ORVILLE_PICO_LIGHTING_ONLINE\n")
buf = ""

while True:
    # Non-blocking stdin check
    while select.select([sys.stdin], [], [], 0)[0]:
        char = sys.stdin.read(1)
        if char == "\n":
            process_cmd(buf)
            buf = ""
        elif char != "\r":
            buf += char

    # Smooth transition
    fade = 0.15
    cur_r += (target_r - cur_r) * fade
    cur_g += (target_g - cur_g) * fade
    cur_b += (target_b - cur_b) * fade

    # Convert 0-255 scale to 0-65535 PWM duty
    pwm_r.duty_u16(int(cur_r * 257))
    pwm_g.duty_u16(int(cur_g * 257))
    pwm_b.duty_u16(int(cur_b * 257))

    time.sleep_ms(15)
