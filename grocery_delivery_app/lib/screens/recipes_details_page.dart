import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app/screens/recipes_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../consts/firebase_consts.dart';
import '../inner_screens/product_details.dart';
import '../models/viewed_model.dart';
import '../provider/dark_theme_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../services/global_method.dart';
import '../services/utils.dart';
import '../widgets/text_widget.dart';
import 'cart/cart_screen.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final QueryDocumentSnapshot recipe;

  RecipeDetailsScreen({required this.recipe});

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  bool _isLoading = true;
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  late String productName = '';
  late String productPrice = '';
  late String productImage = '';
  late int productSold = 0;
  late String productidd = '';
  bool loading2 = false;
  final FirebaseAuth authInstance = FirebaseAuth.instance;
  Set<String> userCartProductIDs = Set();

  @override
  void initState() {
    super.initState();
    _fetchUserCart();
    _videoPlayerController = VideoPlayerController.network(
      widget.recipe['videoUrl'],
    );
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoInitialize: true,
      autoPlay: false,
      looping: false,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.isInitialized) {
        setState(() {
          _isLoading = false;
        });
      }
    });
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    try {
      String productID = widget.recipe['productID'];
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productID)
          .get();

      Map<String, dynamic> productData =
          productSnapshot.data() as Map<String, dynamic>;
      setState(() {
        productName = productData['title'];
        productPrice = productData['price'].toString();
        productImage = productData['imageUrl'];
        productSold = productData['productSold'];
      });
    } catch (e) {
      print('Error fetching product data: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController.dispose();
    _chewieController.dispose();
  }

  Future<void> _fetchUserCart() async {
    try {
      final User? user = authInstance.currentUser;

      if (user == null) {
        GlobalMethods.errorDialog(
            subtitle: 'No user found, Please login first', context: context);
        return;
      }

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        GlobalMethods.errorDialog(
            subtitle: 'User data not found', context: context);
        return;
      }

      List<dynamic> userCart = userDoc['userCart'] ?? [];
      setState(() {
        userCartProductIDs =
            userCart.map((item) => item['productId'] as String).toSet();
      });
    } catch (error) {
      GlobalMethods.errorDialog(subtitle: '$error', context: context);
    }
  }

  void _addItemToCart(String productID, String productName) async {
    productidd = productID;
    setState(() {
      loading2 = true;
    });
    try {
      final cartId = const Uuid().v4();
      final User? user = authInstance.currentUser;
      final _uid = user!.uid;

      if (user == null) {
        GlobalMethods.errorDialog(
            subtitle: 'No user found, Please login first', context: context);
        setState(() {
          loading2 = false;
        });
        return;
      }

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<dynamic> userCart = userDoc['userCart'] ?? [];

      bool productExistsInCart = false;
      for (var item in userCart) {
        if (item['productId'] == productID) {
          productExistsInCart = true;
          break;
        }
      }

      if (productExistsInCart) {
        Fluttertoast.showToast(
            msg: "$productName is already in your Cart.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 13);
      }else{
        Navigator.pushNamed(context, ProductDetails.routeName,
            arguments: productID);
      }
    } catch (error) {
      GlobalMethods.errorDialog(subtitle: '$error', context: context);
    } finally {
      setState(() {
        loading2 = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool productInCart =
        userCartProductIDs.contains(widget.recipe['productID']);
    final themeState = Provider.of<DarkThemeProvider>(context, listen: false);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;
    Map<String, dynamic> recipeData =
        widget.recipe.data() as Map<String, dynamic>;
    final cartProvider = Provider.of<CartProvider>(context);

    Timestamp timestamp = recipeData['timestamp'];
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(dateTime);


    String formatCookingTime(int cookingTime) {
      if (cookingTime >= 100) {
        int hours = cookingTime ~/ 100;
        int minutes = cookingTime % 100;
        return '$hours hour${hours > 1 ? 's' : ''} ${minutes} mins';
      } else {
        return '$cookingTime mins';
      }
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextWidget(
          text: 'Recipes Details',
          color: color,
          textSize: 24,
          isTitle: true,
        ),
        titleSpacing: 10,
        iconTheme: IconThemeData(
          color: color,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom: 150.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    width: MediaQuery.of(context)
                        .size
                        .width,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Chewie(controller: _chewieController);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(
                        16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Center(
                            child: Text(
                              recipeData['text'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Description: ${recipeData['description']}',
                                  style: TextStyle(fontSize: 16, color: color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Instructions: ${recipeData['instructions']}',
                                  style: TextStyle(fontSize: 16, color: color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Ingredients: ${recipeData['ingredients']}',
                            style: TextStyle(fontSize: 16, color: color),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Text(
                                'Cooking Time: ${formatCookingTime(recipeData['cookingTime'])}',
                                style: TextStyle(fontSize: 16, color: color),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                IconlyLight.timeCircle,
                                size: 20,
                                color: color,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Difficulty Level: ${recipeData['difficultyLevel']}',
                            style: TextStyle(fontSize: 16, color: color),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Shared by: ${recipeData['userName']}',
                            style: TextStyle(fontSize: 16, color: color),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          'Time Posted: ${formattedTime}',
                          style: TextStyle(fontSize: 16, color: color),
                        ),
                        const SizedBox(
                          height: 12,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: const EdgeInsets.all(0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productInCart
                          ? "$productName is already in your Cart."
                          : 'Would you like to add $productName to your cart?',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          child: Image.network(
                            productImage,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              } else {
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            (loadingProgress
                                                    .expectedTotalBytes ??
                                                1)
                                        : null,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                        Colors.cyan),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Price: RM $productPrice',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Total Sold: ${productSold.toString()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () async {
                                  _addItemToCart(recipeData['productID'], productName);
                                },
                                child: Icon(
                                  productInCart ? Icons.check : IconlyLight.buy,
                                  color: Colors.black,
                                  size: 30,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
