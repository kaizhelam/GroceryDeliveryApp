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

enum OrderStatus {
  Pending,
  InProgress,
  ToDeliver,
  Delivered,
}


class OrderWidget extends StatefulWidget {
  const OrderWidget({Key? key}) : super(key: key);

  @override
  State<OrderWidget> createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderWidget> {
  final User? user = authInstance.currentUser;
  bool _isLoading = false;
  String? _name;
  String? _userprofileImage;
  TextEditingController reviewController = TextEditingController();

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

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
        _userprofileImage = userDoc.get('profileImage');
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

    int myRateStatus = ordersModel.rateStatus;
    String orderId = ordersModel.orderId;

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
            if (myOrderStatus == 3)
              GestureDetector(
                onTap: () {
                  if(myRateStatus != 1){
                    _giveRating(
                        context, getCurrProduct.title, getCurrProduct.id, _name!, orderId, _userprofileImage!);
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
                      myRateStatus == 0 ? 'Rate & Review' : 'Product Rated',
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
          padding: const EdgeInsets.only(left: 13),
          child: GestureDetector(
            onTap: () {
              // Show dialog with timeline based on orderStatus when icon is tapped
              _showTimelineDialog(context, ordersModel.orderStatus, ordersModel.address);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.more_horiz,
                  size: 40,
                  color: Colors.white,// Adjust icon size as needed
                ),
              ],
            ),
          ),
        ),
    );
  }



  void _showTimelineDialog(BuildContext context, int orderStatus, String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Timeline'),
          content: SizedBox(
            width: double.maxFinite,
            height: 270, // Set the height according to your content
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: OrderStatus.values.length,
              itemBuilder: (context, index) {
                final currentStatus = OrderStatus.values[index];
                bool showSubtitle = currentStatus == OrderStatus.Delivered; // Show subtitle for Delivered status

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 2, // Width of the vertical line
                      height: 60, // Height of the vertical line (adjust as needed)
                      color: _getStatusColor(currentStatus, orderStatus),
                    ),
                    SizedBox(width: 15), // Add spacing between the vertical line and the circle avatar
                    CircleAvatar(
                      backgroundColor: _getStatusColor(currentStatus, orderStatus),
                      radius: 20, // Adjust the radius of the CircleAvatar
                      child: Text((index + 1).toString(), style: TextStyle(color: Colors.white),),
                    ),
                    SizedBox(width: 10), // Add spacing between the circle avatar and the text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getStatusTitle(currentStatus), style: TextStyle(color: Colors.black, fontSize: 17),),
                          if (showSubtitle) // Conditionally show the subtitle for Delivered status
                            Text(address, style: TextStyle(color: Colors.black),),
                        ],
                      ),
                    ),
                    SizedBox(height: 20), // Add padding at the bottom of the CircleAvatar
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close', style: TextStyle(color: Colors.cyan),),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(OrderStatus status, int currentStatus) {
    if (status.index == currentStatus) {
      return Colors.cyan;
    } else if (status.index < currentStatus) {
      return Colors.cyan;
    } else {
      return Colors.black;
    }
  }

  String _getStatusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.Pending:
        return 'Pending';
      case OrderStatus.InProgress:
        return 'In Progress';
      case OrderStatus.ToDeliver:
        return 'To Deliver';
      case OrderStatus.Delivered:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }

  String _getStatusSubtitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.Pending:
        return 'Subtitle for Pending';
      case OrderStatus.InProgress:
        return 'Subtitle for In Progress';
      case OrderStatus.ToDeliver:
        return 'Subtitle for To Deliver';
      case OrderStatus.Delivered:
        return 'Subtitle for Delivered';
      default:
        return 'Unknown Subtitle';
    }
  }



  void _giveRating(BuildContext context, String title, String id, String name, String orderId, String userprofileImage) {
    final Color color = Utils(context).color;
    int selectedRating = 0; // Default selected rating

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
                      style: const TextStyle(color: Colors.black, fontSize: 14),
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
                      addRatingReview(context, selectedRating, reviewController.text, title, id, currentDateTime, name, orderId, userprofileImage);
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

  void addRatingReview(BuildContext context, int selectedRating, String review, String title, String id, String currentDateTime, String name, String orderId, String userprofileImage) async {
    final User? user = authInstance.currentUser;
    final _uid = user!.uid;
    final cartId = const Uuid().v4();

    print(id);

      try {
        await FirebaseFirestore.instance.collection('products').doc(id).update({
          'ratingReview': FieldValue.arrayUnion([
            {
              'Name': name,
              'Title': title,
              'Rate': selectedRating,
              'Review': review,
              'currentDateTime' : currentDateTime,
              'profileImage' : userprofileImage
            }
          ])
        });

        try {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .update({
            'rateStatus': 1,
          });
          setState(() {

          });
        } catch (error) {
          print('Error updating document: $error');
        }

        Fluttertoast.showToast(
            msg: "Your Rating Is Added",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.cyan,
            textColor: Colors.white,
            fontSize: 13);
      } catch (error) {
        print(error.toString());
      }
    }
  }
