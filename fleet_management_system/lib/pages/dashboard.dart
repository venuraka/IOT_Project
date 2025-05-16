import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fleet_management_system/calculations/obd_calculations.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String vehicleSpeed = "N/A";
  String acceleration = "N/A";
  String deceleration = "N/A";
  String fuelConsumption = "N/A"; // Instant fuel rate
  String totalFuelConsumption = "0.00 L"; // Total fuel consumption

  double? previousSpeed;
  DateTime? previousTime;
  double _totalFuelUsed = 0.0; // Stores total fuel used in liters
  double _lastFuelRate = 0.0; // Last recorded fuel rate in L/h
  DateTime? _lastFuelUpdateTime; // Last time fuel rate was updated

  Timer? rpmTimer;
  Timer? speedTimer;
  Timer? fuelTimer;
  Timer? totalFuelTimer; // Timer for updating total fuel consumption
  String? temporaryAlertMessage;
  Timer? alertTimer;

  double? ultrasonicBackLeft;
  double? ultrasonicFrontLeft;
  double? ultrasonicFrontRight;
  double? ultrasonicBackRight;

  double? tempThreshold;
  double? humidityThreshold;
  bool tempAlertShown = false;
  bool humidityAlertShown = false;
  bool smokeStatusAlertShown = false;

  String obdDeviceAddress = "01:23:45:67:89:BA";

  @override
  void initState() {
    super.initState();
    _loadSavedFuelData();
    connectToOBDII();
  }

  // Load saved total fuel consumption
  Future<void> _loadSavedFuelData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _totalFuelUsed = prefs.getDouble('totalFuelUsed') ?? 0.0;
        totalFuelConsumption = "${_totalFuelUsed.toStringAsFixed(2)} L";
      });
    } catch (e) {
      print("Error loading saved fuel data: $e");
    }
  }

  // Save total fuel consumption
  Future<void> _saveFuelData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('totalFuelUsed', _totalFuelUsed);
    } catch (e) {
      print("Error saving fuel data: $e");
    }
  }

  Future<void> connectToOBDII() async {
    setState(() {
      isConnecting = true;
      responseText = "Connecting...";
    });

    var statuses =
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    if (statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
        statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.locationWhenInUse] != PermissionStatus.granted) {
      setState(() => isConnecting = false);
      showTemporaryAlert("Bluetooth or Location permissions denied!");
      return;
    }

    try {
      var devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      var device = devices.firstWhere(
        (d) => d.address == obdDeviceAddress,
        orElse: () => BluetoothDevice(address: "", name: ""),
      );

      if (device.address.isEmpty) {
        setState(() {
          isConnecting = false;
          isConnected = false;
        });
        showTemporaryAlert("OBD-II device not found!");
        return;
      }

      BluetoothConnection.toAddress(device.address)
          .then((_conn) {
            setState(() {
              connection = _conn;
              isConnected = true;
              isConnecting = false;
            });
            showTemporaryAlert("Connected to OBD device Successfully");

            startListening();
            startRPMUpdates();
            startSpeedUpdates();
            startFuelConsumptionUpdates();
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
    rpmTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (isConnected)
        sendOBDCommand("010C");
      else
        t.cancel();
    });
  }

  void startSpeedUpdates() {
    speedTimer?.cancel();
    speedTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (isConnected)
        sendOBDCommand("010D");
      else
        t.cancel();
    });
  }

  void startFuelConsumptionUpdates() {
    fuelTimer?.cancel();
    fuelTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (isConnected)
        sendOBDCommand("015E");
      else
        t.cancel();
    });
  }

  // Start timer for updating total fuel consumption
  void startTotalFuelCalculation() {
    totalFuelTimer?.cancel();
    _lastFuelUpdateTime = DateTime.now();
    totalFuelTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (isConnected) {
        _updateTotalFuelConsumption();
      } else {
        t.cancel();
      }
    });
  }

  // Calculate and update total fuel consumption
  void _updateTotalFuelConsumption() {
    if (_lastFuelUpdateTime == null || _lastFuelRate <= 0) return;

    final now = DateTime.now();
    final duration = now.difference(_lastFuelUpdateTime!).inMilliseconds / 3600000; // Convert to hours

    // Calculate fuel used in this interval (L/h * h = L)
    final fuelUsedInInterval = _lastFuelRate * duration;

    setState(() {
      _totalFuelUsed += fuelUsedInInterval;
      totalFuelConsumption = "${_totalFuelUsed.toStringAsFixed(2)} L";
    });

    _lastFuelUpdateTime = now;
    _saveFuelData(); // Save the updated total fuel consumption
  }

  // Reset total fuel consumption
  void resetTotalFuelConsumption() {
    setState(() {
      _totalFuelUsed = 0.0;
      totalFuelConsumption = "${_totalFuelUsed.toStringAsFixed(2)} L";
    });
    _saveFuelData();
    showTemporaryAlert("Total fuel consumption reset");
  }

  void startListening() {
    if (connection == null || !isConnected) return;
    connection!.input!.listen((Uint8List data) {
      var raw = utf8.decode(data);
      if (raw.contains("41 0C")) parseEngineRPMResponse(raw);
      if (raw.contains("41 0D")) parseSpeedResponse(raw);
      if (raw.contains("41 5E")) parseFuelConsumptionResponse(raw);
    });
  }

  void sendOBDCommand(String cmd) async {
    if (connection == null || !isConnected) {
      setState(() => responseText = "Not connected to OBD-II device!");
      return;
    }
    var full = cmd + "\r";
    connection!.output.add(Uint8List.fromList(utf8.encode(full)));
    await connection!.output.allSent;
  }

  void parseEngineRPMResponse(String res) {
    var parts = res.trim().split(' ');
    if (parts.length < 4) return;
    try {
      var rpm =
          ((int.parse(parts[2], radix: 16) * 256) +
              int.parse(parts[3], radix: 16)) ~/
          4;
      setState(() => engineRPM = "$rpm RPM");
    } catch (_) {}
  }

  void parseSpeedResponse(String res) {
    var parts = res.trim().split(' ');
    if (parts.length < 3) return;
    try {
      var sp = int.parse(parts[2], radix: 16).toDouble();
      var now = DateTime.now();
      var accVal = calculateAcceleration(previousSpeed, sp, previousTime, now);
      var decVal = calculateDeceleration(previousSpeed, sp, previousTime, now);
      setState(() {
        vehicleSpeed = "${sp.toInt()} km/h";
        acceleration = "${accVal.toStringAsFixed(2)} m/s²";
        deceleration = "${decVal.toStringAsFixed(2)} m/s²";
        previousSpeed = sp;
        previousTime = now;
      });
    } catch (_) {}
  }

  void parseFuelConsumptionResponse(String res) {
    var parts = res.trim().split(' ');
    if (parts.length < 4) return;
    try {
      var A = int.parse(parts[2], radix: 16);
      var B = int.parse(parts[3], radix: 16);
      var rate = ((A * 256) + B) / 20.0;
      setState(() {
        fuelConsumption = "${rate.toStringAsFixed(2)} L/h";
        _lastFuelRate = rate;
        if (_lastFuelUpdateTime == null) _lastFuelUpdateTime = DateTime.now();

        print("fuel consumption: $fuelConsumption");
      });
    } catch (_) {}
  }

  void showTemporaryAlert(String msg) {
    setState(() => temporaryAlertMessage = msg);
    alertTimer?.cancel();
    alertTimer = Timer(const Duration(seconds: 5), () {
      setState(() => temporaryAlertMessage = null);
    });
  }

  String _getDriverStatus() {
    if (!isConnected) return "Disconnected";
    var acc = double.tryParse(acceleration.replaceAll(" m/s²", "")) ?? 0;
    var dec = double.tryParse(deceleration.replaceAll(" m/s²", "")) ?? 0;
    if (acc > 2.5) return "Accelerating: ${acc.toStringAsFixed(2)} m/s²";
    if (dec > 1.5) return "Decelerating: ${dec.toStringAsFixed(2)} m/s²";
    return "Smooth Driving";
  }

  Color _getDriverStatusColor(String v) {
    if (v.contains("Accelerating")) return Colors.green;
    if (v.contains("Decelerating")) return Colors.red;
    if (v == "Disconnected") return Colors.grey;
    return const Color.fromARGB(255, 15, 92, 239);
  }

  @override
  void dispose() {
    rpmTimer?.cancel();
    speedTimer?.cancel();
    fuelTimer?.cancel();
    totalFuelTimer?.cancel();
    connection?.dispose();
    alertTimer?.cancel();
    _saveFuelData(); // Save fuel data when disposing
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton(
                  onSelected: (v) {
                    if (v == 'logout')
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (c) => LoginScreen()),
                      );
                    if (v == 'reset_fuel')
                      resetTotalFuelConsumption();
                  },
                  itemBuilder: (c) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                    const PopupMenuItem(
                      value: 'reset_fuel',
                      child: Text('Reset Fuel Consumption'),
                    ),
                  ],
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage("assets/images/profile.png"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('sensors').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading sensor data',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                // if (snapshot.connectionState ==
                //     ConnectionState.waiting) {
                //   return const Center(
                //     child: CircularProgressIndicator(),
                //   );
                // }
                final data =
                    snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
                if (data == null) {
                  return const Center(
                    child: Text(
                      'No sensor data available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Humidity and Temperature
                final dhtHumidity =
                    data['dht']?['humidity']?.toString() ?? 'N/A';
                final dhtTemperature =
                    data['dht']?['temperature']?.toString() ?? 'N/A';

                final tempVal = double.tryParse(dhtTemperature);
                final humidityVal = double.tryParse(dhtHumidity);

                final isTempWarning =
                    tempThreshold != null &&
                    tempVal != null &&
                    (tempVal > tempThreshold! ||
                        tempVal < tempThreshold! - 5); // Check range

                final isHumidityWarning =
                    humidityThreshold != null &&
                    humidityVal != null &&
                    (humidityVal > humidityThreshold! ||
                        humidityVal < humidityThreshold! - 5); // Check range

                // Temperature Alert
                if (isTempWarning && !tempAlertShown) {
                  tempAlertShown = true;
                  Future.microtask(() {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Temperature Warning!'),
                            content: Text(
                              'Temperature is out of safe range! (Set: ${tempThreshold}°C)',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  });
                } else if (!isTempWarning) {
                  tempAlertShown = false;
                }

                // Humidity Alert
                if (isHumidityWarning && !humidityAlertShown) {
                  humidityAlertShown = true;
                  Future.microtask(() {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Humidity Warning!'),
                            content: Text(
                              'Humidity is out of safe range! (Set: ${humidityThreshold}%)',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  });
                } else if (!isHumidityWarning) {
                  humidityAlertShown = false;
                }

                final flameStatus =
                    data['flame']?['status']?.toString() ?? 'N/A';

                final bool isFlameDetected =
                    flameStatus.toLowerCase() == 'flame detected.';

                if (isFlameDetected) {
                  Future.microtask(() {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Fire Warning!'),
                            content: const Text(
                              'Flame detected! Immediate action required!',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  });
                }

                // MQ135 Smoke Status based on 'status' field
                final smokeData = data['smoke'];
                final smokeStatus = smokeData?['status']?.toString() ?? 'N/A';
                final smokeValue =
                    smokeData?['value']?.toString() ??
                    'N/A'; // Get the raw value as well

                final isSmokeStatusDetected = smokeStatus == 'SM0KE DETECTED';

                // Show alert when smoke status is 'SM0KE DETECTED' and alert hasn't been shown
                if (isSmokeStatusDetected && !smokeStatusAlertShown) {
                  smokeStatusAlertShown = true; // Set flag
                  Future.microtask(() {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Smoke Detected!'),
                            content: Text(
                              'Smoke detected! Status: $smokeStatus (Value: $smokeValue)',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  });
                } else if (!isSmokeStatusDetected) {
                  // Reset the flag when the status is no longer 'SM0KE DETECTED'
                  smokeStatusAlertShown = false;
                }

                final vibrationCount =
                    data['vibration']?['count']?.toString() ?? 'N/A';

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoBox("Vibration", "${vibrationCount}Hz"),
                    _buildInfoBox("Temperature", "${tempVal} C"),
                    _buildInfoBox("Humidity", "${humidityVal}%"),
                  ],
                );
              },
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoBox("Speed", vehicleSpeed),
                _buildInfoBox("RPM", engineRPM),
                _buildInfoBox("Fuel Rate", fuelConsumption),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                isConnected
                    ? _buildInfoBox(
                      "Driver Status",
                      _getDriverStatus(),
                      width: 120,
                      color: _getDriverStatusColor(_getDriverStatus()),
                    )
                    : GestureDetector(
                      onTap: connectToOBDII,
                      child: _buildInfoBox(
                        "Driver Status",
                        isConnecting ? "Reconnecting..." : "Disconnected",
                        width: 160,
                        color: Colors.grey,
                      ),
                    ),
                _buildInfoBox(
                  "Total Fuel",
                  totalFuelConsumption,
                  width: 120,
                  color: const Color.fromARGB(255, 15, 92, 239),
                ),
              ],
            ),
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
              child: Text(
                temporaryAlertMessage ?? "Fire, vibrations, alcohol warnings",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('sensors').onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error Loading Sonar Data',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  // if (snapshot.connectionState ==
                  //     ConnectionState.waiting) {
                  //   return const Center(
                  //     child: CircularProgressIndicator(),
                  //   );
                  // }
                  final data =
                      snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
                  if (data == null) {
                    return const Center(
                      child: Text(
                        'No sensor data available',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  ultrasonicBackLeft = _parseUltrasonicValue(
                    data['ultrasonic']?['backLeft']?['status'],
                  );
                  ultrasonicFrontLeft = _parseUltrasonicValue(
                    data['ultrasonic']?['frontLeft']?['status'],
                  );
                  ultrasonicFrontRight = _parseUltrasonicValue(
                    data['ultrasonic']?['frontRight']?['status'],
                  );
                  ultrasonicBackRight = _parseUltrasonicValue(
                    data['ultrasonic']?['backRight']?['status'],
                  );

                  print("front right: $ultrasonicFrontRight");
                  print("front left: $ultrasonicFrontLeft");
                  print("back right: $ultrasonicBackRight");
                  print("back left: $ultrasonicBackLeft");

                  return Stack(
                    children: [
                      if (ultrasonicFrontLeft == null ||
                          ultrasonicFrontLeft! >= 70.0)
                        Positioned(
                          top: 0,
                          left: 100,
                          child: Transform.rotate(angle: 5.55, child: null),
                        ),

                      if (ultrasonicFrontLeft != null &&
                          ultrasonicFrontLeft! < 70)
                        Positioned(
                          top: 0,
                          left: 100,
                          child: Transform.rotate(
                            angle: 5.55,
                            child: _buildRadarArc(ultrasonicFrontLeft!),
                          ),
                        ),

                      if (ultrasonicFrontRight == null ||
                          ultrasonicFrontRight! >= 70.0)
                        Positioned(
                          top: 0,
                          right: 100,
                          child: Transform.rotate(angle: 1.00, child: null),
                        ),

                      if (ultrasonicFrontRight != null &&
                          ultrasonicFrontRight! < 70)
                        Positioned(
                          top: 0,
                          right: 100,
                          child: Transform.rotate(
                            angle: 1.00,
                            child: _buildRadarArc(ultrasonicFrontRight!),
                          ),
                        ),

                      if (ultrasonicBackLeft == null ||
                          ultrasonicBackLeft! >= 70)
                        Positioned(
                          bottom: 0,
                          left: 100,
                          child: Transform.rotate(angle: 3.95, child: null),
                        ),

                      if (ultrasonicBackLeft != null &&
                          ultrasonicBackLeft! < 70)
                        Positioned(
                          bottom: 0,
                          left: 100,
                          child: Transform.rotate(
                            angle: 3.95,
                            child: _buildRadarArc(ultrasonicBackLeft!),
                          ),
                        ),

                      if (ultrasonicBackRight == null ||
                          ultrasonicBackRight! >= 70)
                        Positioned(
                          bottom: 0,
                          right: 100,
                          child: Transform.rotate(angle: 2.20, child: null),
                        ),

                      if (ultrasonicBackRight != null &&
                          ultrasonicBackRight! < 70)
                        Positioned(
                          bottom: 0,
                          right: 100,
                          child: Transform.rotate(
                            angle: 2.20,
                            child: _buildRadarArc(ultrasonicBackRight!),
                          ),
                        ),
                      Center(
                        child: Image.asset(
                          "assets/images/car.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarArc(double distance) {
    return CustomPaint(size: Size(60, 60), painter: RadarArcPainter(distance));
  }
}

class RadarArcPainter extends CustomPainter {
  final double distance;

  RadarArcPainter(this.distance);

  @override
  void paint(Canvas canvas, Size size) {
    Paint arcPaint;
    if (distance < 10) {
      arcPaint =
          Paint()
            ..color = Colors.red.withOpacity(0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
    } else if (distance < 30) {
      arcPaint =
          Paint()
            ..color = Colors.orange.withOpacity(0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
    } else {
      arcPaint =
          Paint()
            ..color = Colors.green.withOpacity(0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      double currentRadius = radius * (0.5 + i * 0.3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        3.5,
        2.2,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _buildInfoBox(
  String title,
  String value, {
  double width = 100,
  Color? color,
}) {
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
          color: color ?? const Color.fromARGB(255, 15, 92, 239), // default
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
