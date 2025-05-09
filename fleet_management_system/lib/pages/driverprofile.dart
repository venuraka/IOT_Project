import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverProfile extends StatefulWidget {
  final Map<String, String> driverData;

  const DriverProfile({Key? key, required this.driverData})
    : super(key: key); // Added Key? key

  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  double? tempThreshold;
  double? humidityThreshold;
  bool tempAlertShown = false;
  bool humidityAlertShown = false;
  // Keep the flag for the smoke status alert
  bool smokeStatusAlertShown = false;

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {}; // Set to hold markers

  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref(
    'sensors/gps',
  );

  StreamSubscription? _gpsLocationSubscription;

  @override
  void initState() {
    super.initState();
    print('Driver Data: ${widget.driverData}');
    _listenToGpsLocation();
  }

  @override
  void dispose() {
    _gpsLocationSubscription?.cancel();
    super.dispose();
  }

  void _listenToGpsLocation() {
    _gpsLocationSubscription = databaseRef.onValue.listen(
      (event) {
        final dataSnapshot = event.snapshot;

        if (dataSnapshot.value != null) {
          print('GPS Data received: ${dataSnapshot.value}'); // Debug print

          Map<dynamic, dynamic>? locationData =
              dataSnapshot.value as Map<dynamic, dynamic>?;

          if (locationData != null) {
            double? latitude = double.tryParse(
              locationData['latitude'].toString(),
            );
            double? longitude = double.tryParse(
              locationData['longitude'].toString(),
            );

            print(
              'Parsed location: Lat: $latitude, Lng: $longitude',
            ); // Debug print

            if (latitude != null && longitude != null) {
              // Create a new marker
              final updatedMarkers = <Marker>{
                Marker(
                  markerId: const MarkerId('current_gps_location'),
                  position: LatLng(latitude, longitude),
                  infoWindow: InfoWindow(
                    title: 'Current Vehicle Location',
                    snippet: 'Lat: $latitude, Lng: $longitude',
                  ),
                  icon: BitmapDescriptor.defaultMarker,
                ),
              };

              // Update the state
              setState(() {
                _markers = updatedMarkers;
              });

              // Move camera to the location - with better error handling
              _controller.future
                  .then((controller) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(latitude, longitude),
                        15.0, // Higher zoom level for better visibility
                      ),
                    );
                  })
                  .catchError((error) {
                    print('Error moving camera: $error');
                  });
            }
          }
        } else {
          print('No GPS location data available');
        }
      },
      onError: (error) {
        print('Error fetching GPS location: $error');
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Driver Details", // Keep this title if this screen is primarily for driver details
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Info Section (Keep this if you still want to show driver info)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF003366),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('images/login2.png'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driverData['name'] ?? 'Nick Harreled',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.driverData['address'] ??
                              '184/188 2nd Cross Street 11, Colombo\nSri Lanka',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Expanded(
                      flex: 2,
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          _ProfileInfo(
                            title: 'Contact Number',
                            value:
                                widget.driverData['contact'] ?? '+94 775443456',
                          ),
                          _ProfileInfo(
                            title: 'Birth Day',
                            value:
                                widget.driverData['birthday'] ?? '2000/01/12',
                          ),
                          _ProfileInfo(
                            title: 'Assigned Vehicle',
                            value: widget.driverData['vehicle'] ?? 'CHS - 7752',
                          ),
                          _ProfileInfo(
                            title: 'Gender',
                            value: widget.driverData['gender'] ?? 'Male',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Sensor Data and Map
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sensor Data Section (Keep this if needed)
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 470,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        StreamBuilder<DatabaseEvent>(
                          stream:
                              FirebaseDatabase.instance.ref('sensors').onValue,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Center(
                                child: Text(
                                  'Error loading sensor data',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final data =
                                snapshot.data?.snapshot.value
                                    as Map<dynamic, dynamic>?;
                            if (data == null) {
                              return const Center(
                                child: Text(
                                  'No sensor data available',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            // Alcohol
                            final alcoholRaw = data['alcohol']?['percentage'];
                            final alcoholPercentage =
                                alcoholRaw?.toString() ?? 'N/A';
                            final isAlcoholHigh =
                                alcoholRaw != null &&
                                double.tryParse(alcoholRaw.toString()) !=
                                    null &&
                                double.parse(alcoholRaw.toString()) > 100;

                            if (isAlcoholHigh) {
                              Future.microtask(() {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Warning!'),
                                        content: const Text(
                                          'High alcohol level detected!',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                              });
                            }

                            // Humidity and Temperature
                            final dhtHumidity =
                                data['dht']?['humidity']?.toString() ?? 'N/A';
                            final dhtTemperature =
                                data['dht']?['temperature']?.toString() ??
                                'N/A';

                            final tempVal = double.tryParse(dhtTemperature);
                            final humidityVal = double.tryParse(dhtHumidity);

                            final isTempWarning =
                                tempThreshold != null &&
                                tempVal != null &&
                                (tempVal > tempThreshold! ||
                                    tempVal <
                                        tempThreshold! - 5); // Check range

                            final isHumidityWarning =
                                humidityThreshold != null &&
                                humidityVal != null &&
                                (humidityVal > humidityThreshold! ||
                                    humidityVal <
                                        humidityThreshold! - 5); // Check range

                            // Temperature Alert
                            if (isTempWarning && !tempAlertShown) {
                              tempAlertShown = true;
                              Future.microtask(() {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text(
                                          'Temperature Warning!',
                                        ),
                                        content: Text(
                                          'Temperature is out of safe range! (Set: ${tempThreshold}°C)',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                              });
                            } else if (!isTempWarning) {
                              tempAlertShown = false;
                            }

                            // Humidity Alert
                            if (isHumidityWarning && !humidityAlertShown) {
                              humidityAlertShown = true;
                              Future.microtask(() {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Humidity Warning!'),
                                        content: Text(
                                          'Humidity is out of safe range! (Set: ${humidityThreshold}%)',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                              });
                            } else if (!isHumidityWarning) {
                              humidityAlertShown = false;
                            }

                            final flameStatus =
                                data['flame']?['status']?.toString() ?? 'N/A';

                            final isFlameDetected =
                                flameStatus.toLowerCase() == 'flame detected';

                            if (isFlameDetected) {
                              Future.microtask(() {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Fire Warning!'),
                                        content: const Text(
                                          'Flame detected! Immediate action required!',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                              });
                            }

                            // MQ135 Smoke Status based on 'status' field
                            final smokeData = data['smoke'];
                            final smokeStatus =
                                smokeData?['status']?.toString() ?? 'N/A';
                            final smokeValue =
                                smokeData?['value']?.toString() ??
                                'N/A'; // Get the raw value as well

                            final isSmokeStatusDetected =
                                smokeStatus == 'SM0KE DETECTED';

                            // Show alert when smoke status is 'SM0KE DETECTED' and alert hasn't been shown
                            if (isSmokeStatusDetected &&
                                !smokeStatusAlertShown) {
                              smokeStatusAlertShown = true; // Set flag
                              Future.microtask(() {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Smoke Detected!'),
                                        content: Text(
                                          'Smoke detected! Status: $smokeStatus (Value: $smokeValue)',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                              });
                            } else if (!isSmokeStatusDetected) {
                              // Reset the flag when the status is no longer 'SM0KE DETECTED'
                              smokeStatusAlertShown = false;
                            }

                            final vibrationCount =
                                data['vibration']?['count']?.toString() ??
                                'N/A';
                            final ultrasonicBackLeft =
                                data['ultrasonic']?['backLeft']?['status']
                                    ?.toString() ??
                                'N/A';
                            final ultrasonicFrontLeft =
                                data['ultrasonic']?['frontLeft']?['status']
                                    ?.toString() ??
                                'N/A';
                            final ultrasonicFrontRight =
                                data['ultrasonic']?['frontRight']?['status']
                                    ?.toString() ??
                                'N/A';
                            final ultrasonicBackRight =
                                data['ultrasonic']?['backRight']?['status']
                                    ?.toString() ??
                                'N/A';

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _InfoCard(
                                  title: 'Alcohol Percentage',
                                  value: '$alcoholPercentage%',
                                  isDark: true,
                                  isWarning: isAlcoholHigh,
                                ),
                                _InfoCard(
                                  title: 'Humidity',
                                  value: '$dhtHumidity%',
                                  isDark: true,
                                  isWarning: isHumidityWarning,
                                ),
                                _InfoCard(
                                  title: 'Temperature',
                                  value: '$dhtTemperature°C',
                                  isDark: true,
                                  isWarning: isTempWarning,
                                ),
                                _InfoCard(
                                  title: 'Fire Status',
                                  value: flameStatus,
                                  isDark: true,
                                  isWarning:
                                      isFlameDetected, // Indicate warning for flame
                                ),
                                _InfoCard(
                                  title:
                                      'Smoke Status', // Displaying the status field
                                  value: smokeStatus,
                                  isDark: true,
                                  isWarning:
                                      isSmokeStatusDetected, // Use the status for warning
                                ),
                                _InfoCard(
                                  title:
                                      'Smoke Raw Value', // Optionally display the raw value as well
                                  value: smokeValue,
                                  isDark: true,
                                ),
                                _InfoCard(
                                  title: 'Vibration',
                                  value: vibrationCount,
                                  isDark: true,
                                ),
                                _InfoCard(
                                  title: 'BackLeft Distance',
                                  value: ultrasonicBackLeft,
                                  isDark: true,
                                ),
                                _InfoCard(
                                  title: 'FrontLeft Distance',
                                  value: ultrasonicFrontLeft,
                                  isDark: true,
                                ),
                                _InfoCard(
                                  title: 'FrontRight Distance',
                                  value: ultrasonicFrontRight,
                                  isDark: true,
                                ),
                                _InfoCard(
                                  title: 'BackRight Distance',
                                  value: ultrasonicBackRight,
                                  isDark: true,
                                ),
                              ],
                            );
                          },
                        ),
                        // Positioned FAB for setting thresholds
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: FloatingActionButton(
                            onPressed: () {
                              final tempController = TextEditingController(
                                text: tempThreshold?.toString() ?? '',
                              );
                              final humidityController = TextEditingController(
                                text: humidityThreshold?.toString() ?? '',
                              );

                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Set Thresholds'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: tempController,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Temperature Threshold (°C)',
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                          TextField(
                                            controller: humidityController,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Humidity Threshold (%)',
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              tempThreshold = double.tryParse(
                                                tempController.text,
                                              );
                                              humidityThreshold =
                                                  double.tryParse(
                                                    humidityController.text,
                                                  );
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: const Icon(Icons.settings),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Map Section
                Expanded(
                  child: Container(
                    height: 470,
                    decoration: BoxDecoration(
                      // Keep decoration for border radius
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // --- GoogleMap Widget ---
                    child: GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(6.9271, 79.8612),
                        zoom: 10, // More reasonable initial zoom
                      ),
                      onMapCreated: _onMapCreated,
                      markers: _markers,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                    ),
                    // --- End GoogleMap Widget ---
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Keep the _ProfileInfo and _InfoCard widgets as they are
class _ProfileInfo extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileInfo({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;
  final bool isWarning;

  const _InfoCard({
    required this.title,
    required this.value,
    this.isDark = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A4D7A) : const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color:
                  isWarning
                      ? Colors
                          .redAccent // Use red for warnings
                      : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
