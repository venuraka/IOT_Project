#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <TinyGPSPlus.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ===== Wi-Fi Credentials =====
#define WIFI_SSID "Ravindu A70"
#define WIFI_PASSWORD "Ravindu12345"

// ===== Firebase Credentials =====
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// ===== Firebase Objects =====
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ===== Vibration Sensor Setup =====
#define VIBRATION_PIN 33
#define VIBRATION_THRESHOLD 500
int vibrationCount = 0;
bool vibrationActive = false;

// ===== Ultrasonic Sensor Configuration =====
const int trigPins[2] = {12, 23};
const int echoPins[2] = {14, 21};
const char* sensorKeys[2] = {"frontLeft", "frontRight"};
const int numSensors = 2;
const int numSamples = 5;
float distances[2];

// ===== GPS Setup =====
TinyGPSPlus gps;
HardwareSerial GPSserial(2);
#define GPS_RX_PIN 19
#define GPS_TX_PIN 18

// ===== MQ-135 Smoke Sensor Setup =====
#define MQ135_PIN 32
#define SMOKE_THRESHOLD 1200  // Adjust based on testing

void setup() {
  Serial.begin(115200);

  // Initialize sensor pins
  pinMode(VIBRATION_PIN, INPUT);
  pinMode(MQ135_PIN, INPUT);

  for (int i = 0; i < numSensors; i++) {
    pinMode(trigPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }

  // Start GPS
  GPSserial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
  Serial.println("🔄 Initializing GPS...");

  // Connect Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("🌐 Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(10);
  }
  Serial.println("\n✅ Wi-Fi Connected");

  // Firebase Setup
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

  Serial.println("🔧 All sensors initialized");
}

float measureDistance(int trigPin, int echoPin) {
  float total = 0;
  int valid = 0;
  for (int i = 0; i < numSamples; i++) {
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);
    long duration = pulseIn(echoPin, HIGH, 30000);
    if (duration > 0) {
      float distance = (duration * 0.0343) / 2.0;
      total += distance;
      valid++;
    }
    delay(10);
  }
  return (valid > 0) ? total / valid : -1.0;
}

void loop() {
  if (!Firebase.ready()) return;

  // === Vibration Sensor ===
  int vibrationVal = analogRead(VIBRATION_PIN);
  if (vibrationVal > VIBRATION_THRESHOLD) {
    if (!vibrationActive) {
      vibrationActive = true;
      vibrationCount++;
      Serial.println("💥 Vibration Detected!");
    }
  } else {
    vibrationActive = false;
  }
  Firebase.RTDB.setInt(&fbdo, "/sensors/vibration/value", vibrationVal);
  Firebase.RTDB.setString(&fbdo, "/sensors/vibration/status", (vibrationActive ? "VIBRATION" : "STABLE"));
  Firebase.RTDB.setInt(&fbdo, "/sensors/vibration/count", vibrationCount);

  Serial.print("Analog Value: ");
  Serial.print(vibrationVal);
  Serial.print(" | Status: ");
  Serial.print(vibrationActive ? "VIBRATION" : "STABLE");
  Serial.print(" | Count: ");
  Serial.println(vibrationCount);

  // === Ultrasonic Sensors ===
  for (int i = 0; i < numSensors; i++) {
    distances[i] = measureDistance(trigPins[i], echoPins[i]);
    Serial.print(sensorKeys[i]);
    Serial.print(": ");
    if (distances[i] >= 0) {
      Serial.print(distances[i], 2);
      Serial.println(" cm");
      String path = "/sensors/ultrasonic/" + String(sensorKeys[i]) + "/status";
      Firebase.RTDB.setFloat(&fbdo, path, distances[i]);
    } else {
      Serial.println("Out of range");
    }
  }

  // === GPS ===
  while (GPSserial.available() > 0) {
    gps.encode(GPSserial.read());
  }
  if (gps.location.isUpdated()) {
    double lat = gps.location.lat();
    double lng = gps.location.lng();
    Serial.print("Latitude: ");
    Serial.println(lat, 6);
    Serial.print("Longitude: ");
    Serial.println(lng, 6);
    Firebase.RTDB.setDouble(&fbdo, "/sensors/gps/latitude", lat);
    Firebase.RTDB.setDouble(&fbdo, "/sensors/gps/longitude", lng);
  }

  // === MQ-135 Smoke Sensor ===
  int smokeLevel = analogRead(MQ135_PIN);
  String smokeStatus = smokeLevel > SMOKE_THRESHOLD ? "SMOKE DETECTED" : "NORMAL";
  Firebase.RTDB.setInt(&fbdo, "/sensors/smoke/value", smokeLevel);
  Firebase.RTDB.setString(&fbdo, "/sensors/smoke/status", smokeStatus);

  Serial.print("Smoke Level: ");
  Serial.print(smokeLevel);
  Serial.print(" | Status: ");
  Serial.println(smokeStatus);

  Serial.println("-----------------------------");
  delay(10);
}
