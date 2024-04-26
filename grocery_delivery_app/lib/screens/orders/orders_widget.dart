import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app/models/orders_model.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../consts/firebase_consts.dart';
import '../../inner_screens/product_details.dart';
import '../../providers/orders_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/global_method.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';
import 'package:intl/intl.dart';

class OrderWidget extends StatefulWidget {
  const OrderWidget({Key? key}) : super(key: key);

  @override
  State<OrderWidget> createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderWidget> {
  final User? user = authInstance.currentUser;
  bool _isLoading = false;
  String? _name;
  bool rate = false;

  void initState() {
    getUserData();
    super.initState();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      String _uid = user!.uid;

      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (userDoc == null) {
        return;
      } else {
        _name = userDoc.get('name');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      GlobalMethods.errorDialog(subtitle: '$error', context: context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersModel = Provider.of<OrderModel>(context);
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final productProvider = Provider.of<ProductsProvider>(context);
    final getCurrProduct = productProvider.findProdById(ordersModel.productId);

    Timestamp orderTimestamp = ordersModel.orderDate;
    DateTime orderDateTime = orderTimestamp.toDate().toLocal();
    String formattedDateTime = DateFormat('yyyy-MM-dd').format(orderDateTime) +
        '\n' +
        DateFormat('hh:mm:ss a').format(orderDateTime);

    int myOrderStatus = ordersModel.orderStatus;

    setState(() {
      myOrderStatus;
    });

    return ListTile(
      leading: FancyShimmerImage(
        width: size.width * 0.2,
        imageUrl: getCurrProduct.imageUrl,
        boxFit: BoxFit.fill,
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: '${getCurrProduct.title} x${ordersModel.quantity}',
              color: color,
              textSize: 14,
            ),
            Text(
              'Total Paid: RM${double.parse(ordersModel.totalPayment).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, color: color),
            ),
            Text(
              formattedDateTime,
              style: TextStyle(fontSize: 14, color: color),
            ),
            SizedBox(
              height: 8,
            ),
            if (myOrderStatus != 0)
              GestureDetector(
                onTap: () {
                  if(!rate){
                    _giveRating(
                        context, getCurrProduct.title, getCurrProduct.id, _name!);
                  }else{
                    Fluttertoast.showToast(
                        msg: "You Rated This Product",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 13);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.rate_review,
                      color: Colors.cyan, // Change icon color as needed
                      size: 16, // Adjust icon size as needed
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    Text(
                      rate ? 'Product Rated' : 'Rate & Review',
                      style: const TextStyle(
                        fontSize: 14, // Adjust font size as needed
                        color: Colors.cyan, // Change text color as needed
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(
            left: 13), // Adjust the amount of space as needed
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ordersModel.orderStatus == 0 ? 'Pending' : 'Accepted',
              style: TextStyle(
                  fontSize: 14,
                  color:
                      ordersModel.orderStatus == 0 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _giveRating(BuildContext context, String title, String id, String name) {
    final Color color = Utils(context).color;
    int selectedRating = 0; // Default selected rating
    TextEditingController reviewController = TextEditingController();

    DateTime currentDate = DateTime.now();
    String currentDateTime =
        '${currentDate.year}-${currentDate.month}-${currentDate.day}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              // backgroundColor: Colors.grey[900],
              title: Text(
                'Rate & Review',
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Star rating selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(5, (index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 0),
                            child: IconButton(
                              icon: Icon(
                                index < selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.orange,
                              ),
                              iconSize: 30,
                              onPressed: () {
                                setState(() {
                                  selectedRating = index + 1;
                                });
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 10),
                    // Review text field
                    TextFormField(
                      controller: reviewController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Write Your Review',
                        labelStyle:
                            TextStyle(color: Colors.black, fontSize: 14),
                        // Color of the label text
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          // Border color when enabled
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          // Border color when focused
                        ),
                      ),
                      cursorColor: Colors.black,
                      // Color of the cursor
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    if (selectedRating == 0 || reviewController.text.isEmpty) {
                      // Show error message if rating or review is not provided
                      Fluttertoast.showToast(
                          msg: "Please Don\'t Not Empty The Rating Or Review",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 13);
                    } else {
                      addRatingReview(context, selectedRating, reviewController.text, title, id, currentDateTime, name);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.cyan),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.cyan),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void addRatingReview(BuildContext context, int selectedRating, String review, String title, String id, String currentDateTime, String name) async {
    final User? user = authInstance.currentUser;
    final _uid = user!.uid;
    final cartId = const Uuid().v4();

    print(selectedRating);
    print(review);
    print(title);
    print(id);
    print(currentDateTime);
    print(name);
      try {
        await FirebaseFirestore.instance.collection('products').doc(id).update({
          'ratingReview': FieldValue.arrayUnion([
            {
              'Name': name,
              'Title': title,
              'Rate': selectedRating,
              'Review': review,
              'currentDateTime' : currentDateTime
            }
          ])
        });
        Fluttertoast.showToast(
            msg: "Your Rating Is Added",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.cyan,
            textColor: Colors.white,
            fontSize: 13);
        rate = true;
      } catch (error) {
        print(error.toString());
      }
    }
  }
