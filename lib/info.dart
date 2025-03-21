import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const int itemCount = 10;

class VehicleInfo extends StatelessWidget {
  const VehicleInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        children: [
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Vehicle Info',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'images/truck.jpg',
              width: 250,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Name', 'Chiller Truck 6492'),
          _buildDetailRow('Number', 'CBB 6492'),
          _buildDetailRow('Next Service', '100 KM'),
          _buildDetailRow('License Number', '200138913'),
          _buildDetailRow('Accident Detected', 'None'),
          _buildDetailRow('Vehicle Score', '100'),
          const Divider(color: Colors.white),
          const Divider(color: Colors.white),
          ElevatedButton(
            onPressed: () {
              debugPrint('somethingg');
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
