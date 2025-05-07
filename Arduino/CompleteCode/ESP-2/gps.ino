#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ===== Wi-Fi Credentials =====
#define WIFI_SSID "##"
#define WIFI_PASSWORD "$#"

// ===== Firebase Credentials =====
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Firebase Setup =====
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ===== GPS Setup =====
TinyGPSPlus gps;
HardwareSerial mySerial(2);  // Using UART2 (GPIO18 = RX, GPIO19 = TX)

void setup() {
  Serial.begin(115200);
  mySerial.begin(9600, SERIAL_8N1, 18, 19);  // GPS RX and TX

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("📶 Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\n✅ Wi-Fi Connected");

  // Configure Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = "testuser@gmail.com";
  auth.user.password = "test1234";
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  while (!Firebase.ready()) {
    Serial.println("⏳ Waiting for Firebase...");
    delay(1000);
  }
  Serial.println("✅ Firebase is ready");
}

void loop() {
  // Read and parse GPS data
  while (mySerial.available() > 0) {
    gps.encode(mySerial.read());
  }

  // Check if location is valid and updated
  if (gps.location.isUpdated() && gps.location.isValid()) {
    double lat = gps.location.lat();
    double lng = gps.location.lng();

    Serial.print("📍 Latitude: ");
    Serial.print(lat, 6);
    Serial.print(" | Longitude: ");
    Serial.println(lng, 6);

    // Firebase base path
    String basePath = "/sensors/gps";

    // Send to Firebase
    Firebase.RTDB.setDouble(&fbdo, basePath + "/latitude", lat);
    Firebase.RTDB.setDouble(&fbdo, basePath + "/longitude", lng);

    delay(3000);  // Update every 3 seconds
  }
}
