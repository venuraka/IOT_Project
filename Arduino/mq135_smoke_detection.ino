// Pin Definitions
#define MQ135_PIN 34       // GPIO 34 for MQ135 Analog Output (Use an ADC pin)
#define BUZZER_PIN 14      // GPIO 14 for Buzzer
#define RED_LED_PIN 26     // GPIO 26 for Red LED (Alarm)
#define GREEN_LED_PIN 25   // GPIO 25 for Green LED (Normal)

// Threshold for Smoke Detection (Adjust based on testing)
#define SMOKE_THRESHOLD 2000  

void setup() {
  Serial.begin(115200);  // Start Serial Monitor

  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(GREEN_LED_PIN, OUTPUT);
  pinMode(MQ135_PIN, INPUT);  // Read Analog Values

  // Start with normal state
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(GREEN_LED_PIN, HIGH);  // Green LED ON (Normal)
}

void loop() {
  int smokeLevel = analogRead(MQ135_PIN);  // Read smoke sensor value
  Serial.print("🔥 Smoke Level: ");
  Serial.println(smokeLevel);

  // Check if smoke level exceeds threshold
  if (smokeLevel > SMOKE_THRESHOLD) {
    Serial.println("⚠️ Warning: High Smoke Detected!");

    digitalWrite(BUZZER_PIN, LOW);  // Turn on Buzzer
    digitalWrite(RED_LED_PIN, HIGH); // Turn on Red LED (Warning)
    digitalWrite(GREEN_LED_PIN, LOW); // Turn OFF Green LED
  } else {
    Serial.println("✅ Normal Air Quality");

    digitalWrite(BUZZER_PIN, HIGH);   // Turn off Buzzer
    digitalWrite(RED_LED_PIN, LOW);  // Turn off Red LED
    digitalWrite(GREEN_LED_PIN, HIGH); // Turn ON Green LED (Normal)
  }

  delay(10);  // Delay 1 second before next reading
}
