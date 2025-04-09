import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
//import 'package:google_maps_webservice/places.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _mapCompleter = Completer();
  final Location _locationController = Location();
  TextEditingController _searchController = TextEditingController();

  static const LatLng sourceLocation = LatLng(37.33500926, -122.03272188);
  static const LatLng destination = LatLng(37.33429383, -122.03981562);
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getLocationUpdates();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_mapCompleter.isCompleted) {
      _mapCompleter.complete(controller);
    }
  }

  Future<void> _getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged.listen((LocationData location) {
      if (location.latitude != null && location.longitude != null) {
        setState(() {
          _currentPosition = LatLng(location.latitude!, location.longitude!);
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentPosition!),
        );
      }
    });
  }

  // void _searchLocation(String placeId) async {
  //   final places = GoogleMapsPlaces(apiKey: "AIzaSyD3o1xU8EVjFSSGABrJiCDMkgwh4UfBWoE");
  //   PlacesDetailsResponse detail = await places.getDetailsByPlaceId(placeId);

  //   final lat = detail.result.geometry?.location.lat;
  //   final lng = detail.result.geometry?.location.lng;

  //   if (lat != null && lng != null) {
  //     LatLng searchedLocation = LatLng(lat, lng);
  //     _mapController?.animateCamera(CameraUpdate.newLatLngZoom(searchedLocation, 14.5));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Location Tracking',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: sourceLocation,
              zoom: 14.5,
            ),
            markers: {
              if (_currentPosition != null)
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: _currentPosition!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                ),
              const Marker(
                markerId: MarkerId('sourceLocation'),
                position: sourceLocation,
              ),
              const Marker(
                markerId: MarkerId('destinationLocation'),
                position: destination,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: _searchController,
                  googleAPIKey: "AIzaSyD3o1xU8EVjFSSGABrJiCDMkgwh4UfBWoE",
                  inputDecoration: InputDecoration(
                    hintText: "Search Location",
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                  ),
                  debounceTime: 600,
                  isLatLngRequired: true,
                  // getPlaceDetailWithLatLng: (prediction) {
                  //   _searchLocation(prediction.placeId);
                  // },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
