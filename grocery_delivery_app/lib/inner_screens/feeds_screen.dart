import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/models/products_model.dart';
import 'package:grocery_delivery_app/providers/products_provider.dart';
import 'package:grocery_delivery_app/widgets/back_widget.dart';
import 'package:provider/provider.dart';

import '../services/utils.dart';
import '../widgets/empty_products_widget.dart';
import '../widgets/feed_items.dart';
import '../widgets/text_widget.dart';

class FeedsScreen extends StatefulWidget {
  static const routeName = "/FeedsScreen";
  const FeedsScreen({super.key});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  final TextEditingController _searchTextController = TextEditingController();

  final FocusNode _searchTextFocusNode = FocusNode();
  @override
  void dispose() {
    _searchTextController.dispose();
    _searchTextFocusNode.dispose();
    Provider.of<ProductsProvider>(context, listen: false).dispose();
    super.dispose();
  }

  @override
  void initState() {
    final productProvider = Provider.of<ProductsProvider>(context, listen: false);
    productProvider.fetchProducts();
    super.initState();
  }
  String? _selectedSortOption = "low_to_high";
  List<ProductModel> listProductSearch = [];

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final productProvider = Provider.of<ProductsProvider>(context);
    List<ProductModel> allProducts = productProvider.getProducts;

    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        title: TextWidget(
          text: 'All Products',
          color: color,
          textSize: 20.0,
          isTitle: true,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: kBottomNavigationBarHeight,
                    child: TextField(
                      focusNode: _searchTextFocusNode,
                      controller: _searchTextController,
                      onChanged: (value) {
                        setState(() {
                          listProductSearch = productProvider.searchQuery(value);
                        });
                      },
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.cyan,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.cyan,
                            width: 2,
                          ),
                        ),
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
                          icon: Icon(
                            Icons.close,
                            color: _searchTextFocusNode.hasFocus ? Colors.red : color,
                          ),
                        ),
                      ),
                      cursorColor: Colors.cyan,
                    ),
                  ),
                  SizedBox(height: 10), // Adjust as needed
                  Row( // Wrap dropdown and apply button in a row
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedSortOption,
                          items: [
                            DropdownMenuItem(
                              value: "low_to_high",
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text("Price Low to High", textAlign: TextAlign.center, style: TextStyle(color: color),),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "high_to_low",
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text("Price High to Low", textAlign: TextAlign.center, style: TextStyle(color: color)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "name_a_to_z",
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text("Name A-Z", textAlign: TextAlign.center, style: TextStyle(color: color)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "name_z_to_a",
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text("Name Z-A", textAlign: TextAlign.center, style: TextStyle(color: color)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "most_popular_sold",
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text("Most Popular Sold", textAlign: TextAlign.center, style: TextStyle(color: color)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSortOption = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10), // Adjust as needed
                      SizedBox( // Set the width of the button
                        width: 150, // Adjust the width as needed
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedSortOption == "low_to_high") {
                              setState(() {
                                allProducts.sort((a, b) => a.price.compareTo(b.price));
                              });
                            } else if (_selectedSortOption == "high_to_low") {
                              setState(() {
                                allProducts.sort((a, b) => b.price.compareTo(a.price));
                              });
                            } else if (_selectedSortOption == "name_a_to_z") {
                              setState(() {
                                allProducts.sort((a, b) => a.title.compareTo(b.title));
                              });
                            } else if (_selectedSortOption == "name_z_to_a") {
                              setState(() {
                                allProducts.sort((a, b) => b.title.compareTo(a.title));
                              });
                            } else if (_selectedSortOption == "most_popular_sold") {
                              setState(() {
                                allProducts.sort((a, b) => b.productSold.compareTo(a.productSold));
                              });
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.cyan),
                            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          child: Text("Apply", style: TextStyle(fontSize: 17),),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _searchTextController!.text.isNotEmpty && listProductSearch.isEmpty
                ? const EmptyProdWidget(text: 'No Product found, please try another keyword')
                : GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              padding: EdgeInsets.zero,
              childAspectRatio: size.width / (size.height * 0.47),
              children: List.generate(
                _searchTextController!.text.isNotEmpty ? listProductSearch.length : allProducts.length,
                    (index) {
                  return ChangeNotifierProvider.value(
                    value: _searchTextController!.text.isNotEmpty ? listProductSearch[index] : allProducts[index],
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
