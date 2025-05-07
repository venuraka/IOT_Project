#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ====== Wi-Fi Credentials ======
#define WIFI_SSID "###"
#define WIFI_PASSWORD "#####"

// ====== Firebase Credentials ======
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ====== Firebase Objects ======
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ====== MQ-135 Smoke Sensor Setup ======
#define MQ135_PIN 32
#define SMOKE_THRESHOLD 1500  // Adjust based on testing

void setup() {
  Serial.begin(115200);
  pinMode(MQ135_PIN, INPUT);

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

  Serial.println("🔧 MQ-135 Smoke Sensor Test Started");
}

void loop() {
  if (!Firebase.ready()) return;

  int smokeLevel = analogRead(MQ135_PIN);
  String smokeStatus = smokeLevel > SMOKE_THRESHOLD ? "SMOKE DETECTED" : "NORMAL";

  // Upload to Firebase
  Firebase.RTDB.setInt(&fbdo, "/sensors/smoke/value", smokeLevel);
  Firebase.RTDB.setString(&fbdo, "/sensors/smoke/status", smokeStatus);

  // Debug Output
  Serial.print("Smoke Level: ");
  Serial.print(smokeLevel);
  Serial.print(" | Status: ");
  Serial.println(smokeStatus);

  delay(1000);  // Read every second
}
