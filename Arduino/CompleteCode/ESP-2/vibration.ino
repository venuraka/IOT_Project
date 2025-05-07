#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ===== Wi-Fi Credentials =====
#define WIFI_SSID "..."
#define WIFI_PASSWORD "..."

// ===== Firebase Credentials =====
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Firebase Objects =====
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ===== Vibration Sensor Setup =====
#define VIBRATION_PIN 33
#define VIBRATION_THRESHOLD 4000  // Adjust as needed

int vibrationCount = 0;
bool vibrationActive = false;

void setup() {
  Serial.begin(115200);
  pinMode(VIBRATION_PIN, INPUT);

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\n✅ Wi-Fi Connected");

  // Setup Firebase
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
    Serial.println("❌ Firebase init failed: " + fbdo.errorReason());
  }

  Serial.println("🔧 801S Vibration Sensor Test Started");
}

void loop() {
  if (!Firebase.ready()) return;

  int sensorValue = analogRead(VIBRATION_PIN);

  // Detect vibration
  if (sensorValue > VIBRATION_THRESHOLD) {
    if (!vibrationActive) {
      vibrationActive = true;
      vibrationCount++;
      Serial.println("💥 Vibration Detected!");
    }
  } else {
    vibrationActive = false;
  }

  // Upload to Firebase
  Firebase.RTDB.setInt(&fbdo, "/sensors/vibration/value", sensorValue);
  Firebase.RTDB.setString(&fbdo, "/sensors/vibration/status", (vibrationActive ? "VIBRATION" : "STABLE"));
  Firebase.RTDB.setInt(&fbdo, "/sensors/vibration/count", vibrationCount);

  // Serial Monitor Output
  Serial.print("Analog Value: ");
  Serial.print(sensorValue);
  Serial.print(" | Status: ");
  Serial.print(vibrationActive ? "VIBRATION" : "STABLE");
  Serial.print(" | Count: ");
  Serial.println(vibrationCount);

  delay(500);  // adjust for smoother performance
}
