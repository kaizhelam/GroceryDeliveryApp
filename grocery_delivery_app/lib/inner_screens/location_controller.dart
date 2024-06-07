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
  RxString currentLocation = RxString("");

  Future<void> getCurrentLocation() async {
    try {
      isLoading(true);
      update();
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      await getAddressFromLatLng(currentPosition!.latitude, currentPosition!.longitude);
      isLoading(false);
      update();
    } catch (e) {
      print(e);
    }
  }

  Future<void> getAddressFromLatLng(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;

        // Constructing the full address
        currentLocation.value = "${placemark.street ?? placemark.name ?? ''}, ${placemark.locality ?? ''}, ${placemark.postalCode ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.country ?? ''}";
      } else {
        currentLocation.value = "Address not found";
      }
      update();
    } catch (e) {
      print(e);
      currentLocation.value = "Error fetching address";
      update();
    }
  }

  void updateAddress(String address, ) {
    currentLocation.value = address;
  }

}
