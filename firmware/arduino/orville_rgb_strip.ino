/*
 * 🛸 Orville Ops Lighting — Physical RGB LED Strip Controller (Arduino)
 * Target Hardware: Arduino Uno, Nano, Pro Micro, or compatible ATmega board
 * 
 * Hardware Wiring:
 * -------------------------------------------------------------
 * LED Strip Pin | Connection
 * -------------------------------------------------------------
 * +5V           | +5V Power Rail (or Arduino 5V if strip is short < 0.5m)
 * R (Red)       | Drain of N-FET 1 (Gate -> Arduino Pin D9, Source -> GND)
 * G (Green)     | Drain of N-FET 2 (Gate -> Arduino Pin D10, Source -> GND)
 * B (Blue)      | Drain of N-FET 3 (Gate -> Arduino Pin D11, Source -> GND)
 * GND           | Arduino GND (Must share common ground with 5V supply)
 * -------------------------------------------------------------
 * 
 * Protocol:
 *   Baud Rate: 115200 baud (8-N-1)
 *   Commands:
 *     SET_RGB:r,g,b   -> e.g. "SET_RGB:5,150,105\n" (Smooth fade to target)
 *     CODE:<Name>     -> e.g. "CODE:Green\n", "CODE:Red\n", "CODE:Pink\n"
 *     PING            -> Responds "ORVILLE_LED_OK\n"
 */

const int PIN_RED   = 9;   // PWM Pin for Red channel
const int PIN_GREEN = 10;  // PWM Pin for Green channel
const int PIN_BLUE  = 11;  // PWM Pin for Blue channel

// Current output levels (0-255)
float curR = 0, curG = 0, curB = 0;
// Target output levels (0-255)
int targetR = 0, targetG = 0, targetB = 0;

// Fade speed: step interpolation per loop iteration
const float FADE_SPEED = 0.15f; 

void setup() {
  pinMode(PIN_RED, OUTPUT);
  pinMode(PIN_GREEN, OUTPUT);
  pinMode(PIN_BLUE, OUTPUT);

  // Default boot: gentle standby warm white
  setTarget(40, 40, 40);

  Serial.begin(115200);
  while (!Serial && millis() < 1000); // Wait briefly on native USB boards
  Serial.println("ORVILLE_OPS_LIGHTING_ONLINE");
}

void loop() {
  // Read Serial Commands
  if (Serial.available() > 0) {
    String line = Serial.readStringUntil('\n');
    line.trim();
    processCommand(line);
  }

  // Smooth cinematic color fading
  if (abs(curR - targetR) > 0.5f) curR += (targetR - curR) * FADE_SPEED; else curR = targetR;
  if (abs(curG - targetG) > 0.5f) curG += (targetG - curG) * FADE_SPEED; else curG = targetG;
  if (abs(curB - targetB) > 0.5f) curB += (targetB - curB) * FADE_SPEED; else curB = targetB;

  analogWrite(PIN_RED,   (int)curR);
  analogWrite(PIN_GREEN, (int)curG);
  analogWrite(PIN_BLUE,  (int)curB);

  delay(15);
}

void setTarget(int r, int g, int b) {
  targetR = constrain(r, 0, 255);
  targetG = constrain(g, 0, 255);
  targetB = constrain(b, 0, 255);
}

void processCommand(String cmd) {
  if (cmd.startsWith("SET_RGB:")) {
    String payload = cmd.substring(8);
    int comma1 = payload.indexOf(',');
    int comma2 = payload.indexOf(',', comma1 + 1);
    if (comma1 > 0 && comma2 > comma1) {
      int r = payload.substring(0, comma1).toInt();
      int g = payload.substring(comma1 + 1, comma2).toInt();
      int b = payload.substring(comma2 + 1).toInt();
      setTarget(r, g, b);
      Serial.print("ACK:RGB=");
      Serial.print(r); Serial.print(",");
      Serial.print(g); Serial.print(",");
      Serial.println(b);
    }
  } else if (cmd.startsWith("CODE:")) {
    String code = cmd.substring(5);
    code.toUpperCase();
    if (code == "GREEN") {
      setTarget(5, 150, 105);        // #059669
    } else if (code == "PINK") {
      setTarget(219, 39, 119);       // #DB2777
    } else if (code == "RED" || code == "BATTLESTATION") {
      setTarget(220, 38, 38);        // #DC2626
    } else if (code == "BLUE" || code == "WATCHSTANDER") {
      setTarget(0, 120, 212);        // #0078D4
    } else if (code == "GOLIVE") {
      setTarget(37, 99, 235);        // #2563EB
    } else if (code == "YELLOW" || code == "TACTICAL" || code == "AMBER" || code == "MAINTENANCE") {
      setTarget(217, 119, 6);        // #D97706
    } else if (code == "RESTORE" || code == "STANDDOWN" || code == "DEEPBLUE") {
      setTarget(0, 0, 0);            // Stand down / off
    }
    Serial.print("ACK:CODE=");
    Serial.println(code);
  } else if (cmd == "PING") {
    Serial.println("ORVILLE_LED_OK");
  }
}
