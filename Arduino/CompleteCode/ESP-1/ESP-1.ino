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

// Flame Sensor Pins (ESP32)
#define FLAME_SENSOR_DIGITAL 4    
#define FLAME_SENSOR_ANALOG 34     

// DHT11 Sensor
#define DHTPIN 27  
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

int threshold = 200;  // Set detection threshold for flame sensor 

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

void setup() {
  Serial.begin(115200);

  pinMode(FLAME_SENSOR_DIGITAL, INPUT);
  pinMode(FLAME_SENSOR_ANALOG, INPUT);

  dht.begin();

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nConnected to Wi-Fi");

  // Set Firebase credentials
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // OPTIONAL: Use a newly created user, or anonymous login for testing
  auth.user.email = "testuser@gmail.com"; 
  auth.user.password = "test1234";        

  // Required for token generation status
  config.token_status_callback = tokenStatusCallback;

  // Initialize Firebase
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

  // ==== FLAME SENSOR ====
  int analogValue = analogRead(FLAME_SENSOR_ANALOG);
  String flameStatus;

  if (analogValue < threshold) {
    flameStatus = "Flame Detected!";
  } else {
    flameStatus = "No Flame Detected.";
  }

  Serial.println("Flame Status: " + flameStatus);

  if (Firebase.RTDB.setString(&fbdo, "/sensors/flame/status", flameStatus)) {
    Serial.println("Flame status sent to Firebase");
  } else {
    Serial.println("Firebase Error (flame): " + fbdo.errorReason());
  }

  // ==== DHT11 SENSOR ====
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature(); // Celsius

  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("Failed to read from DHT sensor!");
  } else {
    Serial.print("Humidity: ");
    Serial.print(humidity);
    Serial.print(" %, Temperature: ");
    Serial.print(temperature);
    Serial.println(" °C");

    // Send to Firebase
    Firebase.RTDB.setFloat(&fbdo, "/sensors/dht/humidity", humidity);
    Firebase.RTDB.setFloat(&fbdo, "/sensors/dht/temperature", temperature);
  }

  delay(2000);  // 2 second delay between loops
}