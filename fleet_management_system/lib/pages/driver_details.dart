// driver_details.dart
import 'package:flutter/material.dart';

class DriverDetailsScreen extends StatelessWidget {
  const DriverDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Driver Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Image
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(75),
              child: Image.asset(
                'assets/images/driver_profile.jpg',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Driver Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                _buildDetailRow('Name', 'Don Jhon'),
                _buildDetailRow('Age', '20'),
                _buildDetailRow('License Number', '2002273019'),
                _buildDetailRow('Blood Type', 'A+'),
                _buildDetailRow('Driving Score', 'NO'),
                _buildDetailRow('Vehicle Score', '100'),
              ],
            ),
          ),
          const Spacer(),
          // Bottom Navigation
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white, size: 30),
                  onPressed: () {},
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(Icons.person, color: Colors.blue, size: 30),
                ),
                IconButton(
                  icon: const Icon(Icons.info, color: Colors.white, size: 30),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
