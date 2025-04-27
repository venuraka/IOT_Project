import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DriverProfile extends StatefulWidget {
  final Map<String, String> driverData;

  const DriverProfile({required this.driverData});

  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  double? tempThreshold;
  double? humidityThreshold;
  bool tempAlertShown = false;
  bool humidityAlertShown = false;

  @override
  void initState() {
    print('Driver Data: ${widget.driverData}');
    super.initState();
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
          "Driver Details",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Info Section
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
                                double.parse(alcoholRaw.toString()) > 0.08;

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
                                    tempVal < tempThreshold! - 5);

                            final isHumidityWarning =
                                humidityThreshold != null &&
                                humidityVal != null &&
                                (humidityVal > humidityThreshold! ||
                                    humidityVal < humidityThreshold! - 5);

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

                            // MQ135 Smoke Status
                            final mq135RawValue = data['mq135']?['rawValue'];
                            final mq135Status =
                                mq135RawValue?.toString() ?? 'N/A';

                            final double? smokeValue = double.tryParse(
                              mq135Status,
                            );
                            final bool isSmokeWarning =
                                smokeValue != null &&
                                smokeValue > 300; // Adjust threshold

                            // Show alert when smoke level is high
                            if (isSmokeWarning) {
                              Future.microtask(() {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Smoke Warning!'),
                                        content: Text(
                                          'High smoke levels detected! ($mq135Status)',
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
                                ),
                                _InfoCard(
                                  title: 'Smoke Status',
                                  value: mq135Status,
                                  isDark: true,
                                  isWarning: isSmokeWarning,
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
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: FloatingActionButton(
                            onPressed: () {
                              final tempController = TextEditingController();
                              final humidityController =
                                  TextEditingController();

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
                Expanded(
                  child: Container(
                    height: 470,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('images/login2.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
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
                      ? Colors.redAccent
                      : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
