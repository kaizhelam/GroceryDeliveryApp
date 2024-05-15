import 'dart:io';

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
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../inner_screens/location_controller.dart';
import '../provider/dark_theme_provider.dart';
import '../widgets/text_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'my_recipes.dart';

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

  TextEditingController _cardNumberController = TextEditingController();
  TextEditingController _expiryDateController = TextEditingController();
  TextEditingController _cvvController = TextEditingController();

  @override
  void dispose() {
    _addressTextController.dispose();
    _phoneNumberController.dispose();
    _userNameController.dispose();
    _genderController.dispose();
    _birthDateController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
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
  String? _profileImageUrl;

  @override
  void initState() {
    getUserData();
    super.initState();
    _fetchProfileImageUrl();
  }

  Future<void> _fetchProfileImageUrl() async {
    if (user != null) {
      String _uid = user!.uid;

      DocumentSnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      setState(() {
        Map<String, dynamic>? userData =
        userSnapshot.data() as Map<String, dynamic>?;
        _profileImageUrl = userData?['profileImage'];
      });
    } else {
      print('User is null');
    }
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

  Future<void> _uploadImage() async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Upload Profile Picture',
              style: TextStyle(fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _getImageFromSource(ImageSource.camera);
                    },
                    child: const Row(
                      children: <Widget>[
                        Icon(Icons.camera, color: Colors.black,),
                        SizedBox(width: 8),
                        Text(
                          'Camera',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                  ),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _getImageFromSource(ImageSource.gallery);
                    },
                    child: const Row(
                      children: <Widget>[
                        Icon(Icons.photo, color: Colors.black,),
                        SizedBox(width: 8),
                        Text(
                          'Photos',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _getImageFromSource(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: source);

      if (pickedImage != null) {
        final imageFile = File(pickedImage.path);

        bool uploadConfirmed = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Confirm Upload',
                style: TextStyle(fontSize: 19),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Are you sure to upload this image?',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 15),
                  // Display small image preview
                  Image.file(
                    imageFile,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ],
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

        if (uploadConfirmed != null && uploadConfirmed) {
          Fluttertoast.showToast(
            msg: "Image Uploading...",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.cyan,
            textColor: Colors.white,
            fontSize: 13,
          );
          String downloadURL = await _uploadImageToStorage(imageFile);
          await _storeImageUrlInFirestore(downloadURL);
          setState(() {
            _profileImageUrl = downloadURL;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<String> _uploadImageToStorage(File imageFile) async {
    String _uid = user!.uid;
    final storageRef = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('users')
        .child(_uid)
        .child('profileImage');
    await storageRef.putFile(imageFile);
    return await storageRef.getDownloadURL();

    Fluttertoast.showToast(
      msg: "Image Uploaded",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.cyan,
      textColor: Colors.white,
      fontSize: 13,
    );
  }

  Future<void> _storeImageUrlInFirestore(String downloadURL) async {
    String _uid = user!.uid;
    await FirebaseFirestore.instance.collection('users').doc(_uid).update({
      'profileImage': downloadURL,
    });

    Fluttertoast.showToast(
      msg: "Image Uploaded",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.cyan,
      textColor: Colors.white,
      fontSize: 13,
    );
  }

  Future<void> _removeImage() async {
    try {
      String uid = user!.uid;

      bool confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Remove Image',
              style: TextStyle(fontSize: 19),
            ),
            content: const Text(
              'Are you sure you want to remove your profile image?',
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
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('users')
            .child(uid)
            .child('profileImage');
        await storageRef.delete();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'profileImage': ""});

        setState(() {
          _profileImageUrl = null;
        });
        Fluttertoast.showToast(
          msg: "Image Removed",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 13,
        );
        print('Image removed successfully');
      }
    } catch (e) {
      print('Error removing image: $e');
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
                  const SizedBox(height: 35),
                  Row(
                    children: [
                      GestureDetector(
                        onTap:
                            _profileImageUrl != null && _profileImageUrl != ""
                                ? _removeImage
                                : _uploadImage,
                        child: CircleAvatar(
                          radius: 29, // Adjust the size as needed
                          backgroundImage: _profileImageUrl != null &&
                                  _profileImageUrl != ""
                              ? NetworkImage(
                                  _profileImageUrl!)
                              : null,
                          child: _profileImageUrl == null ||
                                  _profileImageUrl == ""
                              ? const Icon(
                                  Icons.account_circle,
                                  color: Colors.black,
                                  size: 58,
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: 'Hi, ',
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: _name == null ? 'Welcome' : _name,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextWidget(
                            text: _email == null
                                ? 'Login Now and Start Ordering.'
                                : _email!,
                            color: color,
                            textSize: 15,
                          ),
                        ],
                      ),
                    ],
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
                      title: 'My Recipes',
                      icon: IconlyLight.bookmark,
                      onPressed: () {
                        final User? user = authInstance.currentUser;
                        if (user == null) {
                          GlobalMethods.errorDialog(
                              subtitle: 'No user found, Please login in first',
                              context: context);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MyRecipesScreen(),
                            ),
                          );
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

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get()
        .then((docSnapshot) {
      if (docSnapshot.exists) {
        final userCard = docSnapshot.data()?['userCard'];
        if (userCard != null && userCard is List) {
          userCards = List<Map<String, String>>.from(
              userCard.map((card) => Map<String, String>.from(card)));
        }
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'My Bank Cards',
                        style: TextStyle(fontSize: 18, color: Colors.black),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    userCards.isNotEmpty
                        ? SingleChildScrollView(
                            child: Column(
                              children: [
                                for (int i = 0; i < userCards.length; i++)
                                  ListTile(
                                    title: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Card Number: ${userCards[i]['cardNumber'] != null ? '*${userCards[i]['cardNumber']!.substring(userCards[i]['cardNumber']!.length - 4)}' : ''}',
                                                style: TextStyle(fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _removeUserCard(i, userCards, _uid);
                                          },
                                          child: Icon(Icons.delete),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Container(
                            child: Center(
                            child: TextWidget(
                              text: "No available Cards",
                              color: Colors.black,
                              textSize: 15,
                            ),
                          )),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              child: Form(
                                key: _formKey,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: TextFormField(
                                          controller: _cardNumberController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Card Number',
                                            hintText: 'XXXX XXXX XXXX XXXX',
                                            prefixIcon: Icon(Icons.credit_card,
                                                color: Colors.black54),
                                            hintStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.cyan),
                                            ),
                                          ),
                                          cursorColor: Colors.cyan,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty ||
                                                value.length != 16 ||
                                                !RegExp(r'^[0-9]{16}$')
                                                    .hasMatch(value)) {
                                              return 'Please enter a valid 16-digit card number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: TextFormField(
                                          controller: _expiryDateController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: 'Expiry Date (MM/YY)',
                                            labelText: 'Expiry Date',
                                            hintStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.cyan),
                                            ),
                                          ),
                                          cursorColor: Colors.cyan,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter an expiry date';
                                            }
                                            if (!RegExp(r'^\d{2}\/\d{2}$')
                                                .hasMatch(value)) {
                                              return 'Please enter a valid expiry date (MM/YY)';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: TextFormField(
                                          controller: _cvvController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'CVV',
                                            hintText: 'CVV',
                                            hintStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                            labelStyle:
                                                TextStyle(color: Colors.black),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.cyan),
                                            ),
                                          ),
                                          cursorColor: Colors.cyan,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter a CVV';
                                            }
                                            if (!RegExp(r'^[0-9]{3,4}$')
                                                .hasMatch(value)) {
                                              return 'Please enter a valid CVV';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  try {
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(_uid)
                                                        .update({
                                                      'userCard': FieldValue
                                                          .arrayUnion([
                                                        {
                                                          'cardNumber':
                                                              _cardNumberController
                                                                  .text,
                                                          'expiryDate':
                                                              _expiryDateController
                                                                  .text,
                                                          'CVV': _cvvController
                                                              .text,
                                                        }
                                                      ])
                                                    });
                                                    Fluttertoast.showToast(
                                                      msg: "New Card Added",
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      gravity:
                                                          ToastGravity.BOTTOM,
                                                      timeInSecForIosWeb: 1,
                                                      backgroundColor:
                                                          Colors.cyan,
                                                      textColor: Colors.white,
                                                      fontSize: 13,
                                                    );
                                                    Navigator.of(context).pop();
                                                  } catch (error) {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          "Something went wrong, please try again later",
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      gravity:
                                                          ToastGravity.BOTTOM,
                                                      timeInSecForIosWeb: 1,
                                                      backgroundColor:
                                                          Colors.red,
                                                      textColor: Colors.white,
                                                      fontSize: 13,
                                                    );
                                                  }
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: Text(
                                                'Add Card',
                                                style: TextStyle(
                                                  color: Colors.cyan,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.cyan,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(15),
                        child: Center(
                          child: Text(
                            'Add a New Card',
                            style: TextStyle(color: Colors.cyan),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _removeUserCard(
      int index, List<Map<String, dynamic>> userCards, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'userCard': FieldValue.arrayRemove([userCards[index]])
      });

      setState(() {
        userCards.removeAt(index);
      });

      Fluttertoast.showToast(
        msg: "Card Removed",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 13,
      );
      Navigator.of(context).pop();
    } catch (error) {
      Fluttertoast.showToast(
        msg: "Something went wrong, please try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 13,
      );
    }
  }

  Future<void> _changePassword(BuildContext context, String email) async {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    print(email);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text(
                'Change Password',
                style: TextStyle(fontSize: 19),
              ),
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
                                .cyan),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
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
                                .cyan),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
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

                    if (newPassword.isEmpty || confirmPassword.isEmpty) {
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

                    if (newPassword.length < 8 || confirmPassword.length < 8) {
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

                    RegExp regex = RegExp(
                        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#$%^&*()_+={}\[\]|;:"<>,./?]).{8,}$');
                    if (!regex.hasMatch(newPassword)) {
                      Fluttertoast.showToast(
                        msg:
                            "Password must contain at least one uppercase letter, one lowercase letter, one digit, and one special character",
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
            title: const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 19),
            ),
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
                                  .cyan),
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
                                  .cyan),
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
                                          .cyan,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _birthDate = pickedDate;
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
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                )
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
                          true;
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
