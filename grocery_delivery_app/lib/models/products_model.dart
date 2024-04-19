import 'package:flutter/widgets.dart';

class ProductModel with ChangeNotifier{
  final String id, title, imageUrl, productCategoryName, productDescription;
  final double price, salePrice;
  final bool isOnSale, isPiece;
  final int productSold;

  ProductModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.productCategoryName,
    required this.price,
    required this.salePrice,
    required this.isOnSale,
    required this.isPiece,
    required this.productDescription,
    required this.productSold,
  });
}
