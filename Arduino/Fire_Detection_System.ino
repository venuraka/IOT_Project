#define FLAME_SENSOR_DIGITAL 4  // Digital output pin
#define FLAME_SENSOR_ANALOG A0  // Analog output pin

int threshold = 500;  // Adjust this value to increase detection distance

void setup() {
    pinMode(FLAME_SENSOR_DIGITAL, INPUT);
    pinMode(FLAME_SENSOR_ANALOG, INPUT);
  
    Serial.begin(9600);
}

void loop() {
    int analogValue = analogRead(FLAME_SENSOR_ANALOG);


    // If the analog value is below the threshold, flame is detected
    if (analogValue < threshold) {  
        Serial.println("🔥 Flame Detected! 🔥");
    } else {
        Serial.println("No Flame Detected.");
    }

    delay(500);
}