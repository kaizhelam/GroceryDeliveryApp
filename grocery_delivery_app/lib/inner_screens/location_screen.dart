import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/landing/delivery.png', // Path to your image asset
                                width: 200, // Adjust width as needed
                                height: 200, // Adjust height as needed
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons
                                      .location_on), // Add your desired icon
                                  SizedBox(
                                      width:
                                          8), // Adjust spacing between icon and text
                                  Text(
                                    'Your Address',
                                    style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          controller.currentLocation != null &&
                                  controller.currentLocation!.isNotEmpty
                              ? controller.currentLocation!
                              : _addressTextController.text.isNotEmpty
                                  ? _addressTextController.text
                                  : 'No Address Found',
                          style: const TextStyle(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await controller.getCurrentLocation();
                            },
                            icon: Icon(Icons.map),
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(Colors.cyan),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
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
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(Colors.cyan),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              shape: MaterialStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            label: const Text('Edit Address'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: controller.currentLocation != null &&
                                    controller.currentLocation!.isNotEmpty
                                ? () {
                                    _getCurrentLocation(
                                        controller.currentLocation, context);
                                  }
                                : null,
                            icon: Icon(Icons.save),
                            style: ButtonStyle(
                              backgroundColor: controller.currentLocation !=
                                          null &&
                                      controller.currentLocation!.isNotEmpty
                                  ? MaterialStateProperty.all<Color>(Colors
                                      .cyan) // Use cyan if condition is true
                                  : MaterialStateProperty.all<Color>(Colors
                                      .red), // Use red if condition is false
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                              shape: MaterialStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            label: const Text('Save Address'),
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

  Future<void> _getCurrentLocation(
      String? currentLocation, BuildContext context) async {
    final User? user = authInstance.currentUser;
    String _uid = user!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .update({'shippingAddress': currentLocation});
      Fluttertoast.showToast(
          msg: "Saved Address",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.cyan,
          textColor: Colors.white,
          fontSize: 13);
      Navigator.pop(context);
    } catch (err) {
      GlobalMethods.errorDialog(subtitle: err.toString(), context: context);
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
              title: const Text(
                'Edit Address',
                style: TextStyle(fontSize: 23),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _addressTextController == null
                        ? null
                        : _addressTextController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Address',
                      hintStyle: TextStyle(color: Colors.grey),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors
                                .cyan), // Change the underline color when focused
                      ),
                    ),
                    cursorColor: Colors.cyan,
                  ),
                  // Add more TextFields as needed
                ],
              ),
              actions: [
                if (isLoading)
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                  )
                else
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        isLoading =
                            true; // Set isLoading to true when update starts
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
                        Fluttertoast.showToast(
                            msg: "Updated Address",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.cyan,
                            textColor: Colors.white,
                            fontSize: 13);
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context);
                      } catch (err) {
                        GlobalMethods.errorDialog(
                            subtitle: err.toString(), context: context);
                      } finally {
                        setState(() {
                          isLoading =
                              false; // Set isLoading to false when update completes
                        });
                      }
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(color: Colors.cyan),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
