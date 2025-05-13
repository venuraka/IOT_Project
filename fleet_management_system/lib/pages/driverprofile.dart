import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DriverProfile extends StatefulWidget {
  final Map<String, String> driverData;

  const DriverProfile({required this.driverData});

  @override
  State<DriverProfile> createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
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
        title: const Text("Driver Details", style: TextStyle(color: Colors.white)),
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
                            value: widget.driverData['contact'] ?? '+94 775443456',
                          ),
                          _ProfileInfo(
                            title: 'Birth Day',
                            value: widget.driverData['birthday'] ?? '2000/01/12',
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
                    child: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance.ref('sensors').onValue,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Error loading sensor data',
                                  style: TextStyle(color: Colors.white)));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
                        if (data == null) {
                          return const Center(
                              child: Text('No sensor data available',
                                  style: TextStyle(color: Colors.white)));
                        }

                        // Map the fetched data to the UI cards
                        final alcoholPercentage = data['alcohol']?['percentage']?.toString() ?? 'N/A';
                        final dhtHumidity = data['dht']?['humidity']?.toString() ?? 'N/A';
                        final dhtTemperature = data['dht']?['temperature']?.toString() ?? 'N/A';
                        final flameStatus = data['flame']?['status']?.toString() ?? 'N/A';
                        final mq135Status = data['mq135']?['rawValue']?.toString() ?? 'N/A';
                        final vibrationCount = data['vibration']?['count']?.toString() ?? 'N/A';
                        final ultrasonicBackLeft = data['ultrasonic']?['backLeft']?['status']?.toString() ?? 'N/A';
                        final ultrasonicFrontLeft = data['ultrasonic']?['frontLeft']?['status']?.toString() ?? 'N/A';
                        final ultrasonicFrontRight = data['ultrasonic']?['frontRight']?['status']?.toString() ?? 'N/A';
                        final ultrasonicBackRight = data['ultrasonic']?['backRight']?['status']?.toString() ?? 'N/A';


                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _InfoCard(
                                title: 'Alcohol Percentage',
                                value: '$alcoholPercentage%',
                                isDark: true),
                            _InfoCard(
                                title: 'Humidity',
                                value: '$dhtHumidity%',
                                isDark: true),
                            _InfoCard(
                                title: 'Temperature',
                                value: '$dhtTemperature°C',
                                isDark: true),
                            _InfoCard(
                                title: 'Fire Status',
                                value: flameStatus,
                                isDark: true),
                            _InfoCard(
                                title: 'Smoke Status',
                                value: mq135Status,
                                isDark: true),
                            _InfoCard(
                                title: 'Vibration',
                                value: vibrationCount,
                                isDark: true),
                            _InfoCard(
                                title: 'BackLeft Distance',
                                value: ultrasonicBackLeft,
                                isDark: true),
                            _InfoCard(
                                title: 'Frontleft Distance',
                                value: ultrasonicFrontLeft,
                                isDark: true),
                            _InfoCard(
                                title: 'FrontRight Distance',
                                value: ultrasonicFrontRight,
                                isDark: true),
                            _InfoCard(
                                title: 'BackRight Distance',
                                value: ultrasonicBackRight,
                                isDark: true),
                            
                          ],
                        );
                      },
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
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;

  const _InfoCard({required this.title, required this.value, this.isDark = false});

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
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}