import 'package:flutter/cupertino.dart';
import 'package:grocery_delivery_app/services/utils.dart';

class EmptyProdWidget extends StatelessWidget {
  const EmptyProdWidget({super.key, required this.text});

  final String text;
  @override
  Widget build(BuildContext context) {
    Color color = Utils(context).color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/box.png',
                width: 200,
              ),
            ),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
