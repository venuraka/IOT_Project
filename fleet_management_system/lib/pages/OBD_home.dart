import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class OBDIIPage extends StatefulWidget {
  @override
  _OBDIIPageState createState() => _OBDIIPageState();
}

class _OBDIIPageState extends State<OBDIIPage> {
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool isConnected = false;
  String responseText = "Connecting...";
  String engineRPM = "N/A";
  Timer? rpmTimer;

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

  void startListening() {
    if (connection == null || !isConnected) return;

    connection!.input!.listen((Uint8List data) {
      String rawResponse = utf8.decode(data);
      print("Raw OBD Response: $rawResponse");
      parseEngineRPMResponse(rawResponse);
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

  @override
  void dispose() {
    rpmTimer?.cancel();
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OBD-II Engine RPM")),
      body: Center(
        child: Column(
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
            Text("Engine RPM: $engineRPM", style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/speed');
              },
              child: Text("Go to Speed Page"),
            ),
          ],
        ),
      ),
    );
  }
}
