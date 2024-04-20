import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app/inner_screens/location_screen.dart';
import 'package:grocery_delivery_app/screens/orders/orders_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../consts/firebase_consts.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/global_method.dart';
import '../../services/utils.dart';
import '../../widgets/empty.screen.dart';
import '../../widgets/text_widget.dart';
import 'cart_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  DateTime? _selectedDateTime;

  @override
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
        title: 'Order Placed Successfully',
        body: 'Your order is in progress. Have a great day!',
      ),
    );
  }

  final User? user = authInstance.currentUser;
  bool _isLoading = false;
  String? address;

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
        address = userDoc.get('shippingAddress');
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
    Size size = Utils(context).getScreenSize;
    final Color color = Utils(context).color;
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemList =
        cartProvider.getCardItems.values.toList().reversed.toList();

    return cartItemList.isEmpty
        ? const EmptyScreen(
            title: 'Your cart is empty',
            subtitle: 'Add something and order now',
            buttonText: 'Shop now',
            imagePath: 'assets/images/cart.png',
          )
        : Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: TextWidget(
                text: 'Cart (${cartItemList.length})',
                color: color,
                textSize: 22,
                isTitle: true,
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    GlobalMethods.warningDialog(
                      title: 'Empty your cart?',
                      subtitle: 'Are you sure',
                      fct: () async {
                        await cartProvider.clearOnlineCart();
                        cartProvider.clearLocalCart();
                      },
                      context: context,
                    );
                  },
                  icon: Icon(IconlyBroken.delete, color: color),
                ),
              ],
            ),
            body: Column(
              children: [
                _checkout(ctx: context),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItemList.length,
                    itemBuilder: (ctx, index) {
                      return ChangeNotifierProvider.value(
                          value: cartItemList[index],
                          child: CartWidget(q: cartItemList[index].quantity));
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Widget _checkout({required BuildContext ctx}) {
    Size size = Utils(ctx).getScreenSize;
    final Color color = Utils(ctx).color;
    final cartProvider = Provider.of<CartProvider>(ctx);
    final productProvider = Provider.of<ProductsProvider>(ctx);
    final ordersProvider = Provider.of<OrdersProvider>(ctx);

    double total = 0.0;
    List<Map<String, dynamic>> productDetailsList = [];

    cartProvider.getCardItems.forEach((key, value) {
      final getCurrProduct = productProvider.findProdById(value.productId);
      final imageUrl = getCurrProduct.imageUrl;
      final productTitle = getCurrProduct.title;
      final productQuantity = value.quantity;
      total += (getCurrProduct.isOnSale
              ? getCurrProduct.salePrice
              : getCurrProduct.price) *
          productQuantity;

      // Add product details to the list
      productDetailsList.add({
        'imageUrl': imageUrl,
        'title': productTitle,
        'quantity': productQuantity,
      });
    });
    productDetailsList = productDetailsList.reversed.toList();

    final cartItemList =
        cartProvider.getCardItems.values.toList().reversed.toList();

    void _presentDatePicker() async {
      final now = DateTime.now();
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: DateTime(now.year + 1, now.month, now.day),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.green, // Change text color to green
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.green, // Change text color to green
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          final selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          setState(() {
            _selectedDateTime = selectedDateTime;
          });
          await Fluttertoast.showToast(
            msg: "You have schedule your delivery date & time",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
          print(_selectedDateTime);
        }
      }
    }

    DateTime now = DateTime.now().toUtc();

    // Create a DateTime object based on _selectedDateTime or current time
    DateTime orderDateTime = _selectedDateTime ?? now;

    // If Timestamp.now() is executed, add the UTC+8 offset and format the date and time
    if (_selectedDateTime == null) {
      orderDateTime = orderDateTime.add(Duration(hours: 8));
    }
    // Format the date and time
    String formattedDateTime =
        DateFormat('yyyy-MM-dd hh:mm:ss a').format(orderDateTime);

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        height: size.height * 0.17,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // Align buttons to stretch across the width
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        _showCardDialog(context, total, productDetailsList,
                            address!, orderDateTime);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextWidget(
                          text: 'Check Out',
                          color: Colors.white,
                          textSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FittedBox(
                    child: TextWidget(
                      text: 'Total: RM${total.toStringAsFixed(2)}',
                      color: color,
                      textSize: 18,
                      isTitle: true,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8), // Add some space between the buttons
              ElevatedButton.icon(
                onPressed: _presentDatePicker, // Add an icon
                label: const Text(
                  'Schedule Delivery time and date',
                  style: TextStyle(
                    fontSize: 18, // Adjust the font size as needed
                  ),
                ), // Empty text
                icon: const Icon(Icons.schedule),
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  backgroundColor: MaterialStateProperty.all(
                      Colors.green), // Specify the background color
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextWidget(
                  text: _selectedDateTime != null
                      ? 'Delivery Date and Time: ${DateFormat.yMd().add_jm().format(_selectedDateTime!)}'
                      : '',
                  color: color,
                  textSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardDialog(
      BuildContext context,
      double total,
      List<Map<String, dynamic>> productDetailsList,
      String address,
      DateTime orderDateTime) {
    // final Color color = Utils(context).color;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width *
                1.5, // Adjust the width as needed
            child: AlertDialog(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 24, vertical: 20), // Adjust padding as needed
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15), // Adjust border radius as needed
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Icon(
                              Icons.location_on, // Delivery address icon
                              color: Colors.black,
                              size: 18, // Adjust the size of the icon as needed
                            ),
                          ),
                        ),
                        TextSpan(
                          text: 'Delivery Address:',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    address,
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  SizedBox(height: 5),
                  Divider(
                    color: Colors.black, // Set the color of the divider
                    thickness: 1, // Set the thickness of the divider
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var productDetails in productDetailsList)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            child: Stack(
                              children: [
                                Image.network(
                                  productDetails['imageUrl'],
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child; // Return the actual image when loading is complete
                                    }
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productDetails['title'],
                                style: TextStyle(color: Colors.black),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'x${productDetails['quantity']}',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Total price: ',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'RM${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Add more widgets as needed
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    _sendOrder(context, orderDateTime);
                    Navigator.of(context).pop(true); // Return true for confirm
                  },
                  child: Text('Confirm'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Return false for cancel
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendOrder(BuildContext ctx, DateTime orderDateTime) {
    User? user = authInstance.currentUser;

    final productProvider = Provider.of<ProductsProvider>(ctx, listen: false);
    final cartProvider = Provider.of<CartProvider>(ctx, listen: false);
    final ordersProvider = Provider.of<OrdersProvider>(ctx, listen: false);

    double total = 0.0;
    cartProvider.getCardItems.forEach(
      (key, value) async {
        final getCurrProduct = productProvider.findProdById(
          value.productId,
        );
        total += (getCurrProduct.isOnSale
                ? getCurrProduct.salePrice
                : getCurrProduct.price) *
            value.quantity;

        try {
          final orderId = const Uuid().v4();
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
          String shippingAddress = userSnapshot.get('shippingAddress');
          String phoneNumber = userSnapshot.get('phoneNumber');

          if (shippingAddress == 'Empty' || shippingAddress.isEmpty) {
            Fluttertoast.showToast(
                msg: "Please add your address before placing the order",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.grey.shade600,
                textColor: Colors.white,
                fontSize: 16.0);
          } else {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Dialog(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Processing Order...'),
                      ],
                    ),
                  ),
                );
              },
            );
            triggerNotification();
            await FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .set({
              'orderId': orderId,
              'userId': user!.uid,
              'productId': value.productId,
              'price': (getCurrProduct.isOnSale
                  ? getCurrProduct.salePrice
                  : getCurrProduct.price) *
                  value.quantity,
              'totalPrice': total,
              'quantity': value.quantity,
              'imageUrl': getCurrProduct.imageUrl,
              'userName': user.displayName,
              'orderDate': orderDateTime,
              'orderStatus': 0,
              'shippingAddress': shippingAddress,
              'phoneNumber': phoneNumber,
              'title': getCurrProduct.title,
            });

            await cartProvider.clearOnlineCart();
            cartProvider.clearLocalCart();
            ordersProvider.fetchOrders();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OrdersScreen()),
            );
          }
        } catch (error) {
          GlobalMethods.errorDialog(subtitle: error.toString(), context: ctx);
        } finally {}
      },
    );
  }
}
