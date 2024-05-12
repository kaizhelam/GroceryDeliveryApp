import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class OrderModel with ChangeNotifier {
  final String orderId, userId, productId, userName, price, imageUrl, quantity, totalPayment, address;
  final int orderStatus, rateStatus;
  final Timestamp orderDate;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.productId,
    required this.userName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.orderDate,
    required this.orderStatus,
    required this.totalPayment,
    required this.rateStatus,
    required this.address,
  });
}
