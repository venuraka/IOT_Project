void setup() {
    pinMode(A0, INPUT);  // Set the pin as input
    Serial.begin(9600);  // Start serial communication
}
void loop() {
    float sensorValue = analogRead(A0);  // Read sensor value

    // Trigger if alcohol level is above a certain threshold
    if (sensorValue > 700) {
        Serial.println("Alcohol detected!");
    } else {
        Serial.println("No alcohol detected.");
    }

    delay(100);  // Adjust delay to fine-tune detection sensitivity
}