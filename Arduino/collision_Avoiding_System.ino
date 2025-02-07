// Define sensor pins
const int numSensors = 4;
const int triggerPins[numSensors] = {7, 8, 9, 10}; // Triggers for each sensor
const int echoPins[numSensors] = {6, 5, 4, 3};     // Echoes for each sensor

long duration[numSensors];  // Stores pulse duration for each sensor
int distanceInCM[numSensors];  // Stores distance values for each sensor

void setup() {
    Serial.begin(500000);
    for (int i = 0; i < numSensors; i++) {
        pinMode(triggerPins[i], OUTPUT);
        pinMode(echoPins[i], INPUT);
    }
}

void loop() {
    for (int i = 0; i < numSensors; i++) {
        // Send trigger pulse
        digitalWrite(triggerPins[i], LOW);
        delayMicroseconds(2);
        digitalWrite(triggerPins[i], HIGH);
        delayMicroseconds(10);
        digitalWrite(triggerPins[i], LOW);

        // Read echo pulse duration
        duration[i] = pulseIn(echoPins[i], HIGH);
        distanceInCM[i] = duration[i] / 29 / 2;

        // Print distance for this sensor
        Serial.print("Sensor ");
        Serial.print(i + 1);
        Serial.print(": ");
        Serial.print(distanceInCM[i]);
        Serial.println(" cm");

        delay(50);  // Small delay to avoid overlapping signals
    }
    Serial.println("--------------------");
    delay(500); // General delay before the next reading
}