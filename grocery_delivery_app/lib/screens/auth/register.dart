import 'dart:ui';

import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app/screens/btm_bar.dart';
import 'package:grocery_delivery_app/services/global_method.dart';

import '../../consts/contss.dart';
import '../../consts/firebase_consts.dart';
import '../../fetch_screen.dart';
import '../../services/utils.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/text_widget.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/RegisterScreen';
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _passTextController = TextEditingController();
  final _addressTextController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _confirmPassTextController = TextEditingController();

  final _passFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _phoneNumberFocusNode = FocusNode();
  final _confirmPassFocusNode = FocusNode();
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _addressTextController.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _addressFocusNode.dispose();
    _phoneNumberController.dispose();
    _phoneNumberFocusNode.dispose();
    _confirmPassFocusNode.dispose();
    _confirmPassTextController.dispose();
    super.dispose();
  }

  void _submitFormOnRegister(BuildContext context) async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (isValid) {
      _formKey.currentState!.save();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
            ),
          );
        },
      );
      try {
        UserCredential userCredential = await authInstance.createUserWithEmailAndPassword(
          email: _emailTextController.text,
          password: _passTextController.text,
        );
        await userCredential.user!.updateDisplayName(_fullNameController.text);
        await userCredential.user!.sendEmailVerification();
        await userCredential.user!.reload();
        final _uid = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(_uid).set({
          'id': _uid,
          'name': _fullNameController.text,
          'email': _emailTextController.text.toLowerCase(),
          'shippingAddress': "",
          'phoneNumber': _phoneNumberController.text,
          'userWish': [],
          'userCart': [],
          'userCard': [],
          'userRecipes': [],
          'userFavouriteRecipes' : [],
          'gender': "null",
          'birth': "",
          'createdAt': Timestamp.now(),
          'profileImage': "",
        });
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: "Please Check your Email & Verify to Login",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 13
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      } on FirebaseException catch (error) {
        print(error);
        Navigator.pop(context);
        GlobalMethods.errorDialog(subtitle: '${error.message}', context: context);
      } catch (error) {
        print(error);
        Navigator.pop(context);
        GlobalMethods.errorDialog(subtitle: '$error', context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Utils(context).getTheme;
    final Color color = Utils(context).color;
    bool containsUppercase(String value) {
      return value.contains(RegExp(r'[A-Z]'));
    }

    bool containsLowercase(String value) {
      return value.contains(RegExp(r'[a-z]'));
    }

    bool containsSpecialCharacter(String value) {
      return value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    }


    return Scaffold(
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Center( // Center the image
                  child: Image.asset(
                    "assets/images/landing/signup.png",
                    width: 150,
                    height: 150,
                  ),
                ),
                TextWidget(
                  text: 'Register',
                  color: color,
                  textSize: 35,
                  isTitle: true,
                ),
                const SizedBox(
                  height: 8,
                ),
                TextWidget(
                  text: "Create your new account",
                  color: color,
                  textSize: 18,
                  isTitle: false,
                ),
                const SizedBox(
                  height: 8,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        controller: _fullNameController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'This field is required';
                          } else {
                            return null;
                          }
                        },
                        style:  TextStyle(color: color),
                        decoration:  InputDecoration(
                          hintText: 'Full name',
                          hintStyle: TextStyle(color: color),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                        ),
                        cursorColor: color,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        focusNode: _emailFocusNode,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailTextController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'This field is required';
                          }else if (!value.contains("@gmail.com")){
                            return "Please enter a valid Email address";
                          } else {
                            return null;
                          }
                        },
                        style:  TextStyle(color: color),
                        decoration:  InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: color),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                        ),
                        cursorColor: color,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        focusNode: _passFocusNode,
                        obscureText: _obscureText,
                        keyboardType: TextInputType.visiblePassword,
                        controller: _passTextController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'This field is required';
                          } else if (value.length < 8){
                            return "Password must be at least 8 characters long";
                          }
                          else if (!containsUppercase(value) ||
                              !containsLowercase(value) ||
                              !containsSpecialCharacter(value)) {
                            return "Password must contain at least one uppercase letter,\none lowercase letter,\nand one special character";
                          } else {
                            return null;
                          }
                        },
                        style: TextStyle(color: color),
                        decoration: InputDecoration(
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                            child: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: color,
                            ),
                          ),
                          hintText: 'Password',
                          hintStyle:  TextStyle(color: color),
                          enabledBorder:  UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                          focusedBorder:  UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                        ),
                        cursorColor: color,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        focusNode: _confirmPassFocusNode,
                        obscureText: _obscureConfirmText,
                        keyboardType: TextInputType.visiblePassword,
                        controller: _confirmPassTextController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'This field is required';
                          } else if (value.length < 8){
                            return "Password must be at least 8 characters long";
                          } else if (value != _passTextController.text) {
                            return "Passwords do not match";
                          } else {
                            return null;
                          }
                        },
                        style: TextStyle(color: color),
                        decoration: InputDecoration(
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureConfirmText = !_obscureConfirmText;
                              });
                            },
                            child: Icon(
                              _obscureConfirmText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: color,
                            ),
                          ),
                          hintText: 'Confirm Password',
                          hintStyle:  TextStyle(color: color),
                          enabledBorder:  UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                          focusedBorder:  UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                        ),
                        cursorColor: color,
                      ),

                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        focusNode: _phoneNumberFocusNode,
                        textInputAction: TextInputAction.done,
                        controller: _phoneNumberController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9]')), // Accept only numbers
                        ],
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'This field is required';
                          } else if (value.length != 10) {
                            return "Phone Number should be 10 digits long";
                          } else {
                            return null;
                          }
                        },
                        style: TextStyle(color: color),
                        textAlign: TextAlign.start,
                        decoration: InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(color: color),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: color),
                          ),
                        ),
                        cursorColor: color,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                AuthButton(
                  buttonText: 'Sign up',
                  fct: () {
                    _submitFormOnRegister(context);
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                RichText(
                  text: TextSpan(
                      text: 'Already a user?',
                      style: TextStyle(color: color, fontSize: 18),
                      children: <TextSpan>[
                        TextSpan(
                            text: ' Sign in',
                            style: const TextStyle(
                                color: Colors.cyan, fontSize: 18, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacementNamed(
                                    context, LoginScreen.routeName);
                              }),
                      ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
