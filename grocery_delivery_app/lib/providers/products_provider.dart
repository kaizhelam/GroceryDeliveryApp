import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../models/products_model.dart';

class ProductsProvider with ChangeNotifier {
  static List<ProductModel> _productsList = [];
  List<ProductModel> get getProducts {
    return _productsList;
  }

  List<ProductModel> get getOnSaleProducts {
    return _productsList.where((element) => element.isOnSale).toList();
  }

  Future<void> fetchProducts() async {
    await FirebaseFirestore.instance
        .collection('products')
        .get()
        .then((QuerySnapshot productSnapshot) {
          _productsList = [];
          // _productsList.clear();
      productSnapshot.docs.forEach((element) {
        _productsList.insert(
            0,
            ProductModel(
              id: element.get('id'),
              title: element.get('title'),
              imageUrl: element.get('imageUrl'),
              productCategoryName: element.get('productCategoryName'),
              productDescription: element.get('productDescription'),
              price: double.parse(element.get('price')),
              salePrice: element.get('salePrice'),
              isOnSale: element.get('isOnSale'),
              isPiece: element.get('isPiece'),
              productSold : element.get('productSold'),
            ));
      });
    });
    notifyListeners();
  }

  ProductModel findProdById(String productId) {
    return _productsList.firstWhere((element) => element.id == productId);
  }

  List<ProductModel> findByCategory(String categoryName) {
    return _productsList
        .where((element) => element.productCategoryName
            .toLowerCase()
            .contains(categoryName.toLowerCase()))
        .toList();
  }

  List<ProductModel> searchQuery(String searchText) {
    List<ProductModel> _searchList = _productsList
        .where(
          (element) => element.title.toLowerCase().contains(
                searchText.toLowerCase(),
              ),
        )
        .toList();
    return _searchList;
  }

  // static final List<ProductModel> _productsList = [
  //   ProductModel(
  //     id: 'Apricot',
  //     title: 'Apricot',
  //     price: 0.99,
  //     salePrice: 0.49,
  //     imageUrl: 'https://i.ibb.co/F0s3FHQ/Apricots.png',
  //     productCategoryName: 'Fruits',
  //     isOnSale: true,
  //     isPiece: false,
  //   ),
  //   ProductModel(
  //     id: 'Avocado',
  //     title: 'Avocado',
  //     price: 0.88,
  //     salePrice: 0.5,
  //     imageUrl: 'https://i.ibb.co/9VKXw5L/Avocat.png',
  //     productCategoryName: 'Fruits',
  //     isOnSale: false,
  //     isPiece: true,
  //   ),
  //  ];
}
