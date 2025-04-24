#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include "DHT.h"

// WiFi Credentials
#define WIFI_SSID "Dialog 4G 437"
#define WIFI_PASSWORD "D3c000D3"

// Firebase Credentials
#define API_KEY "AIzaSyD5lrh1dowrXxvuNs16PZ8tKmRBIcsFdvg"
#define DATABASE_URL "https://fleetz-74a25-default-rtdb.asia-southeast1.firebasedatabase.app/"

// Sensor Pins
#define FLAME_SENSOR_DIGITAL 4    
#define FLAME_SENSOR_ANALOG 34     
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
  float total = 0;
  int valid = 0;

  for (int i = 0; i < numSamples; i++) {
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    long duration = pulseIn(echoPin, HIGH, 30000);  // 30ms timeout
    if (duration > 0) {
      float distance = duration * 0.0343 / 2.0;
      total += distance;
      valid++;
    }
    delay(10);
  }

  return (valid > 0) ? total / valid : -1.0;
}

void setup() {
  Serial.begin(115200);

  pinMode(FLAME_SENSOR_DIGITAL, INPUT);
  pinMode(FLAME_SENSOR_ANALOG, INPUT);
  pinMode(MQ3_PIN, INPUT);
  
  dht.begin();
  analogReadResolution(12);

  for (int i = 0; i < numSensors; i++) {
    pinMode(trigPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
  }

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nConnected to Wi-Fi");

  // Firebase setup
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = "testuser@gmail.com"; 
  auth.user.password = "test1234";
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (Firebase.ready()) {
    Serial.println("Firebase is ready");
  } else {
    Serial.println("Firebase failed to initialize");
    Serial.println(fbdo.errorReason());
  }
}

void loop() {
  if (!Firebase.ready()) return;

  // === FLAME SENSOR ===
  int analogFlameValue = analogRead(FLAME_SENSOR_ANALOG);
  String flameStatus = (analogFlameValue < 200) ? "Flame Detected!" : "No Flame Detected.";
  Serial.println("Flame Status: " + flameStatus);
  Firebase.RTDB.setString(&fbdo, "/sensors/flame/status", flameStatus);

  // === DHT11 SENSOR ===
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature(); 
  if (!isnan(humidity) && !isnan(temperature)) {
    Serial.printf("Humidity: %.2f %% | Temp: %.2f °C\n", humidity, temperature);
    Firebase.RTDB.setFloat(&fbdo, "/sensors/dht/humidity", humidity);
    Firebase.RTDB.setFloat(&fbdo, "/sensors/dht/temperature", temperature);
  } else {
    Serial.println("Failed to read from DHT sensor!");
  }

  // === MQ-3 ALCOHOL SENSOR ===
  int mq3Value = analogRead(MQ3_PIN);
  float alcoholPercentage = map(mq3Value, airValue, alcoholValue, 0, 100);
  alcoholPercentage = constrain(alcoholPercentage, 0, 100);
  Serial.printf("MQ-3 Raw: %d | Alcohol %%: %.2f %%\n", mq3Value, alcoholPercentage);
  Firebase.RTDB.setFloat(&fbdo, "/sensors/alcohol/percentage", alcoholPercentage);
  Firebase.RTDB.setInt(&fbdo, "/sensors/alcohol/raw", mq3Value);

  // === ULTRASONIC SENSORS ===
  for (int i = 0; i < numSensors; i++) {
    distances[i] = measureDistance(trigPins[i], echoPins[i]);

    if (distances[i] >= 0) {
      String path = "/sensors/ultrasonic/" + String(sensorKeys[i]) + "/status";
      Serial.printf("%s: %.2f cm\n", sensorKeys[i], distances[i]);
      Firebase.RTDB.setFloat(&fbdo, path.c_str(), distances[i]);
    } else {
      Serial.printf("%s: Out of range\n", sensorKeys[i]);
    }
  }

  Serial.println("-----------------------------");
  delay(2000);
}