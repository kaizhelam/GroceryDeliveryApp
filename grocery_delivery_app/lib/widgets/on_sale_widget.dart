import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_delivery_app/services/utils.dart';
import 'package:grocery_delivery_app/widgets/heart_btn.dart';
import 'package:grocery_delivery_app/widgets/price_widget.dart';
import 'package:grocery_delivery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../consts/firebase_consts.dart';
import '../inner_screens/product_details.dart';
import '../models/products_model.dart';
import '../providers/cart_provider.dart';
import '../providers/viewed_prod_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/global_method.dart';

class OnSaleWidget extends StatefulWidget {
  const OnSaleWidget({super.key});

  @override
  State<OnSaleWidget> createState() => _OnSaleWidgetState();
}

class _OnSaleWidgetState extends State<OnSaleWidget> {
  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    final theme = Utils(context).getTheme;
    Size size = Utils(context).getScreenSize;
    final productModel = Provider.of<ProductModel>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    bool? _isInCart = cartProvider.getCardItems.containsKey(productModel.id);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    bool? _isInWishlist = wishlistProvider.getWishlistItems.containsKey(productModel.id);
    final viewedProdProvider = Provider.of<ViewedProdProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            viewedProdProvider.addProductToHistory(productId: productModel.id);
            Navigator.pushNamed(context, ProductDetails.routeName,
                arguments: productModel.id);
            // GlobalMethods.navigateTo(
            //     ctx: context, routeName: ProductDetails.routeName);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FancyShimmerImage(
                      imageUrl: productModel.imageUrl,
                      height: size.width * 0.22,
                      width: size.width * 0.22,
                      boxFit: BoxFit.fill,
                    ),
                    Column(
                      children: [
                        TextWidget(
                          text: productModel.isPiece ? '1Item' : '1Kg',
                          color: color,
                          textSize: 18,
                          isTitle: true,
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _isInCart ? null : () async{
                                final User? user = authInstance.currentUser;
                                if (user == null) {
                                  GlobalMethods.errorDialog(
                                      subtitle: 'No user found, Please login in first',
                                      context: context);
                                  return;
                                }
                                await GlobalMethods.addToCart(productId: productModel.id, quantity: 1, context: context);
                                await cartProvider.fetchCart();
                                // cartProvider.addProductsToCard(
                                //     productId: productModel.id,
                                //     quantity: 1);
                              },
                              child: Icon(
                                _isInCart ?
                                IconlyBold.bag2 : IconlyLight.bag2,
                                size: 22,
                                color: _isInCart? Colors.cyan : color,
                              ),
                            ),
                            HeartBTN(productId: productModel.id,
                              isInWishlist: _isInWishlist,),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 3,),
                PriceWidget(
                  salePrice: productModel.salePrice,
                  price: productModel.price,
                  textPrice: '1',
                  isOnSale: true,),
                const SizedBox(
                  height: 5,
                ),
                TextWidget(
                  text: productModel.title,
                  color: color,
                  textSize: 18,
                  isTitle: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
