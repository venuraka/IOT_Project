#include <DHT.h>

// Pin Definitions
#define DHTPIN 27            // GPIO 27 for DHT11
#define DHTTYPE DHT11        // Define DHT11 sensor
#define BUZZER_PIN 14        // GPIO 14 for Buzzer
#define RED_LED_PIN 26       // GPIO 26 for Red LED (Alarm)
#define GREEN_LED_PIN 25     // GPIO 25 for Green LED (Normal)

// Thresholds for Alarm System
#define TEMP_THRESHOLD 35 // High Temperature threshold in °C
#define HUMIDITY_THRESHOLD 20 // Low Humidity threshold in %

DHT dht(DHTPIN, DHTTYPE);  // Initialize DHT sensor

void setup() {
  Serial.begin(115200);  // Start Serial Monitor

  dht.begin();           // Initialize DHT sensor
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(GREEN_LED_PIN, OUTPUT);

  // Start with all alarms off
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(GREEN_LED_PIN, HIGH); // Green LED ON (Normal State)
}

void loop() {
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();  // Celsius

  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("❌ Failed to read from DHT sensor!");
    return;
  }

  Serial.print("🌡 Temperature: ");
  Serial.print(temperature);
  Serial.print("°C  |  💧 Humidity: ");
  Serial.print(humidity);
  Serial.println("%");

  // Check for high temperature OR low humidity
  if (temperature > TEMP_THRESHOLD || humidity < HUMIDITY_THRESHOLD) {
    Serial.println("⚠️ Warning: High Temperature or Low Humidity Detected!");
    
    digitalWrite(BUZZER_PIN, LOW);  // Turn on Buzzer
    digitalWrite(RED_LED_PIN, HIGH); // Turn on Red LED (Warning)
    digitalWrite(GREEN_LED_PIN, LOW); // Turn OFF Green LED
  } else {
    Serial.println("✅ Normal Condition: Buzzer OFF, Red LED OFF, Green LED ON");

    digitalWrite(BUZZER_PIN, HIGH);   // Turn off Buzzer
    digitalWrite(RED_LED_PIN, LOW);  // Turn off Red LED
    digitalWrite(GREEN_LED_PIN, HIGH); // Turn ON Green LED (Normal)
  }

  delay(10);  // Delay 2 seconds before next reading
}
