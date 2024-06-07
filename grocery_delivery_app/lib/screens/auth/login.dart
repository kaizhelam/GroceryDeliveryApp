import 'dart:ui';

import 'package:card_swiper/card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app/screens/auth/register.dart';
import 'package:grocery_delivery_app/screens/btm_bar.dart';
import 'package:grocery_delivery_app/widgets/text_widget.dart';

import '../../consts/contss.dart';
import '../../consts/firebase_consts.dart';
import '../../fetch_screen.dart';
import '../../services/global_method.dart';
import '../../services/utils.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/google_button.dart';
import 'forget_pass.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/LoginScreen';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailTextController = TextEditingController();
  final _passTextController = TextEditingController();
  final _passFocusNode = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _obscureText = true;

  @override
  void dispose() {
    _emailTextController.dispose();
    _passTextController.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }

  void _submitFormOnLogin() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (isValid) {
      _formKey.currentState!.save();
      try {
        UserCredential userCredential = await authInstance.signInWithEmailAndPassword(
          email: _emailTextController.text,
          password: _passTextController.text,
        );

        if (!userCredential.user!.emailVerified) {
          Fluttertoast.showToast(
              msg: "Email is Not Verified Yet",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 13
          );
          await FirebaseAuth.instance.signOut();
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const FetchScreen(),
          ),
        );
      } on FirebaseException catch (error) {
        print(error);
        GlobalMethods.errorDialog(
          subtitle: '${error.message}',
          context: context,
        );
      } catch (error) {
        print(error);
        GlobalMethods.errorDialog(
          subtitle: '$error',
          context: context,
        );
      } finally {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    FocusNode passFocusNode = FocusNode();
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Center( // Center the image
                    child: Image.asset(
                      "assets/images/landing/signin.png",
                      width: 250,
                      height: 250,
                    ),
                  ),
                  TextWidget(
                    text: 'Welcome Back',
                    color: color,
                    textSize: 35,
                    isTitle: true,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextWidget(
                    text: 'Sign in to your account',
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
                          onEditingComplete: () => FocusScope.of(context)
                              .requestFocus(passFocusNode),
                          controller: _emailTextController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'This field is required';
                            } else if (!value.contains('@')) {
                              return 'Please enter a valid email address';
                            } else {
                              return null;
                            }
                          },
                          style: TextStyle(color: color),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: color),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color:color),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: color),
                            ),
                          ),
                          cursorColor: color,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        // password
                        TextFormField(
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () {
                            _submitFormOnLogin();
                          },
                          controller: _passTextController,
                          focusNode: passFocusNode,
                          obscureText: _obscureText,
                          keyboardType: TextInputType.visiblePassword,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'This field is required';
                            } else if( value.length < 6){
                              return 'Please enter a password more than 6 digit';
                            }else {
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
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: () {
                          GlobalMethods.navigateTo(
                              ctx: context,
                              routeName: ForgetPasswordScreen.routeName);
                        },
                        child: const Text(
                          'Forgot password?',
                          maxLines: 1,
                          style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold),
                        ),
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  AuthButton(
                      fct: () {
                        _submitFormOnLogin();
                      },
                      buttonText: 'Sign In'),
                  Row(
                    children: [
                       Expanded(
                        child: Divider(
                          color: color,
                          thickness: 2,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      TextWidget(
                        text: 'OR',
                        color: color,
                        textSize: 18,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                       Expanded(
                        child: Divider(
                          color: color,
                          thickness: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  AuthButton(
                      fct: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const FetchScreen()));
                      },
                      buttonText: 'Continue as a guest'),
                  const SizedBox(
                    height: 10,
                  ),
                  RichText(
                    text: TextSpan(
                      text: 'Don\'t have an account?',
                      style: TextStyle(color: color, fontSize: 18),
                      children: [
                        TextSpan(
                          text: ' Sign up',
                          style: const TextStyle(
                              color: Colors.cyan,
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              GlobalMethods.navigateTo(
                                  ctx: context,
                                  routeName: RegisterScreen.routeName);
                            },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
