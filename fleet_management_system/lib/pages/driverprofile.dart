import 'package:flutter/material.dart';

class DriverProfile extends StatelessWidget {
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
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('images/login2.png'), 
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Nick Harreled",
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "184/188 2nd Cross Street 11, Colombo\nSri Lanka",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: const [
                        _ProfileInfo(title: "Contact Number", value: "+94 775443456"),
                        _ProfileInfo(title: "Birth Day", value: "2000/01/12"),
                        _ProfileInfo(title: "Assigned Vehicle", value: "CHS - 7752"),
                        _ProfileInfo(title: "Gender", value: "Male"),
                      ],
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
                // Sensor Cards with blue background
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
                      children: const [
                        _InfoCard(title: "Vibration", value: "70Hz", isDark: true),
                        _InfoCard(title: "Humidity", value: "77%", isDark: true),
                        _InfoCard(title: "Remaining Fuel", value: "20L", isDark: true),
                        _InfoCard(title: "Temperature", value: "77C", isDark: true),
                        _InfoCard(title: "Speed", value: "50kmph", isDark: true),
                        _InfoCard(title: "Fuel Consumption", value: "8Km", isDark: true),
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
                        image: AssetImage('images/login2.png'), // Replace with map or another image
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

// ----------------------------

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

// ----------------------------

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