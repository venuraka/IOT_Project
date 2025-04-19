import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DriverProfile extends StatelessWidget {
  final String driverId;
  final String driverName;

  const DriverProfile({super.key, required this.driverId, required this.driverName});

  @override
  Widget build(BuildContext context) {
    // Reference to the specific driver's data in Firebase
    final databaseRef = FirebaseDatabase.instance.ref().child('DataSet/Drivers/$driverId');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
  preferredSize: Size.fromHeight(70),
  child: AppBar(
    backgroundColor: const Color(0xFF184A8C),
    leading: Padding(
      padding: const EdgeInsets.only(top: 15.0), // top margin for back button
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    title: Padding(
      padding: const EdgeInsets.only(top: 15.0), // top margin for title
      child: Text(
        "Driver Details",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    ),
  ),
),

      body: StreamBuilder(
        stream: databaseRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Handle errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // Handle no data
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('Driver data not found'));
          }

          // Extract driver data
          final driverData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final address = driverData['address']?.toString() ?? 'Not provided';
          final birthday = driverData['birthday']?.toString() ?? 'Not provided';
          final gender = driverData['gender']?.toString() ?? 'Not provided';
          final number = driverData['number']?.toString() ?? 'Not provided';
          final vehicle = driverData['vehicle']?.toString() ?? 'Not provided';
          final picUrl = driverData['pic']?.toString() ?? '';

          // Extract OBDdata
          final obdData = driverData['OBDdata'] as Map<dynamic, dynamic>? ?? {};
          print('OBD Data: $obdData');
          final vibration = obdData['Vibration']?.toString() ?? 'Not available';
          final humidity = obdData['Humidity']?.toString() ?? 'Not available';
          final remainingFuel = obdData['Remaining Fule']?.toString() ?? 'Not available';
          final temperature = obdData['Temperture']?.toString() ?? 'Not available';
          final speed = obdData['Speed']?.toString() ?? 'Not available';
          final fuelConsumption = obdData['Fuel Consumption']?.toString() ?? 'Not available';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003366),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture
                      Padding(
                        padding: const EdgeInsets.only(top: 9, left: 5),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: picUrl.isNotEmpty
                              ? NetworkImage(picUrl)
                              : const AssetImage('images/login2.png') as ImageProvider,
                          onBackgroundImageError: (_, __) => const AssetImage('images/login2.png'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Text(
                                driverName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 10,
                            children: [
                              _ProfileInfo(title: "Contact Number", value: number),
                              _ProfileInfo(title: "Birth Day", value: birthday),
                              _ProfileInfo(title: "Assigned Vehicle", value: vehicle),
                              _ProfileInfo(title: "Gender", value: gender),
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
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _InfoCard(title: "Vibration", value: vibration, isDark: true),
                            _InfoCard(title: "Humidity", value: humidity, isDark: true),
                            _InfoCard(title: "Remaining Fuel", value: remainingFuel, isDark: true),
                            _InfoCard(title: "Temperature", value: temperature, isDark: true),
                            _InfoCard(title: "Speed", value: speed, isDark: true),
                            _InfoCard(title: "Fuel Consumption", value: fuelConsumption, isDark: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Map Container
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
          );
        },
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
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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