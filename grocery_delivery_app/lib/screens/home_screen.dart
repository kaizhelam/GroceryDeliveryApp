import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_delivery_app/inner_screens/feeds_screen.dart';
import 'package:grocery_delivery_app/inner_screens/on_sale_screen.dart';
import 'package:grocery_delivery_app/services/global_method.dart';
import 'package:grocery_delivery_app/widgets/feed_items.dart';
import 'package:grocery_delivery_app/widgets/on_sale_widget.dart';
import 'package:grocery_delivery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../consts/contss.dart';
import '../models/products_model.dart';
import '../providers/products_provider.dart';
import '../services/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final Utils utils = Utils(context);
    final themeState = utils.getTheme;
    final Color color = Utils(context).color;
    Size size = utils.getScreenSize;
    final productProviders = Provider.of<ProductsProvider>(context);
    List<ProductModel> allProducts = productProviders.getProducts;
    List<ProductModel> productOnSale = productProviders.getOnSaleProducts;

    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 63,
          elevation: 5,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: 'GoGrocery',
                color: color,
                textSize: 24,
                isTitle: true,
              ),
              SizedBox(height: 5,),
              TextWidget(
                text: 'Fresh. Fast. Delivered.',
                color: color, // Choose the color for your subtitle
                textSize: 14, // Adjust the size of your subtitle text
              ),
            ],
          ),
          titleSpacing: 10,
          automaticallyImplyLeading: false,
        ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: size.height * 0.20,
              child: Swiper(
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.asset(
                        Constss.offerImages[index],
                        fit: BoxFit.fill,
                      ),
                    ),
                  );
                },
                autoplay: true,
                itemCount: Constss.offerImages.length,
                pagination: const SwiperPagination(
                    alignment: Alignment.bottomCenter,
                    builder: DotSwiperPaginationBuilder(
                      color: Colors.white,
                      activeColor: Colors.cyan,
                    )
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                GlobalMethods.navigateTo(
                    ctx: context, routeName: OnSaleScreen.routeName);
              },
              child: TextWidget(
                text: 'Explore All',
                maxLines: 1,
                color: Colors.cyan,
                textSize: 20,
                isTitle: true,
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: Row(
                      children: [
                        TextWidget(
                          text: 'Hot Sale'.toUpperCase(),
                          color: Colors.red,
                          textSize: 22,
                          isTitle: true,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        const Icon(
                          IconlyLight.discount,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Flexible(
                  child: SizedBox(
                    height: size.height * 0.23,
                    child: ListView.builder(
                      itemCount: productOnSale.length < 10 ? productOnSale.length : 10,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (ctx, index) {
                        return ChangeNotifierProvider.value(
                            value: productOnSale[index],
                            child:const OnSaleWidget());
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidget(
                    text: 'Top Products',
                    color: color,
                    textSize: 22,
                    isTitle: true,
                  ),
                  TextButton(
                    onPressed: () {
                      print('error');
                      GlobalMethods.navigateTo(
                          ctx: context, routeName: FeedsScreen.routeName);
                    },
                    child: TextWidget(
                      text: 'Explore All',
                      maxLines: 1,
                      color: Colors.cyan,
                      textSize: 22,
                      isTitle: true,
                    ),
                  ),
                ],
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              padding: EdgeInsets.zero,
              // crossAxisSpacing: 10,r
              childAspectRatio: size.width / (size.height * 0.47),
              children: List.generate(
                allProducts.length < 4 ? allProducts.length : 4,
                    (index) {
                  return ChangeNotifierProvider.value(
                    value: allProducts[index],
                    child: const FeedsWidget(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
