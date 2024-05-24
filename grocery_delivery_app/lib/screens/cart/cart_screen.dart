import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
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
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  DateTime? _selectedDateTime;
  TextEditingController _noteMessage = TextEditingController();
  String? _noteMessageForDriver;
  double _deliveryFee = 4.90;

  @override
  void dispose() {
    _noteMessage.dispose();
    super.dispose();
  }

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
            title: 'Your Cart Is Empty',
            subtitle: 'Add Something and Start Order Now',
            buttonText: 'Shop Now',
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
                      title: 'Empty Your Cart',
                      subtitle: 'Are You Sure To Empty All Item From The Cart?',
                      fct: () async {
                        await cartProvider.clearOnlineCart();
                        cartProvider.clearLocalCart();
                        Fluttertoast.showToast(
                            msg: "All Item Removed From Your Cart",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 2,
                            backgroundColor: Colors.grey[200],
                            textColor: Colors.black,
                            fontSize: 13);
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
      final endDate =
          now.add(Duration(days: 7)); // Allow selection up to 7 days from now
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: endDate,
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.cyan, // Change text color to green
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
                  primary: Colors.cyan, // Change text color to green
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
              msg: "You Have Scheduled The Delivery Date & Time",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.cyan,
              textColor: Colors.white,
              fontSize: 13);
          print(_selectedDateTime);
        }
      }
    }

    DateTime now = DateTime.now().toUtc();

    // Create a DateTime object based on _selectedDateTime or current time
    DateTime orderDateTime = _selectedDateTime ?? now;

    // If Timestamp.now() is executed, add the UTC+8 offset and format the date and time
    if (_selectedDateTime == null) {
      orderDateTime = orderDateTime.add(Duration(hours: 0));
    }
    // Format the date and time
    String formattedDateTime =
        DateFormat('yyyy-MM-dd hh:mm:ss a').format(orderDateTime);

    void _noteForDriver() async {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Add a Note for Driver',
              style: TextStyle(fontSize: 19),
            ),
            content: TextField(
              controller: _noteMessage,
              maxLines: 5, // Set maxLines to 5
              decoration: InputDecoration(
                hintText: 'Enter your note here',
                hintStyle: TextStyle(color: Colors.grey),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors
                          .cyan), // Change the underline color when focused
                ), // Set the hint text color
              ),
              cursorColor: Colors.cyan,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  if (_noteMessage.text.isEmpty) {
                    Fluttertoast.showToast(
                        msg: "Please Key In Something...",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 13);
                    return;
                  } else {
                    Fluttertoast.showToast(
                        msg: "You have Added a Note To Our Driver",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.cyan,
                        textColor: Colors.white,
                        fontSize: 13);
                    Navigator.pop(context);
                    setState(() {
                      _noteMessageForDriver = _noteMessage.text;
                    });
                  }
                },
                child: Text(
                  'Add',
                  style: TextStyle(color: Colors.cyan),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.cyan),
                ),
              ),
            ],
          );
        },
      ).then((_) {
        // Update the state of the widget containing GestureDetector
        setState(() {});
      });
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        height: size.height * 0.33,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // Align buttons to stretch across the width
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        _showCardDialog(context, total, productDetailsList,
                            address!, orderDateTime, _noteMessageForDriver);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextWidget(
                          text: 'Check Out',
                          color: Colors.white,
                          textSize: 18,
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
              const SizedBox(height: 18), // Add some space between the buttons
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align elements to the start
                children: [
                  GestureDetector(
                    onTap: _presentDatePicker,
                    child: Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconlyLight.timeCircle,
                            color: color,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Schedule Delivery Date and Time *Optional',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Container(
                          height: 40, // Adjust the height as needed
                          child: Row(
                            children: [
                              Text(
                                _selectedDateTime != null
                                    ? 'Delivery Date and Time: ${DateFormat.yMd().add_jm().format(_selectedDateTime!)}'
                                    : 'By Default, The order place by Today',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: color,
                                ),
                              ),
                              SizedBox(width: 10),
                              if (_selectedDateTime != null)
                                Container(
                                  width: 24, // Fixed width for the icon
                                  height: 24, // Fixed height for the icon
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedDateTime = null;
                                        });
                                      },
                                      child: Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                        size: 24, // Adjust size as needed
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: color,
                    thickness: 1,
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: _noteForDriver,
                    child: Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconlyLight.message,
                            color: color,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Note for Driver *Optional',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Container(
                          height: 70, // Adjust the height as needed
                          child: Row(
                            children: [
                              Container(
                                width:
                                    300, // Set a specific width for the TextField container
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: color, // Set the border color
                                    width: 1, // Set the border width
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      5), // Optionally, add border radius
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal:
                                          8), // Add padding to TextField
                                  child: TextField(
                                    controller: _noteMessage,
                                    maxLines: null,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              // Add SizedBox for spacing between TextField and the remove icon
                              SizedBox(width: 5),
                              // Use if-else to check if the note message is not empty
                              if (_noteMessageForDriver != null)
                                Container(
                                  width: 24, // Fixed width for the icon
                                  height: 24, // Fixed height for the icon
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _noteMessage
                                              .clear(); // Clear the text
                                          _noteMessageForDriver =
                                              null; // Clear the note message
                                        });
                                      },
                                      child: Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                        size: 24, // Adjust size as needed
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
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
    DateTime orderDateTime,
    String? noteMessageForDriver,
  ) {

    DateTime newDateTime = orderDateTime.add(Duration(hours: 8));
    String formattedDateTime = DateFormat.yMd().add_jm().format(newDateTime);

    double totalPayment = _deliveryFee + total;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 1.5,
            child: AlertDialog(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
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
                              Icons.location_on,
                              color: Colors.black,
                              size: 18,
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
                    address.isEmpty ? 'No Address Found' : address,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Divider(
                    color: Colors.black,
                    thickness: 1,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var productDetails in productDetailsList)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                          return child;
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.cyan),
                                          ),
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
                        ],
                      ),
                    SizedBox(height: 10),
                    Text(
                      'Delivery Date & Time : ',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      _selectedDateTime == null
                          ? formattedDateTime
                          : DateFormat.yMd().add_jm().format(_selectedDateTime!),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Note for Driver : ',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      noteMessageForDriver != null
                          ? noteMessageForDriver
                          : 'No Note for Driver',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Merchandise Total : ',
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
                    Row(
                      children: [
                        Text(
                          'Delivery Fee : ',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'RM${_deliveryFee.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Total Payment : ',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'RM${totalPayment.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    String driverMessage = noteMessageForDriver ??
                        ""; // Check if null, if so, assign an empty string

                    if (address.isEmpty) {
                      Fluttertoast.showToast(
                          msg:
                              "Please Add Your Address Before Placing Any Order",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 13);
                    } else {
                      Navigator.of(context).pop(true);
                      // print(message);
                      _addPaymentMethod(context, address, orderDateTime,
                          driverMessage, totalPayment);
                    }
                  },
                  child: Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.cyan,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.cyan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addPaymentMethod(BuildContext context, String address,
      DateTime orderDateTime, String driverMessage, double totalPayment) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String _selectedPaymentMethod = '';
    final User? user = authInstance.currentUser;
    final _uid = user!.uid;
    final cartId = const Uuid().v4();

    // Add TextEditingController for card number, expiry date, and CVV
    TextEditingController _cardNumberController = TextEditingController();
    TextEditingController _expiryDateController = TextEditingController();
    TextEditingController _cvvController = TextEditingController();

    // Variable to store user's existing cards
    List<Map<String, String>> userCards = [];

    // Function to fetch user's existing cards from Firebase
    void fetchUserCards() {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get()
          .then((docSnapshot) {
        if (docSnapshot.exists) {
          final userCard = docSnapshot.data()?['userCard'];
          if (userCard != null && userCard is List) {
            userCards = List<Map<String, String>>.from(
                userCard.map((card) => Map<String, String>.from(card)));
          }
        }
      });
    }

    // Fetch user's existing cards when the dialog is built
    fetchUserCards();

    int? selectedIndex; // Track the index of the selected card

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: AlertDialog(
                title: Text(
                  'Select Your Payment Method',
                  style: TextStyle(fontSize: 17),
                ),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Center(
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Radio(
                                  value: 'Cash',
                                  groupValue: _selectedPaymentMethod,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPaymentMethod = value as String;
                                    });
                                  },
                                  activeColor: Colors.cyan,
                                ),
                                Text(
                                  'Cash',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Column(
                              children: [
                                Radio(
                                  value: 'Card',
                                  groupValue: _selectedPaymentMethod,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPaymentMethod = value as String;
                                    });
                                  },
                                  activeColor: Colors.cyan,
                                ),
                                Text(
                                  'Card',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      if (_selectedPaymentMethod == 'Card')
                        Column(
                          children: [
                            // Display existing cards
                            if (userCards.isNotEmpty)
                              Column(
                                children: [
                                  for (int i = 0; i < userCards.length; i++)
                                    ListTile(
                                      title: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Card Number: ${userCards[i]['cardNumber'] != null ? '*${userCards[i]['cardNumber']!.substring(userCards[i]['cardNumber']!.length - 4)}' : ''}',
                                                  style:
                                                      TextStyle(fontSize: 15),
                                                )
                                              ],
                                            ),
                                          ),
                                          Radio(
                                            value: i,
                                            groupValue: selectedIndex,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedIndex = value as int?;
                                              });
                                            },
                                            activeColor: Colors.cyan,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            // Text fields for card details
                            if (userCards.isEmpty) ...[
                              TextFormField(
                                controller:
                                    _cardNumberController, // Assign controller
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Card Number',
                                  hintText: 'XXXX XXXX XXXX XXXX',
                                  prefixIcon: Icon(Icons.credit_card,
                                      color: Colors.black54),
                                  hintStyle: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                  labelStyle: TextStyle(color: Colors.black),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.cyan),
                                  ),
                                ),
                                cursorColor: Colors.cyan,
                                validator: (value) {
                                  if (value?.length != 16) {
                                    return 'Please enter a valid \n16-digit card number';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller:
                                    _expiryDateController, // Assign controller
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Expiry Date (MM/YY)',
                                  labelText: 'Expiry Date',
                                  hintStyle: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                  labelStyle: TextStyle(color: Colors.black),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.cyan),
                                  ),
                                ),
                                cursorColor: Colors.cyan,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an expiry date';
                                  }
                                  if (!RegExp(r'^\d{2}\/\d{2}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid expiry date (MM/YY)';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _cvvController, // Assign controller
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  hintText: 'CVV',
                                  hintStyle: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                  labelStyle: TextStyle(color: Colors.black),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.cyan),
                                  ),
                                ),
                                cursorColor: Colors.cyan,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a CVV';
                                  }
                                  if (!RegExp(r'^[0-9]{3,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid CVV';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            if (_selectedPaymentMethod.isEmpty ?? true)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Please select a payment method',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      if (_selectedPaymentMethod == "Cash") {
                        _sendOrder(context, orderDateTime, driverMessage,
                            totalPayment, _selectedPaymentMethod);
                        Navigator.of(context).pop();
                        return;
                      }

                      if (_selectedPaymentMethod == null ||
                          _selectedPaymentMethod.isEmpty) {
                        Fluttertoast.showToast(
                            msg: "Please Select Your Payment Method",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 13);
                        return;
                      }

                      if (_formKey.currentState!.validate()) {
                        if (_cardNumberController.text.isNotEmpty &&
                            _expiryDateController.text.isNotEmpty &&
                            _cvvController.text.isNotEmpty &&
                            userCards.isEmpty) {
                          try {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .update({
                              'userCard': FieldValue.arrayUnion([
                                {
                                  'cardNumber': _cardNumberController.text,
                                  'expiryDate': _expiryDateController.text,
                                  'CVV': _cvvController.text,
                                }
                              ])
                            });
                            _sendOrder(context, orderDateTime, driverMessage,
                                totalPayment, _selectedPaymentMethod);
                            Navigator.of(context).pop();
                          } catch (error) {
                            Fluttertoast.showToast(
                                msg:
                                    "Something went wrong, please try again later",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 13);
                          }
                        }
                      }

                      if (userCards.isNotEmpty &&
                          _selectedPaymentMethod == "Card") {
                        if (selectedIndex == null) {
                          Fluttertoast.showToast(
                              msg: "Please select your card to make payment",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 13);
                        } else {
                          _sendOrder(context, orderDateTime, driverMessage,
                              totalPayment, _selectedPaymentMethod);
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: Text(
                      'Ok',
                      style: TextStyle(color: Colors.cyan),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.cyan),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sendOrder(BuildContext ctx, DateTime orderDateTime,
      String noteMessageForDriver, double totalPayment, String _selectedPaymentMethod) {
    User? user = authInstance.currentUser;
    String message = '';

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
          double lat = userSnapshot.get('lat');
          double long = userSnapshot.get('long');

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Dialog(
                backgroundColor: Colors.black,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Processing your Order',
                        style: TextStyle(color: Colors.white),
                      ),
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
            'noteForDriver': noteMessageForDriver,
            'totalPayment': totalPayment,
            'lat': lat,
            'long': long,
            'paymentMethod' :_selectedPaymentMethod,
            'rateStatus' : 0,
          });

          await cartProvider.clearOnlineCart();
          cartProvider.clearLocalCart();
          ordersProvider.fetchOrders();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OrdersScreen()),
          );
        } catch (error) {
          GlobalMethods.errorDialog(subtitle: error.toString(), context: ctx);
        } finally {}
      },
    );
  }
}
