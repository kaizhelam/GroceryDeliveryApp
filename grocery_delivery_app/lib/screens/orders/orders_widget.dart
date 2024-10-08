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
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    getUserData();
    super.initState();
  }

  void triggerNotification() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: 'Your Order has Arrived',
        body: 'Thank you for using GoGrocery App. Have a great day!',
      ),
    );
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
            const SizedBox(
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
                    Icon(
                      myRateStatus == 0 ? Icons.rate_review : Icons.check,
                      color: myRateStatus == 0 ? Colors.orange : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      myRateStatus == 0 ? 'Rate & Review' : 'Product Rated',
                      style: TextStyle(
                        fontSize: 14,
                        color: myRateStatus == 0 ? Colors.orange : Colors.green,
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
              _showTimelineDialog(context, ordersModel.orderStatus, ordersModel.address);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.more_horiz,
                  size: 40,
                  color: Colors.white,
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
          title: const Text(
            'Order Status',
            style: TextStyle(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              height: 270,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: OrderStatus.values.length,
                itemBuilder: (context, index) {
                  final currentStatus = OrderStatus.values[index];
                  bool showSubtitle = currentStatus == OrderStatus.Delivered;
                  if (currentStatus == OrderStatus.Delivered && currentStatus.index == orderStatus) {
                    triggerNotification();
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 2,
                        height: 60,
                        color: _getStatusColor(currentStatus, orderStatus),
                      ),
                      const SizedBox(width: 15),
                      CircleAvatar(
                        backgroundColor: _getStatusColor(currentStatus, orderStatus),
                        radius: 20,
                        child: Text(
                          (index + 1).toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusTitle(currentStatus),
                              style: const TextStyle(color: Colors.black, fontSize: 15),
                            ),
                            if (showSubtitle)
                              Text(address, style: const TextStyle(color: Colors.black),),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(OrderStatus status, int currentStatus) {
    if (status.index == currentStatus) {
      return Colors.green;
    } else if (status.index < currentStatus) {
      return Colors.green;
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
    int selectedRating = 0;
    DateTime currentDate = DateTime.now();
    String currentDateTime = '${currentDate.year}-${currentDate.month}-${currentDate.day}';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Rate & Review',
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
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
                    const SizedBox(height: 10),
                    // Review text field
                    TextFormField(
                      controller: reviewController,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Write Your Review',
                        labelStyle:
                            TextStyle(color: Colors.black, fontSize: 14),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
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
                    'Add',
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
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 13);
      } catch (error) {
        print(error.toString());
      }
    }
  }
