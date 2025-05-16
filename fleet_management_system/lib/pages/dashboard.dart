import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
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
  String vehicleSpeed = "N/A";
  String acceleration = "N/A";
  String deceleration = "N/A";
  String fuelConsumption = "N/A"; // Instant fuel rate

  double? previousSpeed;
  DateTime? previousTime;
  Timer? rpmTimer;
  Timer? speedTimer;
  Timer? fuelTimer;
  String? temporaryAlertMessage;
  Timer? alertTimer;

  String obdDeviceAddress = "01:23:45:67:89:BA";

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
      setState(() => fuelConsumption = "${rate.toStringAsFixed(2)} L/h");
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
    connection?.dispose();
    alertTimer?.cancel();
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
                  },
                  itemBuilder:
                      (c) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Text('Logout'),
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
                  "Inst. Fuel",
                  fuelConsumption,
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
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 100,
                    child: Transform.rotate(
                      angle: 5.55,
                      child: _buildRadarArc(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 100,
                    child: Transform.rotate(
                      angle: 1.00,
                      child: _buildRadarArc(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 100,
                    child: Transform.rotate(
                      angle: 3.95,
                      child: _buildRadarArc(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 100,
                    child: Transform.rotate(
                      angle: 2.20,
                      child: _buildRadarArc(),
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      "assets/images/car.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            color: color ?? const Color.fromARGB(255, 15, 92, 239),
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

  Widget _buildRadarArc() =>
      CustomPaint(size: const Size(60, 60), painter: RadarArcPainter());
}

class RadarArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.red.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    var center = Offset(size.width / 2, size.height / 2);
    var radius = size.width / 2;
    for (var i = 0; i < 3; i++) {
      var r = radius * (0.5 + i * 0.3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        3.5,
        2.2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
