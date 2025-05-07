#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ===== Wi-Fi Credentials =====
#define WIFI_SSID "Dialog 4G 437"
#define WIFI_PASSWORD "D3c000D3"

// ===== Firebase Credentials =====
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Firebase Objects =====
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ===== Vibration Sensor Setup =====
#define VIBRATION_PIN 33
int vibrationCount = 0;
int vibrationValue = 0;
bool lastState = LOW;

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
}

void loop() {
  if (!Firebase.ready()) return;

  bool vibrationState = digitalRead(VIBRATION_PIN);

  // Detect rising edge
  if (vibrationState == HIGH && lastState == LOW) {
    vibrationCount++;
    vibrationValue += 100;  // Increase fake "vibration strength"
    Serial.println("💥 Vibration Detected!");
  }

  lastState = vibrationState;

  // Decay the vibration value over time (to simulate intensity fading)
  if (vibrationValue > 0) {
    vibrationValue -= 10; // Reduce gradually
  }

  // Upload to Firebase
  Firebase.RTDB.setInt(&fbdo, "/sensors/vibration/count", vibrationCount);
  Firebase.RTDB.setString(&fbdo, "/sensors/vibration/status", (vibrationState == HIGH ? "Vibration Detected" : "No Vibration"));
  Firebase.RTDB.setInt(&fbdo, "/sensors/vibration/value", vibrationValue);

  // Serial monitor logs
  Serial.print("Vibration State: ");
  Serial.println(vibrationState);
  Serial.print("Vibration Count: ");
  Serial.println(vibrationCount);
  Serial.print("Vibration Value (simulated): ");
  Serial.println(vibrationValue);

  delay(500);
}
