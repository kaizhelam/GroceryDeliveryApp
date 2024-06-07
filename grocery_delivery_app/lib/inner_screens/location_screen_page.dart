import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../consts/firebase_consts.dart';
import '../services/utils.dart';
import '../widgets/back_widget.dart';
import '../widgets/text_widget.dart';
import 'location_controller.dart';

class LocationScreenPage extends StatefulWidget {
  @override
  _LocationScreenPageState createState() => _LocationScreenPageState();
}

class _LocationScreenPageState extends State<LocationScreenPage> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  String? userAddress;
  late LocationController controller;
  Marker? _marker;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(LocationController());
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _updateLocation(position.latitude, position.longitude);
  }

  Future<void> _updateLocation(double latitude, double longitude) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    Placemark placemark = placemarks.first;

    String address = '';
    if (placemark.name != null && placemark.name!.isNotEmpty) {
      address += placemark.name! + ', ';
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      address += placemark.locality! + ', ';
    }
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      address += placemark.postalCode! + ', ';
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      address += placemark.administrativeArea! + ', ';
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      address += placemark.country!;
    }

    setState(() {
      currentLocation = LatLng(latitude, longitude);
      userAddress = address;
      _marker = Marker(
        markerId: MarkerId('current_location'),
        position: currentLocation!,
        draggable: true,
        onDragEnd: _onMarkerDragEnd,
      );
    });

    final User? user = authInstance.currentUser;
    String _uid = user!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .update({'lat': latitude, 'long': longitude});
    } catch (err) {
      Fluttertoast.showToast(
          msg: "Something went wrong, please try again later",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 13);
    }
  }

  void _onMarkerDragEnd(LatLng newPosition) async {
    _updateLocation(newPosition.latitude, newPosition.longitude);
  }

  void _onMapTap(LatLng position) {
    _updateLocation(position.latitude, position.longitude);
  }

  Future<void> _searchLocation(String query) async {
    final String apiKey = 'AIzaSyAlfwn60g-Zle-7w6Uh8XrLpo6Gc-4hwqY';
    final String url =
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$query&inputtype=textquery&fields=geometry&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['candidates'] != null && json['candidates'].isNotEmpty) {
        final location = json['candidates'][0]['geometry']['location'];
        final latitude = location['lat'];
        final longitude = location['lng'];
        _updateLocation(latitude, longitude);

        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(latitude, longitude),
            ),
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Location not found, please try again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 13,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Location not found, please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 13,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = Utils(context).color;
    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: false,
        title: TextWidget(
          text: 'Google Map',
          color: color,
          textSize: 22,
          isTitle: true,
        ),
        backgroundColor:
        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: color),
            onPressed: () {
              _confirmAddress(currentLocation!, userAddress!);
              return;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search your Location',
                hintStyle: TextStyle(
                    color: Colors.black),
                fillColor: Colors.white,
                filled: true,
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchLocation(searchController.text);
                    FocusScope.of(context).unfocus();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              cursorColor: Colors.cyan,
            ),
          ),
          Expanded(
            child: currentLocation == null
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
              ),
            )
                : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLocation!,
                zoom: 15.5,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: {
                if (_marker != null) _marker!,
              },
              onTap: _onMapTap,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAddress(LatLng location, String userAddress) async {
    final User? user = authInstance.currentUser;
    String _uid = user!.uid;

    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            userAddress,
            style: TextStyle(fontSize: 19),
          ),
          content: const Text(
            'Confirm to save this as your Address?',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'No',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .update({'shippingAddress': userAddress});

      Fluttertoast.showToast(
        msg: "Address Saved",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 13,
      );
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }
}
