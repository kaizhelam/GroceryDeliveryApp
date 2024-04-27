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
          textSize: 20,
          isTitle: true,
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
                    height: 35,
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
                        ? 'Login Now and Start Ordering.'
                        : _email!,
                    color: color,
                    textSize: 18,
                    // isTitle: true,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Divider(
                    thickness: 2,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _listTiles(
                      title: 'Profile Details',
                      icon: IconlyLight.profile,
                      onPressed: () async {
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
                  const SizedBox(
                    height: 7,
                  ),
                  _listTiles(
                      title: 'My Address',
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
                  const SizedBox(
                    height: 7,
                  ),
                  _listTiles(
                      title: 'My Bank Card',
                      icon: Icons.credit_card,
                      onPressed: () {
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          _myBankCard(context);
                        }
                      },
                      color: color),
                  const SizedBox(
                    height: 7,
                  ),
                  _listTiles(
                      title: 'My Orders',
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
                  const SizedBox(
                    height: 7,
                  ),
                  _listTiles(
                      title: 'My Wishlist',
                      icon: IconlyLight.heart,
                      onPressed: () {
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          GlobalMethods.navigateTo(
                              ctx: context,
                              routeName: WishlistScreen.routeName);
                        }
                      },
                      color: color),
                  const SizedBox(
                    height: 7,
                  ),
                  _listTiles(
                      title: 'My Viewed',
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
                  const SizedBox(
                    height: 7,
                  ),
                  _listTiles(
                      title: 'Change Password',
                      icon: IconlyLight.unlock,
                      onPressed: () {
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          _changePassword(context, _email!);
                        }
                      },
                      color: color),
                  const SizedBox(
                    height: 7,
                  ),
                  SwitchListTile(
                    title: TextWidget(
                      text:
                          themeState.getDarkTheme ? 'Dark Mode' : 'Light Mode',
                      color: color,
                      textSize: 20,
                      isTitle: true,
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
                  const SizedBox(
                    height: 7,
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

  Future<void> _myBankCard(BuildContext context) async {
    List<Map<String, String>> userCards = [];
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    final User? user = authInstance.currentUser;
    final _uid = user!.uid;

    TextEditingController _cardNumberController = TextEditingController();
    TextEditingController _expiryDateController = TextEditingController();
    TextEditingController _cvvController = TextEditingController();

    await FirebaseFirestore.instance.collection('users').doc(_uid).get().then((docSnapshot) {
      if (docSnapshot.exists) {
        final userCard = docSnapshot.data()?['userCard'];
        if (userCard != null && userCard is List) {
          userCards = List<Map<String, String>>.from(userCard.map((card) => Map<String, String>.from(card)));
        }
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'My Bank Cards',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (userCards.isNotEmpty)
                    Column(
                      children: [
                        for (int i = 0; i < userCards.length; i++)
                          ListTile(
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Card Number: ${userCards[i]['cardNumber'] ?? ''}'),
                                      Text('Expiry Date: ${userCards[i]['expiryDate'] ?? ''}'),
                                      Text('CVV: ${userCards[i]['CVV'] ?? ''}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Add New Card',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: _cardNumberController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Card Number',
                                      hintText: 'XXXX XXXX XXXX XXXX',
                                      prefixIcon: Icon(Icons.credit_card, color: Colors.black54),
                                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                      labelStyle: TextStyle(color: Colors.black),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.cyan),
                                      ),
                                    ),
                                    cursorColor: Colors.cyan,
                                    validator: (value) {
                                      if (value == null || value.isEmpty || value.length != 16 || !RegExp(r'^[0-9]{16}$').hasMatch(value)) {
                                        return 'Please enter a valid 16-digit card number';
                                      }
                                      return null;
                                    },
                                  ),
                                  TextFormField(
                                    controller: _expiryDateController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'Expiry Date (MM/YY)',
                                      labelText: 'Expiry Date',
                                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                      labelStyle: TextStyle(color: Colors.black),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.cyan),
                                      ),
                                    ),
                                    cursorColor: Colors.cyan,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter an expiry date';
                                      }
                                      if (!RegExp(r'^\d{2}\/\d{2}$').hasMatch(value)) {
                                        return 'Please enter a valid expiry date (MM/YY)';
                                      }
                                      return null;
                                    },
                                  ),
                                  TextFormField(
                                    controller: _cvvController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'CVV',
                                      hintText: 'CVV',
                                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                      labelStyle: TextStyle(color: Colors.black),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.cyan),
                                      ),
                                    ),
                                    cursorColor: Colors.cyan,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a CVV';
                                      }
                                      if (!RegExp(r'^[0-9]{3,4}$').hasMatch(value)) {
                                        return 'Please enter a valid CVV';
                                      }
                                      return null;
                                    },
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        try {
                                          FirebaseFirestore.instance.collection('users').doc(_uid).update({
                                            'userCard': FieldValue.arrayUnion([
                                              {
                                                'cardNumber': _cardNumberController.text,
                                                'expiryDate': _expiryDateController.text,
                                                'CVV': _cvvController.text,
                                              }
                                            ])
                                          });
                                          Fluttertoast.showToast(
                                              msg: "New Card Added",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor: Colors.cyan,
                                              textColor: Colors.white,
                                              fontSize: 13);
                                        } catch (error) {
                                          Fluttertoast.showToast(
                                              msg: "Something went wrong, please try again later",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor: Colors.red,
                                              textColor: Colors.white,
                                              fontSize: 13);
                                        }
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: Text('Add Card'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      'Add New Card',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }


  Future<void> _changePassword(BuildContext context, String email) async {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    print(email);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text('Change Password',
                  style: TextStyle(fontSize: 19),),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors
                                .cyan), // Change the underline color when focused
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    cursorColor: Colors.cyan,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors
                                .cyan), // Change the underline color when focused
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    cursorColor: Colors.cyan,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    String newPassword = newPasswordController.text;
                    String confirmPassword = confirmPasswordController.text;

                    if(newPassword.isEmpty || confirmPassword.isEmpty){
                      Fluttertoast.showToast(
                        msg: "Passwords is Empty",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 13,
                      );
                      return;
                    }

                    // Check if passwords match
                    if (newPassword != confirmPassword) {
                      Fluttertoast.showToast(
                        msg: "Passwords Do Not Match!",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 13,
                      );
                      return;
                    }

                    if(newPassword.length < 8 || confirmPassword.length < 8){
                      Fluttertoast.showToast(
                        msg: "Password must be at least 8 characters long",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 3,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 13,
                      );
                      return;
                    }

                    // Check if password meets format requirements
                    RegExp regex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#$%^&*()_+={}\[\]|;:"<>,./?]).{8,}$');
                    if (!regex.hasMatch(newPassword)) {
                      Fluttertoast.showToast(
                        msg: "Password must contain at least one uppercase letter, one lowercase letter, one digit, and one special character",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 3,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 13,
                      );
                      return;
                    }

                    try {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await user.updatePassword(newPassword);
                        Fluttertoast.showToast(
                          msg: "Password Updated Successfully",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.cyan,
                          textColor: Colors.white,
                          fontSize: 13,
                        );
                      } else {
                        Fluttertoast.showToast(
                          msg: "User Not Found",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 13,
                        );
                      }
                      Navigator.of(context).pop();
                    } catch (error) {
                      Fluttertoast.showToast(
                        msg: "Error: $error",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 13,
                      );
                    }
                  },
                  child: const Text(
                    'Update',
                    style: TextStyle(color: Colors.cyan),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
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


  Future<void> _showAddressDialog() async {
    bool isLoading = false;
    String? selectedGender;
    String? genderFromDatabase;
    DateTime? _birthDate;

    // Function to retrieve gender from the database
    Future<void> _retrieveGenderFromDatabase() async {
      String _uid = user!.uid;
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      setState(() {
        genderFromDatabase = userDoc.get('gender');
        selectedGender = genderFromDatabase;
      });
    }

    await _retrieveGenderFromDatabase();

    await showDialog(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: AlertDialog(
            title: const Text('Edit Profile',
                style: TextStyle(fontSize: 19),),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _userNameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.black),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors
                                  .cyan), // Change the underline color when focused
                        ),
                      ),
                      cursorColor: Colors.cyan,
                    ),
                    TextField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Colors.black),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors
                                  .cyan), // Change the underline color when focused
                        ),
                      ),
                      cursorColor: Colors.cyan,
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
                          activeColor: Colors.cyan,
                        ),
                        const Text(
                          'Female',
                          style: TextStyle(color: Colors.black),
                        ),
                        Radio<String>(
                          value: 'male',
                          groupValue: selectedGender,
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value;
                            });
                          },
                          activeColor: Colors.cyan,
                        ),
                        const Text(
                          'Male',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Birth Date',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors
                                  .cyan), // Change the underline color when focused
                        ),
                        labelStyle: TextStyle(color: Colors.black),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _birthDate ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    // Define the theme properties
                                    colorScheme: const ColorScheme.dark(
                                      primary: Colors
                                          .cyan, // Change text color to green
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
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
                      cursorColor: Colors.cyan,
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
                        subtitle: 'Please Do Not Empty The Personal Details',
                        context: context,
                      );
                      return;
                    } else if (_phoneNumberController.text.length < 10) {
                      await GlobalMethods.errorDialog(
                        subtitle: 'Phone Number Should Be At Least 10 Digits',
                        context: context,
                      );
                      return;
                    }
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
                        'phoneNumber': _phoneNumberController.text,
                        'name': _userNameController.text,
                        'gender': selectedGender,
                        'birth': _birthDateController.text,
                      });
                      setState(() {
                        phoneNumber = _phoneNumberController.text;
                        _name = _userNameController.text;
                        _birth = _birthDateController.text;
                      });
                      Fluttertoast.showToast(
                          msg: "Profile Details Updated Successfully",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.cyan,
                          textColor: Colors.white,
                          fontSize: 13);
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
                  child: const Text(
                    'Update',
                    style: TextStyle(color: Colors.cyan),
                  ),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.cyan),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
