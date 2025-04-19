import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'driverprofile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Reference to the Firebase database
    // This is where the driver data is stored
    final databaseRef = FirebaseDatabase.instance.ref().child('DataSet/Drivers');

    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and logout button
            Container(
              color: const Color(0xFF184A8C),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Text(
                    'DASHBOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Go back to login
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Section title
            const Text(
              "View Drivers Here",
              style: TextStyle(
                color: Color(0xFF184A8C),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            // Table header for driver list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                color: const Color(0xFF184A8C),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Text(
                          "Driver Name",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Text(
                          "Status",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(width: 80),
                  ],
                ),
              ),
            ),
            // Dynamic list of drivers fetched from Firebase
            // This will update in real-time as data changes
            Expanded(
              child: StreamBuilder(
                stream: databaseRef.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  // Show loading indicator while waiting for data
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Handle errors
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  // Handle no data or null value
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text('No drivers found'));
                  }

                  // Cast the data to a Map
                  final driversMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  final driversList = driversMap.entries.map((entry) {
                    final driverId = entry.key.toString();
                    final driverData = entry.value as Map<dynamic, dynamic>;
                    return {
                      'id': driverId,
                      'name': driverData['name']?.toString() ?? 'Unknown',
                      'status': driverData['status']?.toString() ?? 'Unknown',
                    };
                  }).toList();

                  // Build the ListView dynamically
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: driversList.length,
                    itemBuilder: (context, index) {
                      final driver = driversList[index];
                      return driverRow(
                        context,
                        driver['id']!,
                        driver['name']!,
                        driver['status']!,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget driverRow(BuildContext context, String driverId, String name, String status) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Text(name, style: const TextStyle(fontSize: 16)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Text(status, style: const TextStyle(fontSize: 16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF184A8C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverProfile(
                      driverId: driverId,
                      driverName: name,
                    ),
                  ),
                );
              },
              child: const Text("More", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}