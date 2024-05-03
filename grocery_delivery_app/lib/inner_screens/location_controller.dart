import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../consts/firebase_consts.dart';

import 'package:geolocator/geolocator.dart';

class LocationController extends GetxController {
  Position? currentPosition;
  var isLoading = false.obs;
  String? currentLocation;

  Future<void> getCurrentLocation() async {
    try {
      isLoading(true);
      update();

      // Request permission to access the device's location
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Handle the case where the user denied permission
        throw Exception('Location permissions are denied');
      }

      // Get the current position
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Get the address details from the current position
      await getAddressFromLatLng(
          currentPosition!.latitude, currentPosition!.longitude);

      isLoading(false);
      update();
    } catch (e) {
      print(e);
    }
  }

  Future<void> getAddressFromLatLng(double lat, double long) async {
    print(lat);
    print(long);
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(lat, long);

      Placemark placemark = placemarks[0];

      // Construct the address string from the placemark details
      currentLocation =
      "${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.administrativeArea}, ${placemark.country}";
      update();
    } catch (e) {
      print(e);
    }

    final User? user = authInstance.currentUser;
    String _uid = user!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .update({'lat': lat, 'long' : long});
    } catch (err) {
      Fluttertoast.showToast(
          msg: "Something went wrong, please try again later",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.cyan,
          textColor: Colors.white,
          fontSize: 13);
    }
  }
}

