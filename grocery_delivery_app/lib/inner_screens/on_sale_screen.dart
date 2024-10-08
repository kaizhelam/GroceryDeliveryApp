import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/widgets/on_sale_widget.dart';
import 'package:grocery_delivery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../models/products_model.dart';
import '../providers/products_provider.dart';
import '../services/utils.dart';
import '../widgets/back_widget.dart';
import '../widgets/empty_products_widget.dart';

class OnSaleScreen extends StatelessWidget {
  static const routeName = "/OnSaleScreen";
  const OnSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProviders = Provider.of<ProductsProvider>(context);
    List<ProductModel> productOnSale = productProviders.getOnSaleProducts;

    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        title: TextWidget(
          text: 'Products On Sale',
          color: color,
          textSize: 20.0,
          isTitle: true,
        ),
      ),
      body: productOnSale.isEmpty
          ? const EmptyProdWidget(
              text: 'No products on sale yet!',
            )
          : GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.zero,
              // crossAxisSpacing: 10,
              childAspectRatio: size.width / (size.height * 0.45),
              children: List.generate(
                productOnSale.length,
                (index) {
                  return ChangeNotifierProvider.value(
                    value: productOnSale[index],
                    child: const OnSaleWidget(),
                  );
                },
              ),
            ),
    );
  }
}
