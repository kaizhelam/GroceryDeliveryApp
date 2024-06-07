import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/models/products_model.dart';
import 'package:grocery_delivery_app/providers/products_provider.dart';
import 'package:grocery_delivery_app/widgets/back_widget.dart';
import 'package:grocery_delivery_app/widgets/empty_products_widget.dart';
import 'package:provider/provider.dart';

import '../services/utils.dart';
import '../widgets/feed_items.dart';
import '../widgets/text_widget.dart';
import 'package:grocery_delivery_app/providers/products_provider.dart';

class CategoryScreen extends StatefulWidget {
  static const routeName = "/FeedsScreenState";
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<CategoryScreen> {
  final TextEditingController _searchTextController = TextEditingController();

  final FocusNode _searchTextFocusNode = FocusNode();
  List<ProductModel> listProductSearch = [];
  @override
  void dispose() {
    _searchTextController.dispose();
    _searchTextFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final productProvider = Provider.of<ProductsProvider>(context);
    final catName = ModalRoute.of(context)!.settings.arguments as String;
    List<ProductModel> productByCat = productProvider.findByCategory(catName);

    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        title: TextWidget(
          text: catName,
          color: color,
          textSize: 20.0,
          isTitle: true,
        ),
      ),
      body: productByCat.isEmpty
          ? const EmptyProdWidget(
              text: 'No products belong to this category',
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          padding: EdgeInsets.zero,
                          // crossAxisSpacing: 10,
                          childAspectRatio: size.width / (size.height * 0.47),
                          children: List.generate(
                            _searchTextController!.text.isNotEmpty
                                ? listProductSearch.length
                                : productByCat.length,
                            (index) {
                              return ChangeNotifierProvider.value(
                                value: _searchTextController!.text.isNotEmpty
                                    ? listProductSearch[index]
                                    : productByCat[index],
                                child: const FeedsWidget(),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
