const int vibrationSensorPin = 2;  // Define pin for the vibration sensor
const int threshold = 3;           // Number of consecutive detections to confirm vibration
int vibrationCount = 0;            // Counter for detected vibrations

void setup() {
    pinMode(vibrationSensorPin, INPUT);  // Set the pin as input
    Serial.begin(9600);  // Start serial communication
}

void loop() {
    int sensorValue = digitalRead(vibrationSensorPin);  // Read sensor value

    if (sensorValue == HIGH) {  
        vibrationCount++;  // Increase count if vibration detected
    } else {  
        vibrationCount = 0;  // Reset count if no vibration
    }

    // Trigger only if vibration is detected multiple times in a row
    if (vibrationCount >= threshold) {
        Serial.println("Strong vibration detected!");
        vibrationCount = 0;  // Reset after detection
    } else {
        Serial.println("No strong vibration detected.");
    }

    delay(100);  // Adjust delay to fine-tune detection sensitivity
}