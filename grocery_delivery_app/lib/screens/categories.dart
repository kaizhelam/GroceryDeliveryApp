import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/widgets/categories_widget.dart';
import 'package:grocery_delivery_app/widgets/text_widget.dart';

import '../services/utils.dart';

class CategoriesScreen extends StatelessWidget {
  CategoriesScreen({super.key});

  List<Color> gridColors = [
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
  ];



  List<Map<String, dynamic>> catInfo = [
    {
      'imgPath': 'assets/images/cat/food.png',
      'catText': 'Foods',
    },
    {
      'imgPath': 'assets/images/cat/fruits.png',
      'catText': 'Fruits',
    },
    {
      'imgPath': 'assets/images/cat/veg.png',
      'catText': 'Vegetables',
    },
    {
      'imgPath': 'assets/images/cat/drink.png',
      'catText': 'Drinks',
    },
    {
      'imgPath': 'assets/images/cat/nuts.png',
      'catText': 'Nuts',
    },
    // {
    //   'imgPath': 'assets/images/cat/spices.png',
    //   'catText': 'Spices',
    // },
    {
      'imgPath': 'assets/images/cat/grains.png',
      'catText': 'Grains',
    },
    // {
    //   'imgPath': 'assets/images/cat/Spinach.png',
    //   'catText': 'Herbs',
    // },
  ];

  @override
  Widget build(BuildContext context) {
    final utils = Utils(context);
    Color color = utils.color;
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextWidget(
          text: 'Categories',
          color: color,
          textSize: 24,
          isTitle: true,
        ),
        titleSpacing: 10,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 220 / 260,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: List.generate(6, (index) {
            return CategoriesWidget(
              catText: catInfo[index]['catText'],
              imgPath: catInfo[index]['imgPath'],
              passedColor: color,
            );
          }),
        ),
      ),
    );
  }
}
