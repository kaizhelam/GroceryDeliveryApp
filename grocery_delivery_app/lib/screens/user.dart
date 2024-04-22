import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:grocery_delivery_app/consts/firebase_consts.dart';
import 'package:grocery_delivery_app/inner_screens/location_screen.dart';
import 'package:grocery_delivery_app/screens/auth/forget_pass.dart';
import 'package:grocery_delivery_app/screens/auth/login.dart';
import 'package:grocery_delivery_app/screens/loading_manager.dart';
import 'package:grocery_delivery_app/screens/orders/orders_screen.dart';
import 'package:grocery_delivery_app/screens/viewed_recently/viewed_recently.dart';
import 'package:grocery_delivery_app/screens/wishlist/wishlist_screen.dart';
import 'package:grocery_delivery_app/screens/wishlist/wishlist_widget.dart';
import 'package:grocery_delivery_app/services/global_method.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../inner_screens/location_controller.dart';
import '../provider/dark_theme_provider.dart';
import '../widgets/text_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final TextEditingController _addressTextController =
      TextEditingController(text: "");
  final TextEditingController _phoneNumberController =
  TextEditingController(text: "");
  final TextEditingController _userNameController =
  TextEditingController(text: "");
  final TextEditingController _genderController =
  TextEditingController(text: "");
  final TextEditingController _birthDateController =
  TextEditingController(text: "");

  @override
  void dispose() {
    _addressTextController.dispose();
    _phoneNumberController.dispose();
    _userNameController.dispose();
    _genderController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String? _email;
  String? _name;
  String? address;
  String? phoneNumber;
  String? gender;
  String? _birth;
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
        _email = userDoc.get('email');
        _name = userDoc.get('name');
        _userNameController.text = userDoc.get('name');
        phoneNumber = userDoc.get('phoneNumber');
        _phoneNumberController.text = userDoc.get('phoneNumber');
        address = userDoc.get('shippingAddress');
        _addressTextController.text = userDoc.get('shippingAddress');
        gender = userDoc.get('gender');
        _genderController.text = userDoc.get('gender');
        _birth = userDoc.get('birth');
        _birthDateController.text = userDoc.get('birth');
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
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context, listen: false);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;

    Widget _listTiles(
        {required String title,
        String? subtitle,
        required IconData icon,
        required Function onPressed,
        required Color color}) {
      return ListTile(
        title: TextWidget(
          text: title,
          color: color,
          textSize: 22,
          isTitle: true,
        ),
        subtitle: TextWidget(
          text: subtitle == null ? "" : subtitle,
          color: color,
          textSize: 18,
        ),
        leading: Icon(
          icon,
          color: color,
        ),
        trailing: Icon(
          IconlyLight.arrowRight2,
          color: color,
        ),
        onTap: () {
          onPressed();
        },
      );
    }

    return Scaffold(
      body: LoadingManager(
        isLoading: _isLoading,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  RichText(
                    text: TextSpan(
                      text: 'Hi, ',
                      style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 27,
                          fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: _name == null ? 'Welcome' : _name,
                          style: TextStyle(
                              color: color,
                              fontSize: 23,
                              fontWeight: FontWeight.w600),
                          //         recognizer: TapGestureRecognizer()..onTap = (){
                          //           print('My name');
                          // }
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  TextWidget(
                    text: _email == null
                        ? 'Login now and start ordering.'
                        : _email!,
                    color: color,
                    textSize: 18,
                    // isTitle: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Divider(
                    thickness: 2,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  // GetBuilder<LocationController>(
                  //   init: LocationController(),
                  //   builder: (controller) {
                  //     return _listTiles(
                  //       title: 'Profile Details',
                  //       // subtitle: controller.currentLocation,
                  //       icon: IconlyLight.profile,
                  //       onPressed: () async {
                  //         await _showAddressDialog();
                  //       },
                  //       color: color,
                  //     );
                  //   },
                  // ),
                  _listTiles(
                      title: 'Profile Details',
                      icon: IconlyLight.profile,
                      onPressed: () async{
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          await _showAddressDialog();
                        }
                      },
                      color: color),
                  _listTiles(
                      title: 'Address',
                      icon: IconlyLight.location,
                      onPressed: () {
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LocationScreen(),
                            ),
                          );
                        }
                      },
                      color: color),
                  _listTiles(
                      title: 'Reset Password',
                      icon: IconlyLight.unlock,
                      onPressed: () {
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                              const ForgetPasswordScreen()));
                        }
                      },
                      color: color),
                  _listTiles(
                      title: 'Orders',
                      icon: IconlyLight.bag,
                      onPressed: () {
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          GlobalMethods.navigateTo(
                              ctx: context, routeName: OrdersScreen.routeName);
                        }
                      },
                      color: color),
                  _listTiles(
                      title: 'Wishlist',
                      icon: IconlyLight.heart,
                      onPressed: () {
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          GlobalMethods.navigateTo(
                              ctx: context, routeName: WishlistScreen.routeName);
                        }
                      },
                      color: color),
                  _listTiles(
                      title: 'Viewed',
                      icon: IconlyLight.show,
                      onPressed: () {
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          GlobalMethods.navigateTo(
                              ctx: context,
                              routeName: ViewedRecentlyScreen.routeName);
                        }
                      },
                      color: color),
                  SwitchListTile(
                    title: TextWidget(
                      text:
                          themeState.getDarkTheme ? 'Dark Mode' : 'Light Mode',
                      color: color,
                      textSize: 22,
                      // isTitle: true,
                    ),
                    secondary: Icon(
                      themeState.getDarkTheme
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: color,
                    ),
                    onChanged: (bool value) {
                      setState(() {
                        themeState.setDarkTheme = value;
                      });
                    },
                    value: themeState.getDarkTheme,
                  ),
                  _listTiles(
                      title: user == null ? 'Login' : 'Logout',
                      icon:
                          user == null ? IconlyLight.login : IconlyLight.logout,
                      onPressed: () {
                        if (user == null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                          return;
                        }
                        GlobalMethods.warningDialog(
                          title: 'Sign out',
                          subtitle: 'Do you wanna sign out?',
                          fct: () async {
                            await authInstance.signOut();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const LoginScreen()));
                          },
                          context: context,
                        );
                      },
                      color: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddressDialog() async {
    bool isLoading = false;
    String? selectedGender;
    String? genderFromDatabase;
    DateTime? _birthDate;

    // Function to retrieve gender from the database
    Future<void> _retrieveGenderFromDatabase() async {
      String _uid = user!.uid;
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      setState(() {
        genderFromDatabase = userDoc.get('gender');
        selectedGender = genderFromDatabase;
      });
    }

    await _retrieveGenderFromDatabase();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _userNameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  TextField(
                    controller: _phoneNumberController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                    ),
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'female',
                        groupValue: selectedGender,
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                      ),
                      const Text('Female', style: TextStyle(color:  Colors.black),),
                      Radio<String>(
                        value: 'male',
                        groupValue: selectedGender,
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                      ),
                      const Text('Male',  style: TextStyle(color:  Colors.black),),
                    ],
                  ),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Birth Date',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _birthDate ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _birthDate = pickedDate;
                              // Update the birth date text in the controller
                              _birthDateController.text =
                              '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                            });
                          }
                        },
                      ),
                    ),
                    controller: _birthDateController,
                  ),
                ],
              );
            },
          ),
          actions: [
            if (isLoading)
              CircularProgressIndicator() // Show loading spinner if isLoading is true
            else
              TextButton(
                onPressed: () async {
                  if (_userNameController.text.isEmpty ||
                      _phoneNumberController.text.isEmpty) {
                    await GlobalMethods.errorDialog(
                      subtitle: 'Please do not empty the personal details',
                      context: context,
                    );
                    return;
                  } else if (_phoneNumberController.text.length < 10) {
                    await GlobalMethods.errorDialog(
                      subtitle: 'Phone Number should be at least 10 digits',
                      context: context,
                    );
                    return;
                  }
                  setState(() {
                    isLoading = true; // Set isLoading to true when update starts
                  });

                  String _uid = user!.uid;
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_uid)
                        .update({
                      'phoneNumber': _phoneNumberController.text,
                      'name': _userNameController.text,
                      'gender': selectedGender,
                      'birth' : _birthDateController.text,
                    });
                    setState(() {
                      phoneNumber = _phoneNumberController.text;
                      _name = _userNameController.text;
                      _birth = _birthDateController.text;
                    });
                    Fluttertoast.showToast(
                        msg: "Profile Details Updated",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.grey.shade600,
                        textColor: Colors.white,
                        fontSize: 16.0);
                    Navigator.pop(context);
                  } catch (err) {
                    await GlobalMethods.errorDialog(
                      subtitle: err.toString(),
                      context: context,
                    );
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                },
                child: const Text('Update'),
              ),
          ],
        );
      },
    );
  }
}
