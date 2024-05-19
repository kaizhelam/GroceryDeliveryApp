import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';

import '../consts/firebase_consts.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../providers/viewed_prod_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/global_method.dart';
import '../services/utils.dart';
import '../widgets/heart_btn.dart';
import '../widgets/text_widget.dart';

class ProductDetails extends StatefulWidget {
  static const routeName = '/ProductDetails';

  const ProductDetails({Key? key}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final _quantityTextController = TextEditingController(text: '1');

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _quantityTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = Utils(context).getScreenSize;
    final Color color = Utils(context).color;

    final productProvider = Provider.of<ProductsProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final productId = ModalRoute.of(context)!.settings.arguments as String;
    final getCurrProduct = productProvider.findProdById(productId);

    double usedPrice = getCurrProduct.isOnSale
        ? getCurrProduct.salePrice
        : getCurrProduct.price;
    double sumPrice = usedPrice * int.parse(_quantityTextController.text);
    bool? _isInCart = cartProvider.getCardItems.containsKey(getCurrProduct.id);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    bool? _isInWishlist =
        wishlistProvider.getWishlistItems.containsKey(getCurrProduct.id);
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // viewedProdProvider.addProductToHistory(productId: productId);
      },
      child: Scaffold(
        appBar: AppBar(
            leading: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  Navigator.canPop(context) ? Navigator.pop(context) : null,
              child: Icon(
                IconlyLight.arrowLeft2,
                color: color,
                size: 24,
              ),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor),
        body: Column(children: [
          Flexible(
            flex: 2,
            child: FancyShimmerImage(
              imageUrl: getCurrProduct.imageUrl,
              boxFit: BoxFit.scaleDown,
              width: size.width,
            ),
          ),
          Flexible(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, left: 30, right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: TextWidget(
                            text: getCurrProduct.title,
                            color: color,
                            textSize: 25,
                            isTitle: true,
                          ),
                        ),
                        HeartBTN(
                          productId: getCurrProduct.id,
                          isInWishlist: _isInWishlist,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, left: 30, right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextWidget(
                          text: 'RM${usedPrice.toStringAsFixed(2)}',
                          color: Colors.cyan,
                          textSize: 24,
                          isTitle: true,
                        ),
                        TextWidget(
                          text: getCurrProduct.isPiece ? ' / Per Item' : '/Kg',
                          color: color,
                          textSize: 18,
                          isTitle: false,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Visibility(
                          visible: getCurrProduct.isOnSale ? true : false,
                          child: Text(
                            'RM${getCurrProduct.price.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 18,
                                color: color,
                                decoration: TextDecoration.lineThrough,
                              decorationColor: color,),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      quantityControl(
                        fct: () {
                          if (_quantityTextController.text == '1') {
                            return;
                          } else {
                            setState(() {
                              _quantityTextController.text =
                                  (int.parse(_quantityTextController.text) - 1)
                                      .toString();
                            });
                          }
                        },
                        icon: CupertinoIcons.minus,
                        color: Colors.red,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Flexible(
                        flex: 1,
                        child: TextField(
                          controller: _quantityTextController,
                          key: const ValueKey('quantity'),
                          keyboardType: TextInputType.number,
                          maxLines: 1,
                          style: TextStyle(color: color),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                          textAlign: TextAlign.center,
                          cursorColor: Colors.cyan,
                          enabled: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value.isEmpty) {
                                _quantityTextController.text = '1';
                              } else {}
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      quantityControl(
                        fct: () {
                          setState(() {
                            _quantityTextController.text =
                                (int.parse(_quantityTextController.text) + 1)
                                    .toString();
                          });
                        },
                        icon: CupertinoIcons.plus,
                        color: Colors.cyan,
                      ),
                    ],
                  ),
                  SizedBox(height: 12,),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, left: 30, right: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDescription(context, getCurrProduct.productDescription);
                          },
                          child: Row(
                            children: [
                              Icon(Icons.description, color: color, size: 18,), // Icon for View Product Description
                              SizedBox(width: 10), // Add some space between icon and text
                              TextWidget(
                                text: 'View Product Description',
                                color: color,
                                textSize: 14,
                                isTitle: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        GestureDetector(
                          onTap: () {
                            showRatingReview(context, getCurrProduct.id);
                          },
                          child: Row(
                            children: [
                              Icon(Icons.star, color: color, size: 18,), // Icon for View All Rating & Review
                              SizedBox(width: 10), // Add some space between icon and text
                              TextWidget(
                                text: 'View All Rating & Review',
                                color: color,
                                textSize: 14,
                                isTitle: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: 'Total',
                                color: color,
                                textSize: 20,
                                isTitle: true,
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              FittedBox(
                                child: Row(
                                  children: [
                                    TextWidget(
                                      text: 'RM${sumPrice.toStringAsFixed(2)} / ',
                                      color: color,
                                      textSize: 24,
                                      isTitle: true,
                                    ),
                                    TextWidget(
                                      text: '${_quantityTextController.text}${getCurrProduct.isPiece == false ? 'KG' : 'Item'}',
                                      color: color,
                                      textSize: 18,
                                      isTitle: false,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Flexible(
                          child: Material(
                            color: Colors.cyan,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: _isInCart
                                  ? null
                                  : () async {
                                      final User? user =
                                          authInstance.currentUser;
                                      if (user == null) {
                                        GlobalMethods.errorDialog(
                                            subtitle:
                                                'No user found, Please login in first',
                                            context: context);
                                        return;
                                      }
                                      await GlobalMethods.addToCart(
                                          productId: getCurrProduct.id,
                                          quantity: int.parse(
                                              _quantityTextController.text),
                                          context: context);
                                      await cartProvider.fetchCart();
                                      Navigator.of(context).pop();
                                    },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: TextWidget(
                                      text: _isInCart
                                          ? 'Item in Cart'
                                          : 'Add to Cart',
                                      color: Colors.white,
                                      textSize: 18)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }

  void showDescription(BuildContext context, String subtitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // backgroundColor: Colors.grey[900],
          title: const Text("Product Description", style: TextStyle(color: Colors.black, fontSize: 20)), // Title of the dialog
          content: Text(subtitle, style: TextStyle(color: Colors.black, fontSize: 14),), // Subtitle of the dialog
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close', style: TextStyle(color: Colors.cyan),),
            ),
          ],
        );
      },
    );
  }


  void showRatingReview(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Rate & Review",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
          content: FutureBuilder(
            future: FirebaseFirestore.instance.collection('products').doc(id).get(),
            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child:  CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(
                      Colors.cyan),
                ),);
              }
              if (productSnapshot.hasError) {
                return Center(child: Text('Error: ${productSnapshot.error}'));
              }
              if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                return const Center(child: Text('Product not found'));
              }

              // Fetch the ratingReview array from the product document
              final List<dynamic> ratingReviewArray = productSnapshot.data!['ratingReview'];

              if (ratingReviewArray.isEmpty) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: Center(
                    child: Text(
                      'No rating reviews available',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ratingReviewArray.map((review) {
                    final String name = review['Name'] ?? '';
                    final int rate = review['Rate'] ?? 0;
                    final String title = review['Title'] ?? '';
                    final String dateTime = review['currentDateTime'] ?? '';
                    final String reviewText = review['Review'] ?? '';
                    final String profileImageUrl = review['profileImage'] ?? ''; // Get profile image URL

                    List<Widget> starIcons = [];
                    for (int i = 0; i < 5; i++) {
                      if (i < rate) {
                        starIcons.add(const Icon(Icons.star, color: Colors.orange, size: 18,));
                      } else {
                        starIcons.add(const Icon(Icons.star_border, color: Colors.orange, size: 18,));
                      }
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: profileImageUrl != null && profileImageUrl.toString().isNotEmpty
                            ? NetworkImage(profileImageUrl.toString()) as ImageProvider<Object>?
                            : AssetImage('assets/images/user_icon.png'), // Use user icon if profileImageUrl is empty
                      ),
                      title: Row(
                        children: [
                          // Display the star icon
                          Row(
                            children: starIcons,
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.black, fontSize: 13)),
                          Text(reviewText, style: const TextStyle(color: Colors.black, fontSize: 13)),
                          Text(dateTime, style: const TextStyle(color: Colors.black, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close', style: TextStyle(color: Colors.cyan)),
            ),
          ],
        );
      },
    );
  }

  Widget quantityControl(
      {required Function fct, required IconData icon, required Color color}) {
    return Flexible(
      flex: 2,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: color,
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              fct();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                color: Colors.white,
                size: 25,
              ),
            )),
      ),
    );
  }
}
