import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/inner_screens/cat_screen.dart';
import 'package:grocery_delivery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../provider/dark_theme_provider.dart';

class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({super.key, required this.catText, required this.imgPath, required this.passedColor});
  final String catText, imgPath;
  final Color passedColor;

  @override
  Widget build(BuildContext context) {
    // Size Size = MediaQuery.of(context).size;
    final themeState = Provider.of<DarkThemeProvider>(context, listen: false);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;

    double _screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
        onTap: () {
          Navigator.pushNamed(context, CategoryScreen.routeName,
              arguments: catText);
        },
        child: Container(
          // height: _screenWidth * 0.6,
          decoration: BoxDecoration(
            color: passedColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: passedColor.withOpacity(0.7), width: 2),
          ),
          child: Column(
            children: [
              Container(
                height: _screenWidth * 0.4,
                width: _screenWidth * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(
                        imgPath,
                      ),
                      ),
                ),
              ),
              TextWidget(
                text: catText,
                color: color,
                textSize: 20,
                isTitle: true,
              ),
            ],
          ),
        ));
  }
}
