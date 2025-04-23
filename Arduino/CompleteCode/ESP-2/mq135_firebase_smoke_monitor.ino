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

// ===== MQ135 Sensor =====
#define MQ135_PIN 32
#define SMOKE_THRESHOLD 2000

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

  // MQ135 Warm-up (optional)
  Serial.println("🔥 MQ135 Warming up...");
  delay(30000);
}

void loop() {
  if (!Firebase.ready()) return;

  int smokeLevel = analogRead(MQ135_PIN);

  Serial.print("🔥 Smoke Level: ");
  Serial.println(smokeLevel);

  // Upload raw value to Firebase
  if (Firebase.RTDB.setInt(&fbdo, "/sensors/mq135/rawValue", smokeLevel)) {
    Serial.println("✅ Uploaded: rawValue");
  } else {
    Serial.println("❌ Error: " + fbdo.errorReason());
  }

  // Upload air quality status
  String status = (smokeLevel > SMOKE_THRESHOLD) ? "High Smoke Detected" : "Normal";
  if (Firebase.RTDB.setString(&fbdo, "/sensors/mq135/status", status)) {
    Serial.println("✅ Uploaded: status = " + status);
  } else {
    Serial.println("❌ Error: " + fbdo.errorReason());
  }

  delay(2000);  // 2 sec delay between readings
}
