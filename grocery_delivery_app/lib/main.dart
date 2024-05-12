import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grocery_delivery_app/consts/theme_data.dart';
import 'package:grocery_delivery_app/inner_screens/feeds_screen.dart';
import 'package:grocery_delivery_app/inner_screens/on_sale_screen.dart';
import 'package:grocery_delivery_app/provider/dark_theme_provider.dart';
import 'package:grocery_delivery_app/providers/cart_provider.dart';
import 'package:grocery_delivery_app/providers/orders_provider.dart';
import 'package:grocery_delivery_app/providers/products_provider.dart';
import 'package:grocery_delivery_app/providers/viewed_prod_provider.dart';
import 'package:grocery_delivery_app/providers/wishlist_provider.dart';
import 'package:grocery_delivery_app/screens/auth/forget_pass.dart';
import 'package:grocery_delivery_app/screens/auth/login.dart';
import 'package:grocery_delivery_app/screens/auth/register.dart';
import 'package:grocery_delivery_app/screens/btm_bar.dart';
import 'package:grocery_delivery_app/screens/orders/orders_screen.dart';
import 'package:grocery_delivery_app/screens/viewed_recently/viewed_recently.dart';
import 'package:grocery_delivery_app/screens/wishlist/wishlist_screen.dart';
import 'package:grocery_delivery_app/screens/wishlist/wishlist_widget.dart';
import 'package:provider/provider.dart';

import 'fetch_screen.dart';
import 'firebase_options.dart';
import 'inner_screens/cat_screen.dart';
import 'inner_screens/product_details.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'basic_notification',
          channelDescription: 'test',
        )
      ],
      debug: true);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  void getCurrentAppTheme() async {
    themeChangeProvider.setDarkTheme =
        await themeChangeProvider.darkThemePrefs.getTheme();
  }

  @override
  void initState() {
    getCurrentAppTheme();
    super.initState();
  }

  final Future<FirebaseApp> _firebaseInitialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _firebaseInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                  body: Center(
                child: CircularProgressIndicator(),
              )),
            );
          } else if (snapshot.hasError) {
            const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                  body: Center(
                child: Text('An error occurred'),
              )),
            );
          }
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) {
                return themeChangeProvider;
              }),
              ChangeNotifierProvider(
                create: (_) => ProductsProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => CartProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => WishlistProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => ViewedProdProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => OrdersProvider(),
              ),
            ],
            child: Consumer<DarkThemeProvider>(
                builder: (context, themeProvider, child) {
              return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Grocery Delivery App',
                  theme: Styles.themeData(themeProvider.getDarkTheme, context),
                  home: const FetchScreen(),
                  routes: {
                    OnSaleScreen.routeName: (ctx) => const OnSaleScreen(),
                    FeedsScreen.routeName: (ctx) => const FeedsScreen(),
                    ProductDetails.routeName: (ctx) => const ProductDetails(),
                    WishlistScreen.routeName: (ctx) => const WishlistScreen(),
                    OrdersScreen.routeName: (ctx) => const OrdersScreen(),
                    ViewedRecentlyScreen.routeName: (ctx) =>
                        const ViewedRecentlyScreen(),
                    RegisterScreen.routeName: (ctx) => const RegisterScreen(),
                    LoginScreen.routeName: (ctx) => const LoginScreen(),
                    ForgetPasswordScreen.routeName: (ctx) =>
                        const ForgetPasswordScreen(),
                    CategoryScreen.routeName: (ctx) => const CategoryScreen(),
                  });
            }),
          );
        });
  }
}
