#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include "DHT.h"

// WiFi Credentials
#define WIFI_SSID "Dialog 4G 437"
#define WIFI_PASSWORD "D3c000D3"

// Firebase Credentials
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// Sensor Pins
#define FLAME_SENSOR_DIGITAL 4    
#define FLAME_SENSOR_ANALOG 34     
#define DHTPIN 27  
#define DHTTYPE DHT11
#define MQ3_PIN 35   // Use a different ADC-capable pin than flame analog

DHT dht(DHTPIN, DHTTYPE);

// Calibration constants for MQ-3 (you can fine-tune these)
const float airValue = 200;       // Sensor reading in clean air
const float alcoholValue = 4095;  // Max value under high concentration

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

void setup() {
  Serial.begin(115200);

  pinMode(FLAME_SENSOR_DIGITAL, INPUT);
  pinMode(FLAME_SENSOR_ANALOG, INPUT);
  pinMode(MQ3_PIN, INPUT);

  dht.begin();
  analogReadResolution(12); // Set ADC resolution (ESP32 default is 12-bit)

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nConnected to Wi-Fi");

  // Firebase setup
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = "testuser@gmail.com"; 
  auth.user.password = "test1234";
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (Firebase.ready()) {
    Serial.println("Firebase is ready");
  } else {
    Serial.println("Firebase failed to initialize");
    Serial.println(fbdo.errorReason());
  }
}

void loop() {
  if (!Firebase.ready()) return;

  // === FLAME SENSOR ===
  int analogFlameValue = analogRead(FLAME_SENSOR_ANALOG);
  String flameStatus = (analogFlameValue < 200) ? "Flame Detected!" : "No Flame Detected.";
  Serial.println("Flame Status: " + flameStatus);
  Firebase.RTDB.setString(&fbdo, "/sensors/flame/status", flameStatus);

  // === DHT11 SENSOR ===
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature(); // Celsius
  if (!isnan(humidity) && !isnan(temperature)) {
    Serial.printf("Humidity: %.2f %% | Temp: %.2f °C\n", humidity, temperature);
    Firebase.RTDB.setFloat(&fbdo, "/sensors/dht/humidity", humidity);
    Firebase.RTDB.setFloat(&fbdo, "/sensors/dht/temperature", temperature);
  } else {
    Serial.println("Failed to read from DHT sensor!");
  }

  // === MQ-3 ALCOHOL SENSOR ===
  int mq3Value = analogRead(MQ3_PIN);
  float alcoholPercentage = map(mq3Value, airValue, alcoholValue, 0, 100);
  alcoholPercentage = constrain(alcoholPercentage, 0, 100);

  Serial.printf("MQ-3 Raw: %d | Alcohol %%: %.2f %%\n", mq3Value, alcoholPercentage);
  Firebase.RTDB.setFloat(&fbdo, "/sensors/alcohol/percentage", alcoholPercentage);
  Firebase.RTDB.setInt(&fbdo, "/sensors/alcohol/raw", mq3Value);

  delay(2000);  // Delay between updates
}