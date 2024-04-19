import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_delivery_app/consts/firebase_consts.dart';
import 'package:grocery_delivery_app/screens/auth/forget_pass.dart';
import 'package:grocery_delivery_app/screens/auth/login.dart';
import 'package:grocery_delivery_app/screens/loading_manager.dart';
import 'package:grocery_delivery_app/screens/orders/orders_screen.dart';
import 'package:grocery_delivery_app/screens/viewed_recently/viewed_recently.dart';
import 'package:grocery_delivery_app/screens/wishlist/wishlist_screen.dart';
import 'package:grocery_delivery_app/screens/wishlist/wishlist_widget.dart';
import 'package:grocery_delivery_app/services/global_method.dart';
import 'package:provider/provider.dart';

import '../provider/dark_theme_provider.dart';
import '../widgets/text_widget.dart';
import 'package:location/location.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final TextEditingController _addressTextController =
      TextEditingController(text: "");

  @override
  void dispose() {
    _addressTextController.dispose();
    super.dispose();
  }

  String? _email;
  String? _name;
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
        _email = userDoc.get('email');
        _name = userDoc.get('name');
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
  }

  Location? _pickedLocation;
  var _isGettingLocation = false;

  void _getCurrentLocation() async{
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    setState(() {
      var _isGettingLocation = true;
    });

    locationData = await location.getLocation();

    setState(() {
      var _isGettingLocation = false;
    });

    print(locationData.latitude);
    print(locationData.longitude);
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
                    text: _email == null ? 'Login now and start ordering.' : _email!,
                    color: color,
                    textSize: 18,
                    // isTitle: true,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Divider(
                    thickness: 2,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _listTiles(
                      title: 'Address',
                      subtitle: address,
                      icon: IconlyLight.profile,
                      onPressed: () async {
                        await _showAddressDialog();
                      },
                      color: color),
                  _listTiles(
                      title: 'Orders',
                      icon: IconlyLight.bag,
                      onPressed: () {
                        GlobalMethods.navigateTo(
                            ctx: context, routeName: OrdersScreen.routeName);
                      },
                      color: color),
                  _listTiles(
                      title: 'Wishlist',
                      icon: IconlyLight.heart,
                      onPressed: () {
                        GlobalMethods.navigateTo(
                            ctx: context, routeName: WishlistScreen.routeName);
                      },
                      color: color),
                  _listTiles(
                      title: 'Viewed',
                      icon: IconlyLight.show,
                      onPressed: () {
                        GlobalMethods.navigateTo(
                            ctx: context,
                            routeName: ViewedRecentlyScreen.routeName);
                      },
                      color: color),
                  _listTiles(
                      title: 'Forget Password',
                      icon: IconlyLight.unlock,
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                const ForgetPasswordScreen()));
                      },
                      color: color),
                  _listTiles(
                      title: 'Get current Location',
                      icon: IconlyLight.location,
                      onPressed: () {
                        _getCurrentLocation();
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
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update'),
          content: TextField(
            controller: _addressTextController,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Your address'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
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
                  Navigator.pop(context);
                } catch (err) {
                  GlobalMethods.errorDialog(
                      subtitle: err.toString(), context: context);
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
