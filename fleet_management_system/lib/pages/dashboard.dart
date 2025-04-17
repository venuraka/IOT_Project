import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fleet_management_system/calculations/obd_calculations.dart';

import 'login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  BluetoothConnection? connection;
  bool isConnecting = true;
  bool isConnected = false;
  String responseText = "Connecting...";
  String engineRPM = "N/A";
  double? previousSpeed;
  DateTime? previousTime;
  String vehicleSpeed = "N/A";
  String acceleration = "N/A";
  String deceleration = "N/A";
  Timer? rpmTimer;
  Timer? speedTimer;

  String obdDeviceAddress =
      "01:23:45:67:89:BA"; // Replace with your ELM327 MAC address

  @override
  void initState() {
    super.initState();
    connectToOBDII();
  }

  Future<void> connectToOBDII() async {
    setState(() {
      isConnecting = true;
      responseText = "Connecting...";
    });

    Map<Permission, PermissionStatus> statuses =
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    if (statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
        statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.locationWhenInUse] != PermissionStatus.granted) {
      setState(() {
        responseText = "Bluetooth or Location permissions denied!";
        isConnecting = false;
      });
      return;
    }

    try {
      List<BluetoothDevice> devices =
      await FlutterBluetoothSerial.instance.getBondedDevices();

      BluetoothDevice? device = devices.firstWhere(
            (d) => d.address == obdDeviceAddress,
        orElse: () => BluetoothDevice(address: "", name: ""),
      );

      if (device.address.isEmpty) {
        setState(() {
          responseText = "OBD-II device not found!";
          isConnecting = false;
          isConnected = false;
        });
        return;
      }

      BluetoothConnection.toAddress(device.address)
          .then((_connection) {
        setState(() {
          connection = _connection;
          isConnected = true;
          isConnecting = false;
          responseText = "Connected!";
        });

        print("Connected to OBD-II");
        startListening();
        startRPMUpdates();
        startSpeedUpdates();
      })
          .catchError((error) {
        setState(() {
          responseText = "Connection failed!";
          isConnecting = false;
          isConnected = false;
        });
        print("Connection error: $error");
      });
    } catch (e) {
      setState(() {
        responseText = "Error: $e";
        isConnecting = false;
        isConnected = false;
      });
    }
  }

  void startRPMUpdates() {
    rpmTimer?.cancel();
    rpmTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (isConnected) {
        sendOBDCommand("010C");
      } else {
        timer.cancel();
      }
    });
  }

  void startSpeedUpdates() {
    speedTimer?.cancel();
    speedTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (isConnected) {
        sendOBDCommand("010D"); // Speed PID
      } else {
        timer.cancel();
      }
    });
  }

  void startListening() {
    if (connection == null || !isConnected) return;

    connection!.input!.listen((Uint8List data) {
      String rawResponse = utf8.decode(data);
      print("Raw OBD Response: $rawResponse");

      if (rawResponse.contains("41 0C")) {
        parseEngineRPMResponse(rawResponse);
      } else if (rawResponse.contains("41 0D")) {
        parseSpeedResponse(rawResponse);
      }
    });
  }

  void sendOBDCommand(String command) async {
    if (connection == null || !isConnected) {
      setState(() {
        responseText = "Not connected to OBD-II device!";
      });
      return;
    }

    String formattedCommand = command + "\r";
    connection!.output.add(Uint8List.fromList(utf8.encode(formattedCommand)));
    await connection!.output.allSent;
  }

  void parseEngineRPMResponse(String response) {
    if (!response.contains("41 0C")) return;

    List<String> hexValues = response.trim().split(" ");
    if (hexValues.length < 4) return;

    try {
      int rpmValue =
          ((int.parse(hexValues[2], radix: 16) * 256) +
              int.parse(hexValues[3], radix: 16)) ~/
              4;

      setState(() {
        engineRPM = "$rpmValue RPM";
      });
    } catch (e) {
      print("Error parsing RPM: $e");
    }
  }
  void parseSpeedResponse(String response) {
    List<String> hexValues = response.trim().split(" ");
    if (hexValues.length < 3) return;

    try {
      int speedValue = int.parse(hexValues[2], radix: 16);
      DateTime currentTime = DateTime.now();

      double accelerationValue = calculateAcceleration(
        previousSpeed,
        speedValue.toDouble(),
        previousTime,
        currentTime,
      );
      double decelerationValue = calculateDeceleration(
        previousSpeed,
        speedValue.toDouble(),
        previousTime,
        currentTime,
      );

      setState(() {
        vehicleSpeed = "$speedValue km/h";
        acceleration = "${accelerationValue.toStringAsFixed(2)} m/s²";
        deceleration = "${decelerationValue.toStringAsFixed(2)} m/s²";
        previousSpeed = speedValue.toDouble();
        previousTime = currentTime;
      });
    } catch (e) {
      print("Error parsing speed: $e");
    }
  }

  @override
  void dispose() {
    rpmTimer?.cancel();
    connection?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 25),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // const SizedBox(width: 300), // Space between text and avatar
                  PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'logout') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'logout',
                            child: Text('Logout'),
                          ),
                        ],
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/images/profile.png'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoBox("Vibration", "70Hz"),
                _buildInfoBox("Temperature", "20 C"),
                _buildInfoBox("Humidity", "77%"),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoBox("Speed", "$vehicleSpeed"),
                _buildInfoBox("RPM", "$engineRPM"),
              ],
            ),
            const SizedBox(height: 15),
            _buildInfoBox("Driver Score", "20 C", width: 120),
            const SizedBox(height: 20),
            const Text(
              "Alerts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Fire, vibrations, alcohol warnings",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Image.asset('assets/images/car.png', fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String value, {double width = 100}) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          width: width,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 45, 159),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
