import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../calculations/obd_calculations.dart';

class SpeedPage extends StatefulWidget {
  @override
  _SpeedPageState createState() => _SpeedPageState();
}

class _SpeedPageState extends State<SpeedPage> {
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool isConnected = false;
  String responseText = "Connecting...";
  String vehicleSpeed = "N/A";
  String acceleration = "N/A";
  String deceleration = "N/A";
  Timer? speedTimer;

  double? previousSpeed;
  DateTime? previousTime;

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

  void startSpeedUpdates() {
    speedTimer?.cancel();
    speedTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (isConnected) {
        sendOBDCommand("010D");
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
      parseSpeedResponse(rawResponse);
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

  void parseSpeedResponse(String response) {
    if (!response.contains("41 0D")) return;

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
    speedTimer?.cancel();
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OBD-II Vehicle Speed")),
      body: Center(
        child:
            isConnecting
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      "Connecting to OBD-II...",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isConnected ? "✅ Connected" : "❌ Disconnected",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(responseText, style: TextStyle(fontSize: 18)),
                    SizedBox(height: 20),
                    Text(
                      "Vehicle Speed: $vehicleSpeed",
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Acceleration: $acceleration",
                      style: TextStyle(fontSize: 24, color: Colors.green),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Deceleration: $deceleration",
                      style: TextStyle(fontSize: 24, color: Colors.blue),
                    ),
                  ],
                ),
      ),
    );
  }
}
