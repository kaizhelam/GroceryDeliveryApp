import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/models/orders_model.dart';
import 'package:provider/provider.dart';

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
  late String orderDateToShow;

  @override
  Widget build(BuildContext context) {
    final ordersModel = Provider.of<OrderModel>(context);
    final Color color = Utils(context).color;
    Size size = Utils(context).getScreenSize;
    final productProvider = Provider.of<ProductsProvider>(context);
    final getCurrProduct = productProvider.findProdById(ordersModel.productId);

    Timestamp orderTimestamp = ordersModel.orderDate;
    DateTime orderDateTime = orderTimestamp.toDate().toLocal();
    String formattedDateTime =
    DateFormat('yyyy-MM-dd hh:mm:ss a').format(orderDateTime);

    return ListTile(
      leading: FancyShimmerImage(
        width: size.width * 0.2,
        imageUrl: getCurrProduct.imageUrl,
        boxFit: BoxFit.fill,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: '${getCurrProduct.title} x${ordersModel.quantity}',
            color: color,
            textSize: 18,
          ),
          Text(
            'Paid: \$${double.parse(ordersModel.price).toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, color: color),
          ),
          Text(
            formattedDateTime,
            style: TextStyle(fontSize: 16, color: color),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.pending_actions,
              color: ordersModel.orderStatus == 0 ? Colors.red : Colors.green,
            ),
            iconSize: 30,
            onPressed: () {
              // Add your onPressed function here
              print('Pending button pressed');
            },
          ),
          const SizedBox(width: 5), // Add some space between the icon and text
          Text(
            ordersModel.orderStatus == 0 ? 'Pending' : 'Accepted',
            style: TextStyle(
              fontSize: 14,
              color: ordersModel.orderStatus == 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}
