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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: kBottomNavigationBarHeight,
                      child: TextField(
                        focusNode: _searchTextFocusNode,
                        controller: _searchTextController,
                        onChanged: (valuee) {
                          setState(() {
                            listProductSearch =
                                productProvider.searchQuery(valuee);
                          });
                        },
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.cyan, width: 2)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.cyan, width: 2)),
                          hintText: "Search something...",
                          hintStyle: TextStyle(
                            color: color,
                          ),
                          prefixIcon: Icon(Icons.search, color: color,),
                          suffix: IconButton(
                            onPressed: () {
                              _searchTextController.clear();
                              _searchTextFocusNode.unfocus();
                            },
                            icon: Icon(Icons.close,
                                color: _searchTextFocusNode.hasFocus
                                    ? Colors.red
                                    : color),
                          ),
                        ),
                        cursorColor: Colors.cyan,
                      ),
                    ),
                  ),
                  _searchTextController!.text.isNotEmpty &&
                          listProductSearch.isEmpty
                      ? const EmptyProdWidget(
                          text: 'No Product found, please try another keyword')
                      : GridView.count(
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
