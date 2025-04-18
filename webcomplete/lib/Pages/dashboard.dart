import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF2F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Color(0xFF184A8C),
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Text(
                    'DASHBOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Go back to login
                    },
                    icon: Icon(Icons.logout, color: Colors.white),
                    label: Text(
                      "Logout",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              "View Drivers Here",
              style: TextStyle(color: Color(0xFF184A8C), fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                color: Color(0xFF184A8C),
                child: Row(
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
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  driverRow(context, "John Doe", "Available"),
                  driverRow(context, "Jane Smith", "Busy"),
                  driverRow(context, "Alice Johnson", "Available"),
                  driverRow(context, "Bob Brown", "Offline"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👇 IMPORTANT: pass 'BuildContext context' here
  Widget driverRow(BuildContext context, String name, String status) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Text(name, style: TextStyle(fontSize: 16)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Text(status, style: TextStyle(fontSize: 16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF184A8C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/driver'); // ✅ Navigate to DriverProfile
              },
              child: Text("More", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
