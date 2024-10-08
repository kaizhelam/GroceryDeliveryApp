import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/widgets/text_widget.dart';

import '../services/utils.dart';

class AuthButton extends StatelessWidget {
  const AuthButton(
      {super.key,
      required this.fct,
      required this.buttonText,
      this.primary = Colors.white38});
  final Function fct;
  final String buttonText;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final utils = Utils(context);
    Color color = utils.color;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Adjust the value as needed
            side: BorderSide.none // Add border
          ),
        ),
        onPressed: () {
          fct();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextWidget(
            color: Colors.white,
            textSize: 18,
            text: buttonText,
          ),
        ),
      ),
    );
  }
}
