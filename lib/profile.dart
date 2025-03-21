import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Driver profile',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            
            // Profile Picture - Circular
            const CircleAvatar(
              radius: 50, // Adjust the size
              backgroundImage: AssetImage('images/profile.png'),
            ),

            const SizedBox(height: 20),
            _buildDetailRow('Name', 'John Watson'),
            _buildDetailRow('Age', '30'),
            _buildDetailRow('License number', 'CBB 6492'),
            _buildDetailRow('Blood type', 'O+'),
            _buildDetailRow('Driving Score', '90'),
            _buildDetailRow('Vehicle Score', '100'),

            const Divider(color: Colors.white),
            const Divider(color: Colors.white),
            
            ElevatedButton(
              onPressed: () {
                debugPrint('View History clicked');
              },
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
