#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// WiFi Credentials
#define WIFI_SSID "Fiber SLT"
#define WIFI_PASSWORD "#Ranasinghe903"

// Firebase Credentials
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// Flame Sensor Pins (ESP32)
#define FLAME_SENSOR_DIGITAL 4     // Digital input from flame sensor
#define FLAME_SENSOR_ANALOG 34     // Use GPIO34 for analog input

int threshold = 500;  // Set detection threshold

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

void setup() {
  Serial.begin(115200);

  pinMode(FLAME_SENSOR_DIGITAL, INPUT);
  pinMode(FLAME_SENSOR_ANALOG, INPUT);

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
  auth.user.email = "testuser@gmail.com"; // Replace with your test user
  auth.user.password = "test1234";        // Or leave blank if using anonymous login

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
  int analogValue = analogRead(FLAME_SENSOR_ANALOG);
  String flameStatus;

  if (analogValue < threshold) {
    flameStatus = "🔥 Flame Detected!";
    Serial.println(flameStatus);
  } else {
    flameStatus = "No Flame Detected.";
    Serial.println(flameStatus);
  }

  // Send to Firebase
  if (Firebase.RTDB.setString(&fbdo, "/flameSensor/status", flameStatus)) {
    Serial.println("Sent to Firebase: " + flameStatus);
  } else {
    Serial.println("Firebase Error: " + fbdo.errorReason());
  }

  delay(100);  // 2 second interval
}