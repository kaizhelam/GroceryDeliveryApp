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
import '../services/utils.dart';
import '../widgets/back_widget.dart';
import '../widgets/text_widget.dart';
import 'location_controller.dart';
import 'location_screen_page.dart';

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

  final LocationController controller = Get.put(LocationController());

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
    Color color = Utils(context).color;
    return GetBuilder<LocationController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            leading: const BackWidget(),
            automaticallyImplyLeading: false,
            elevation: 0,
            centerTitle: false,
            title: TextWidget(
              text: 'My Address',
              color: color,
              textSize: 22,
              isTitle: true,
            ),
            backgroundColor:
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 55),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/landing/delivery.png',
                            width: 200,
                            height: 200,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 28,
                        ),
                        Expanded(
                          child: Text(
                            _addressTextController.text.isEmpty ? 'No Address Found' : _addressTextController.text,
                            style: const TextStyle(fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (controller.isLoading.value)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                    ),
                  const SizedBox(height: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.to(() => LocationScreenPage());
                        },
                        icon: const Icon(Icons.map),
                        style: ButtonStyle(
                          backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.cyan),
                          foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        label: const Text('Open Map to Pick Address'),
                      ),
                      // const SizedBox(height: 20),
                      // ElevatedButton.icon(
                      //   onPressed: (){
                      //     _getCurrentLocation(
                      //       controller.currentLocation.value,
                      //       context,
                      //     );                        },
                      //   icon: const Icon(Icons.save),
                      //   style: ButtonStyle(
                      //     backgroundColor: MaterialStateProperty.all<Color>(Colors.cyan),
                      //     foregroundColor:
                      //     MaterialStateProperty.all<Color>(Colors.white),
                      //     shape: MaterialStateProperty.all<OutlinedBorder>(
                      //       RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //     ),
                      //   ),
                      //   label: const Text('Save Address'),
                      // ),
                      // const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
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
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 13);
      Navigator.pop(context);
    } catch (err) {
      GlobalMethods.errorDialog(subtitle: err.toString(), context: context);
    }
  }

  Future<void> _showAddressDialog() async {
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Edit Address',
                style: TextStyle(fontSize: 23),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _addressTextController == null
                          ? null
                          : _addressTextController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Address',
                        hintStyle: TextStyle(color: Colors.grey),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.cyan,
                          ),
                        ),
                      ),
                      cursorColor: Colors.cyan,
                    ),
                    // Add more TextFields as needed
                  ],
                ),
              ),
              actions: [
                if (isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                  )
                else
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });

                      String _uid = user!.uid;
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_uid)
                            .update({
                          'shippingAddress': _addressTextController.text,
                        });
                        setState(() {
                          address = _addressTextController.text;
                        });
                        Fluttertoast.showToast(
                            msg: "Updated Address",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            fontSize: 13);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      } catch (err) {
                        GlobalMethods.errorDialog(
                            subtitle: err.toString(), context: context);
                      } finally {
                        setState(() {
                          isLoading = false;
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
