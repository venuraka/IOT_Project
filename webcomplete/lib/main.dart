import 'package:flutter/material.dart';
import 'Pages/login.dart';
import 'Pages/dashboard.dart';
import 'Pages/driverprofile.dart';

void main() {

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Login Demo',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/dashboard': (context) => DashboardPage(),
        '/driver': (context) => DriverProfile(),
},
    );
  }
}