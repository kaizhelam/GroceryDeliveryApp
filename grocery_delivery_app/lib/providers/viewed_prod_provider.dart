import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/models/viewed_model.dart';


class ViewedProdProvider with ChangeNotifier {
  Map<String, ViewedProdModel> _viewedProdlistItems = {};

  Map<String, ViewedProdModel> get getViewedProdlistItems {
    return _viewedProdlistItems;
  }

  void addProductToHistory({required String productId}) {
    _viewedProdlistItems.putIfAbsent(
      productId,
      () => ViewedProdModel(
        id: DateTime.now().toString(),
        productId: productId,
      ),
    );
    notifyListeners();
  }

  void clearHistory(BuildContext context) {
    _viewedProdlistItems.clear();
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All Item removed from your history'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}
