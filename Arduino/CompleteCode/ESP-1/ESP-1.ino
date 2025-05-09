#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include "DHT.h"

// WiFi Credentials
#define WIFI_SSID "Ravindu A70"
#define WIFI_PASSWORD "Ravindu12345"

// Firebase Credentials
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// Sensor Pins
#define FLAME_SENSOR_DIGITAL 4    
#define DHTPIN 27  
#define DHTTYPE DHT11
#define MQ3_PIN 35   

DHT dht(DHTPIN, DHTTYPE);

// Calibration constants for MQ-3 
const float airValue = 200;
const float alcoholValue = 4095;

// Ultrasonic Sensor pins
const int trigPins[2] = {12, 23};  
const int echoPins[2] = {14, 21};
const char* sensorKeys[2] = {"backLeft", "backRight"};
const int numSensors = 2;
const int numSamples = 5;
float distances[2];

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Function to measure distance (in cm)
float measureDistance(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 50000);
  if (duration > 0 && duration < 30000) {
    return duration * 0.0343 / 2.0;
  }
  return -1.0; // Out of range
}

void setup() {
  Serial.begin(115200);

  pinMode(FLAME_SENSOR_DIGITAL, INPUT);
  pinMode(MQ3_PIN, INPUT);
  dht.begin();
  analogReadResolution(12);

  for (int i = 0; i < numSensors; i++) {
    pinMode(trigPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) delay(500);

  // Firebase setup
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = "testuser@gmail.com"; 
  auth.user.password = "test1234";
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  if (!Firebase.ready()) return;

  // Flame Sensor
  String flameStatus = (digitalRead(FLAME_SENSOR_DIGITAL) == LOW) ? "Flame Detected!" : "No Flame Detected.";
  Firebase.RTDB.setString(&fbdo, "/sensors/flame/status", flameStatus);

  // DHT Sensor
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();
  if (!isnan(humidity) && !isnan(temperature)) {
    Firebase.RTDB.setFloat(&fbdo, "/sensors/dht/humidity", humidity);
    Firebase.RTDB.setFloat(&fbdo, "/sensors/dht/temperature", temperature);
  }

  // MQ-3 Alcohol Sensor
  int mq3Value = analogRead(MQ3_PIN);
  float alcoholPercentage = map(mq3Value, airValue, alcoholValue, 0, 100);
  alcoholPercentage = constrain(alcoholPercentage, 0, 100);
  Firebase.RTDB.setFloat(&fbdo, "/sensors/alcohol/percentage", alcoholPercentage);

  // Ultrasonic Sensors
  for (int i = 0; i < numSensors; i++) {
    distances[i] = measureDistance(trigPins[i], echoPins[i]);

    String path = "/sensors/ultrasonic/" + String(sensorKeys[i]) + "/status";
    if (distances[i] > 0) {
      Firebase.RTDB.setFloat(&fbdo, path.c_str(), distances[i]);
    } else {
      Firebase.RTDB.setString(&fbdo, path.c_str(), "Out of range");
    }
  }

}
