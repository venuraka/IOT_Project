#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ===== WiFi Credentials =====
#define WIFI_SSID "##"
#define WIFI_PASSWORD "##"

// ===== Firebase Credentials =====
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Firebase Objects =====
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ===== Ultrasonic Sensor Configuration =====
const int trigPins[2] = {12, 23};   // frontLeft = 12, frontRight = 23
const int echoPins[2] = {14, 21};   // frontLeft = 14, frontRight = 21
const char* sensorKeys[2] = {"frontLeft", "frontRight"};

const int numSensors = 2;
const int numSamples = 5;
float distances[2];

void setup() {
  Serial.begin(115200);

  // Initialize ultrasonic pins
  for (int i = 0; i < numSensors; i++) {
    pinMode(trigPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\n✅ Connected to WiFi");

  // Initialize Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = "testuser@gmail.com";
  auth.user.password = "test1234";

  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (Firebase.ready()) {
    Serial.println("✅ Firebase is ready");
  } else {
    Serial.println("❌ Firebase failed to initialize: " + fbdo.errorReason());
  }
}

// Function to measure distance (in cm)
float measureDistance(int trigPin, int echoPin) {
  float total = 0;
  int valid = 0;

  for (int i = 0; i < numSamples; i++) {
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    long duration = pulseIn(echoPin, HIGH, 30000);  // Timeout: 30 ms
    if (duration > 0) {
      float distance = (duration * 0.0343) / 2.0;
      total += distance;
      valid++;
    }
    delay(10); // Small delay between samples
  }

  return (valid > 0) ? total / valid : -1.0;
}

void loop() {
  if (!Firebase.ready()) return;

  for (int i = 0; i < numSensors; i++) {
    distances[i] = measureDistance(trigPins[i], echoPins[i]);

    Serial.print(sensorKeys[i]);
    Serial.print(": ");
    if (distances[i] >= 0) {
      Serial.print(distances[i], 2);
      Serial.println(" cm");

      String path = "/sensors/ultrasonic/" + String(sensorKeys[i]) + "/status";
      if (Firebase.RTDB.setFloat(&fbdo, path, distances[i])) {
        Serial.println("✅ Sent to Firebase: " + path + " = " + String(distances[i]));
      } else {
        Serial.println("❌ Firebase Error: " + fbdo.errorReason());
      }
    } else {
      Serial.println("Out of range");
    }
  }

  Serial.println("-----------------------------");
  delay(500);
}
