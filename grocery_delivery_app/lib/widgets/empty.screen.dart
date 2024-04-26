import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/widgets/text_widget.dart';

import '../inner_screens/feeds_screen.dart';
import '../services/global_method.dart';
import '../services/utils.dart';

class EmptyScreen extends StatelessWidget {
  const EmptyScreen(
      {super.key,
      required this.imagePath,
      required this.title,
      required this.subtitle,
      required this.buttonText});

  final String imagePath, title, subtitle, buttonText;
  @override
  Widget build(BuildContext context) {
    Size size = Utils(context).getScreenSize;
    final themeState = Utils(context).getTheme;
    final Color color = Utils(context).color;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
              ),
              Image.asset(
                imagePath,
                width: double.infinity,
                height: size.height * 0.35,
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Whoops!',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 33,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 15,),
              TextWidget(text: title, color: color, textSize: 23),
              const SizedBox(
                height: 20,
              ),
              TextWidget(text: subtitle, color: color, textSize: 16),
              SizedBox(
                height: size.height * 0.1,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: Colors.cyan,
                  // onPrimary: color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                ),
                onPressed: () {
                  GlobalMethods.navigateTo(
                      ctx: context, routeName: FeedsScreen.routeName);
                },
                child: TextWidget(
                  text: buttonText,
                  textSize: 20,
                  color: Colors.white,
                  isTitle: true,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
