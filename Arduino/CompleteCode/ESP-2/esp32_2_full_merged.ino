#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ===== Wi-Fi Credentials =====
#define WIFI_SSID "Home"
#define WIFI_PASSWORD "Ravindu@6205"
// Alternative Wi-Fi (uncomment to use Dialog)
// #define WIFI_SSID "Dialog 4G 437"
// #define WIFI_PASSWORD "D3c000D3"

// ===== Firebase Credentials =====
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Firebase Setup =====
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ===== GPS Setup =====
TinyGPSPlus gps;
HardwareSerial mySerial(2);  // UART2: GPIO18 = RX, GPIO19 = TX

// ===== Ultrasonic Sensor Setup =====
const int trigPins[2] = {12, 23};   // frontLeft, frontRight
const int echoPins[2] = {14, 21};
const char* sensorKeys[2] = {"frontLeft", "frontRight"};
const int numSensors = 2;
const int numSamples = 5;
float distances[2];

// ===== MQ135 Sensor =====
#define MQ135_PIN 32
#define SMOKE_THRESHOLD 2000

void setup() {
  Serial.begin(115200);

  // Init ultrasonic pins
  for (int i = 0; i < numSensors; i++) {
    pinMode(trigPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }

  // Init GPS serial
  mySerial.begin(9600, SERIAL_8N1, 18, 19);
  Serial.println("🔄 Starting sensors...");

  // MQ135 init
  pinMode(MQ135_PIN, INPUT);

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("📶 Connecting to Wi-Fi");
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

  while (!Firebase.ready()) {
    Serial.println("⏳ Waiting for Firebase...");
    delay(1000);
  }
  Serial.println("✅ Firebase is ready");

  // MQ135 Warm-up (optional)
  Serial.println("🔥 MQ135 Warming up...");
  delay(30000);
}

// ===== Measure Ultrasonic Distance (in cm) =====
float measureDistance(int trigPin, int echoPin) {
  float total = 0;
  int valid = 0;

  for (int i = 0; i < numSamples; i++) {
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    long duration = pulseIn(echoPin, HIGH, 30000);  // Timeout 30ms
    if (duration > 0) {
      float distance = duration * 0.0343 / 2.0;
      total += distance;
      valid++;
    }
    delay(10);
  }

  return (valid > 0) ? total / valid : -1.0;
}

void loop() {
  if (!Firebase.ready()) return;

  // ===== Read and Upload GPS Data =====
  while (mySerial.available() > 0) {
    gps.encode(mySerial.read());
  }

  if (gps.location.isUpdated() && gps.location.isValid()) {
    double lat = gps.location.lat();
    double lng = gps.location.lng();

    Serial.print("📍 Lat: ");
    Serial.print(lat, 6);
    Serial.print(" | Lon: ");
    Serial.println(lng, 6);

    Firebase.RTDB.setDouble(&fbdo, "/sensors/gps/latitude", lat);
    Firebase.RTDB.setDouble(&fbdo, "/sensors/gps/longitude", lng);
  }

  // ===== Read and Upload Ultrasonic Data =====
  for (int i = 0; i < numSensors; i++) {
    distances[i] = measureDistance(trigPins[i], echoPins[i]);

    Serial.print(sensorKeys[i]);
    Serial.print(": ");
    if (distances[i] >= 0) {
      Serial.print(distances[i], 2);
      Serial.println(" cm");

      String path = "/sensors/ultrasonic/" + String(sensorKeys[i]) + "/status";
      if (Firebase.RTDB.setFloat(&fbdo, path, distances[i])) {
        Serial.println("✅ Sent: " + path);
      } else {
        Serial.println("❌ Error: " + fbdo.errorReason());
      }
    } else {
      Serial.println("Out of range");
    }
  }

  // ===== Read and Upload MQ135 Smoke Level =====
  int smokeLevel = analogRead(MQ135_PIN);

  Serial.print("🔥 Smoke Level: ");
  Serial.println(smokeLevel);

  if (Firebase.RTDB.setInt(&fbdo, "/sensors/mq135/rawValue", smokeLevel)) {
    Serial.println("✅ Uploaded: rawValue");
  } else {
    Serial.println("❌ Error: " + fbdo.errorReason());
  }

  String status = (smokeLevel > SMOKE_THRESHOLD) ? "High Smoke Detected" : "Normal";
  if (Firebase.RTDB.setString(&fbdo, "/sensors/mq135/status", status)) {
    Serial.println("✅ Uploaded: status = " + status);
  } else {
    Serial.println("❌ Error: " + fbdo.errorReason());
  }

  delay(3000);
}
