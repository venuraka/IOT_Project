import 'package:fleet_management_system/pages/OBD_speed.dart';
import 'package:fleet_management_system/pages/driver_details.dart';
import 'package:fleet_management_system/pages/home.dart';
import 'package:fleet_management_system/pages/login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/home',
      routes: {
        '/login': (context) => LoginScreen(), // Manodya
        '/home': (context) => HomeScreen(), //
        '/driverDetails': (context) => DriverDetailsScreen(), // Ayeshi
        '/speed': (context) => SpeedPage(), //
      },
    );
  }
}
