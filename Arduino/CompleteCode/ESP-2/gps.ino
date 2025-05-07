#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <TinyGPSPlus.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// === Wi-Fi Credentials ===
#define WIFI_SSID "##"
#define WIFI_PASSWORD "####"

// === Firebase Credentials ===
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// === Firebase Objects ===
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// === GPS Setup ===
TinyGPSPlus gps;
HardwareSerial GPSserial(2);
#define GPS_RX_PIN 19  // GPS TX → ESP32 RX
#define GPS_TX_PIN 18  // Not used for NEO-6M

void setup() {
  Serial.begin(115200);

  // Start GPS serial
  GPSserial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
  Serial.println("🔄 Initializing GPS...");

  // Connect Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("🌐 Connecting to Wi-Fi");
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

  Serial.println("📡 GPS tracking started...");
}

void loop() {
  // Process GPS data
  while (GPSserial.available() > 0) {
    gps.encode(GPSserial.read());
  }

  // If GPS location is valid, send to Firebase
  if (gps.location.isUpdated()) {
    double lat = gps.location.lat();
    double lng = gps.location.lng();

    Serial.print("Latitude: ");
    Serial.println(lat, 6);
    Serial.print("Longitude: ");
    Serial.println(lng, 6);

    if (Firebase.ready()) {
      // Upload latitude & longitude
      Firebase.RTDB.setDouble(&fbdo, "/gps/latitude", lat);
      Firebase.RTDB.setDouble(&fbdo, "/gps/longitude", lng);
    } else {
      Serial.println("⚠️ Firebase not ready");
    }
  }

  delay(1000);  // Update every 1 second
}
