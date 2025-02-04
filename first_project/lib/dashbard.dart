import 'package:flutter/material.dart';

class Driver {
  final String name;
  final String status;

  Driver({required this.name, required this.status});
}

class Dashbard extends StatelessWidget {
  const Dashbard({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample list of drivers
    final List<Driver> drivers = [
      Driver(name: 'John Doe', status: 'Available'),
      Driver(name: 'Jane Smith', status: 'Busy'),
      Driver(name: 'Alice Johnson', status: 'Available'),
      Driver(name: 'Bob Brown', status: 'Offline'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF10316B),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Text(
            'View Drivers Here',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10316B),
            ),
          ),
          const SizedBox(height: 50),
          Container(
            // Table Header
            color: const Color(0xFF10316B),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16.0),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Driver Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Status',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(width: 50), // Placeholder for the "More" button column
              ],
            ),
          ),
          const SizedBox(height: 40),
          // List of Drivers
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return Card(
                  elevation: 2, //Adds a shadow to the card
                  margin: const EdgeInsets.only(
                      bottom:
                          10), //Adds a bottom margin of 10 to create space between cards
                  color: Color(0xFFD9D9D9),
                  child: Padding(
                    padding: const EdgeInsets.all(
                        16.0), //adds padding (16.0 on all sides) inside the Card
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          driver.name,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          driver.status,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  const Color(0xFF10316B))),
                          onPressed: () {
                            // Navigate to driver details page
                          },
                          child: const Text('More',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
