import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

// 🔹 Replace this with your actual Google Maps API Key
const String googleAPIKey = 'AIzaSyA0T9YYL8Xz2Rt7FQo9rPj0qzw2Iwhu2r4';

// Custom prediction class (simpler than using google_places_flutter or other packages)
class MyPrediction {
  final String description;
  final String placeId;

  MyPrediction({required this.description, required this.placeId});
}

class RoutingMapScreen extends StatefulWidget {
  @override
  _RoutingMapScreenState createState() => _RoutingMapScreenState();
}

class _RoutingMapScreenState extends State<RoutingMapScreen> {
  late GoogleMapController _controller;
  static const LatLng _initialCameraPosition = LatLng(7.8731, 80.7718);

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

  List<MyPrediction> _originPredictions = [];
  List<MyPrediction> _destinationPredictions = [];

  Future<void> _setCurrentLocationAsOrigin() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    // Check for permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Location permissions are permanently denied. Please enable them in settings.')),
      );
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address =
            "${placemark.name}, ${placemark.locality}, ${placemark.country}";
        setState(() {
          _originController.text = address;
          _originPredictions.clear();
        });
      }
    } catch (e) {
      print("Reverse geocoding error: $e");
    }
  }


  void _getOriginAutocomplete(String input) async {
    if (input.isNotEmpty) {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleAPIKey&components=country:lk',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;
        setState(() {
          _originPredictions = predictions
              .map((p) => MyPrediction(description: p['description'], placeId: p['place_id']))
              .toList();
        });
      } else {
        setState(() => _originPredictions = []);
      }
    } else {
      setState(() => _originPredictions = []);
    }
  }

  void _getDestinationAutocomplete(String input) async {
    if (input.isNotEmpty) {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$googleAPIKey&components=country:lk',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;
        setState(() {
          _destinationPredictions = predictions
              .map((p) => MyPrediction(description: p['description'], placeId: p['place_id']))
              .toList();
        });
      } else {
        setState(() => _destinationPredictions = []);
      }
    } else {
      setState(() => _destinationPredictions = []);
    }
  }

  Future<LatLng?> _getCoordinatesFromPlaceId(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleAPIKey',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
    return null;
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations[0].latitude, locations[0].longitude);
      }
    } catch (e) {
      print("Geocoding error: $e");
    }
    return null;
  }

  Future<void> _findRoute() async {
    LatLng? originCoordinates;
    LatLng? destinationCoordinates;

    if (_originController.text.isNotEmpty &&
        _originPredictions.any((p) => p.description == _originController.text)) {
      final selectedPrediction = _originPredictions.firstWhere(
              (p) => p.description == _originController.text);
      originCoordinates =
      await _getCoordinatesFromPlaceId(selectedPrediction.placeId);
    } else {
      originCoordinates =
      await _getCoordinatesFromAddress(_originController.text.trim());
    }

    if (_destinationController.text.isNotEmpty &&
        _destinationPredictions.any((p) => p.description == _destinationController.text)) {
      final selectedPrediction = _destinationPredictions.firstWhere(
              (p) => p.description == _destinationController.text);
      destinationCoordinates =
      await _getCoordinatesFromPlaceId(selectedPrediction.placeId);
    } else {
      destinationCoordinates =
      await _getCoordinatesFromAddress(_destinationController.text.trim());
    }

    if (originCoordinates != null && destinationCoordinates != null) {
      _getDirections(originCoordinates, destinationCoordinates);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resolve one or both locations.')),
      );
    }
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleAPIKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0];
      final polyline = route['overview_polyline']['points'];

      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> result = polylinePoints.decodePolyline(polyline);

      List<LatLng> polylineCoordinates = result
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        _polylines.clear();
        _markers.clear();

        _polylines.add(Polyline(
          polylineId: PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: polylineCoordinates,
        ));

        _markers.add(Marker(
          markerId: MarkerId('origin'),
          position: origin,
          infoWindow: InfoWindow(title: 'Origin'),
        ));

        _markers.add(Marker(
          markerId: MarkerId('destination'),
          position: destination,
          infoWindow: InfoWindow(title: 'Destination'),
        ));

        _controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                origin.latitude <= destination.latitude
                    ? origin.latitude
                    : destination.latitude,
                origin.longitude <= destination.longitude
                    ? origin.longitude
                    : destination.longitude,
              ),
              northeast: LatLng(
                origin.latitude >= destination.latitude
                    ? origin.latitude
                    : destination.latitude,
                origin.longitude >= destination.longitude
                    ? origin.longitude
                    : destination.longitude,
              ),
            ),
            100.0,
          ),
        );
      });
    } else {
      print('Failed to get directions: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Route Optimizer',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue, // Optional: ensure contrast with white text
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _originController,
              decoration: InputDecoration(
                labelText: 'Choose Start Location',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.my_location,color: Color.fromARGB(255, 15, 92, 239)),
                  onPressed: _setCurrentLocationAsOrigin,
                  tooltip: 'Choose Destination',
                ),
              ),
              onChanged: _getOriginAutocomplete,
            ),
          ),
          if (_originPredictions.isNotEmpty)
            Container(
              height: 150,
              child: ListView.builder(
                itemCount: _originPredictions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_originPredictions[index].description),
                    onTap: () {
                      setState(() {
                        _originController.text =
                            _originPredictions[index].description;
                        _originPredictions.clear();
                      });
                    },
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Destination Address',
                border: OutlineInputBorder(),
              ),
              onChanged: _getDestinationAutocomplete,
            ),
          ),
          if (_destinationPredictions.isNotEmpty)
            Container(
              height: 150,
              child: ListView.builder(
                itemCount: _destinationPredictions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_destinationPredictions[index].description),
                    onTap: () {
                      setState(() {
                        _destinationController.text =
                            _destinationPredictions[index].description;
                        _destinationPredictions.clear();
                      });
                    },
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _findRoute,
              child: Text('Find Route'),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialCameraPosition,
                zoom: 7.0,
              ),
              onMapCreated: (controller) {
                _controller = controller;
              },
              markers: _markers,
              polylines: _polylines,
            ),
          ),
        ],
      ),
    );
  }
}