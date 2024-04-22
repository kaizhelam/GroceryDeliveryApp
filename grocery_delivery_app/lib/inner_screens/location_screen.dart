import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:grocery_delivery_app/screens/user.dart';

import '../consts/firebase_consts.dart';
import '../services/global_method.dart';
import 'location_controller.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _addressTextController =
  TextEditingController(text: "");

  String? address;
  bool _isLoading = false;
  final User? user = authInstance.currentUser;

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      String _uid = user!.uid;

      final DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (userDoc == null) {
        return;
      } else {
        address = userDoc.get('shippingAddress');
        _addressTextController.text = userDoc.get('shippingAddress');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      GlobalMethods.errorDialog(subtitle: '$error', context: context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    print(_addressTextController.text);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
      init: LocationController(),
      builder: (controller) {
        return Scaffold(
          body: Center(
            child: controller.isLoading.value
                ? const CircularProgressIndicator()
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on), // Add your desired icon
                        SizedBox(width: 8), // Adjust spacing between icon and text
                        Text(
                          'Your Address:',
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    controller.currentLocation != null && controller.currentLocation!.isNotEmpty
                        ? controller.currentLocation!
                        : _addressTextController.text.isNotEmpty
                        ? _addressTextController.text
                        : 'No address found',
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await controller.getCurrentLocation();
                      },
                      icon: Icon(Icons.map),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      label: const Text('Get your current Location'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        _showAddressDialog();
                      },
                      icon: Icon(Icons.edit),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      label: const Text('Edit Location'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: controller.currentLocation != null && controller.currentLocation!.isNotEmpty
                          ? () {
                        _getCurrentLocation(controller.currentLocation, context);
                      }
                          : null,
                      icon: Icon(Icons.save),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      label: const Text('Save Location'),
                    )
                  ],
                ),
              ],
            ),
          ),
        );

      },
    );
  }

  Future<void> _getCurrentLocation(String? currentLocation, BuildContext context) async {
    final User? user = authInstance.currentUser;
    String _uid = user!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .update({
        'shippingAddress': currentLocation
      });
      Navigator.pop(context);
    } catch (err) {
      GlobalMethods.errorDialog(
          subtitle: err.toString(), context: context);
    }
  }

  Future<void> _showAddressDialog() async {
    bool isLoading = false; // Flag to track loading state

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog while loading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Address', style: TextStyle(fontSize: 23),),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _addressTextController == null ? null : _addressTextController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Address',
                    ),
                  ),
                  // Add more TextFields as needed
                ],
              ),
              actions: [
                if (isLoading)
                  CircularProgressIndicator() // Show loading spinner if isLoading is true
                else
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true; // Set isLoading to true when update starts
                      });

                      String _uid = user!.uid;
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_uid)
                            .update({
                          'shippingAddress': _addressTextController.text,
                          // Update other fields as needed
                        });
                        setState(() {
                          address = _addressTextController.text;
                          // Update other states as needed
                        });
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context);
                        // Navigator.of(context).pushReplacement(
                        //   MaterialPageRoute(
                        //     builder: (context) => const UserScreen(),
                        //   ),
                        // );
                      } catch (err) {
                        GlobalMethods.errorDialog(
                            subtitle: err.toString(), context: context);
                      } finally {
                        setState(() {
                          isLoading = false; // Set isLoading to false when update completes
                        });
                      }
                    },
                    child: const Text('Update'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

