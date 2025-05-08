import 'dart:core';

double calculateAcceleration(
  double? previousSpeed,
  double currentSpeed,
  DateTime? previousTime,
  DateTime currentTime,
) {
  if (previousSpeed == null || previousTime == null) {
    return 0.0; // No acceleration available initially
  }

  double deltaV = currentSpeed - previousSpeed; // Change in speed
  double deltaT =
      currentTime.difference(previousTime).inMilliseconds /
      1000.0; // Time in seconds

  return deltaT > 0 ? deltaV / deltaT : 0.0; // Acceleration (m/s²)
}

double calculateDeceleration(
    double? previousSpeed,
    double currentSpeed,
    DateTime? previousTime,
    DateTime currentTime,
    ) {
  if (previousSpeed == null || previousTime == null) {
    return 0.0;
  }

  // Direct calculation for deceleration instead of reusing acceleration function
  double speedDifference = previousSpeed - currentSpeed;

  // If speed is decreasing (positive difference)
  if (speedDifference > 0) {
    double deltaT = currentTime.difference(previousTime).inMilliseconds / 1000.0;

    // Avoid division by extremely small time differences
    if (deltaT < 0.05) deltaT = 0.05;

    return speedDifference / deltaT;
  }

  return 0.0; // No deceleration
}
