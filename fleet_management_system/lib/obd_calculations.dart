import 'dart:core';

double calculateAcceleration(double? previousSpeed, double currentSpeed, DateTime? previousTime, DateTime currentTime) {
  if (previousSpeed == null || previousTime == null) {
    return 0.0; // No acceleration available initially
  }

  double deltaV = currentSpeed - previousSpeed; // Change in speed
  double deltaT = currentTime.difference(previousTime).inMilliseconds / 1000.0; // Time in seconds

  return deltaT > 0 ? deltaV / deltaT : 0.0; // Acceleration (m/s²)
}

double calculateDeceleration(double? previousSpeed, double currentSpeed, DateTime? previousTime, DateTime currentTime) {
  double acceleration = calculateAcceleration(previousSpeed, currentSpeed, previousTime, currentTime);
  return acceleration < 0 ? acceleration.abs() : 0.0; // Only return positive deceleration values
}