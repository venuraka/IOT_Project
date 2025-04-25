import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driverprofile.dart'; // Import the DriverProfile page

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<DocumentSnapshot> _drivers = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      print('Fetching drivers from Firestore...');
      final snapshot = await FirebaseFirestore.instance.collection('Drivers').get();
      print('Fetched ${snapshot.docs.length} drivers');
      setState(() {
        _drivers = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching drivers: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      Navigator.pop(context);
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
            const Text(
              "View Drivers Here",
              style: TextStyle(color: Color(0xFF184A8C), fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),
            // Table Header
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
            // Driver List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchDrivers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
                  : _drivers.isEmpty
                  ? const Center(child: Text('No drivers found'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _drivers.length,
                itemBuilder: (context, index) {
                  final driver = _drivers[index];
                  final name = driver['name'] as String? ?? 'Unknown';
                  final status = driver['dstatus'] as String? ?? 'Unknown';
                  return driverRow(context, name, status, driver);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget driverRow(BuildContext context, String name, String status, DocumentSnapshot driver) {
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
                print(driver);
                final driverData = {
                  'name': driver['name'] as String? ?? 'Unknown',
                  'address': driver['daddress'] as String? ?? 'Not provided',
                  'contact': (driver['dcontactnumber'] as num?)?.toString() ?? 'Not provided',
                  'birthday': driver['dbirthday'] as String? ?? 'Not provided',
                  'vehicle': driver['dvehicle'] as String? ?? 'Not provided',
                  'gender': driver['dgender'] as String? ?? 'Not provided',
                };
                // Navigate using MaterialPageRoute
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverProfile(driverData: driverData),
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