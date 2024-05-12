import 'package:badges/badges.dart%20';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_delivery_app/screens/categories.dart';
import 'package:grocery_delivery_app/screens/home_screen.dart';
import 'package:grocery_delivery_app/screens/recipes_page.dart';
import 'package:grocery_delivery_app/screens/user.dart';
import 'package:provider/provider.dart';

import '../provider/dark_theme_provider.dart';
import '../providers/cart_provider.dart';
import 'cart/cart_screen.dart';
import 'package:badges/badges.dart' as badges;

class BottomBarScreen extends StatefulWidget {
  const BottomBarScreen({super.key});

  @override
  State<BottomBarScreen> createState() => _BottomBarScreenState();
}

class _BottomBarScreenState extends State<BottomBarScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {'page': const HomeScreen(), 'title': 'Home Screen'},
    {'page': CategoriesScreen(), 'title': 'Categories Screen'},
    {'page': const CartScreen(), 'title': 'Cart Screen'},
    {'page': const RecipesScreen(), 'title': 'Recipes Screen'},
    {'page': const UserScreen(), 'title': 'User Screen'},
  ];

  void _selectedPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    bool _isDark = themeState.getDarkTheme;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(_pages[_selectedIndex]['title']),
      // ),
      body: _pages[_selectedIndex]['page'],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _isDark ? Theme.of(context).cardColor : Colors.white,
        type: BottomNavigationBarType.fixed,
        // showSelectedLabels: false,
        // showUnselectedLabels: false,
        unselectedItemColor: _isDark ? Colors.white : Colors.black,
        selectedItemColor: _isDark ? Colors.cyan : Colors.black,
        currentIndex: _selectedIndex,
        onTap: _selectedPage,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon:
                Icon(_selectedIndex == 0 ? Icons.home : Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 1
                ? Icons.category
                : Icons.category),
            label: "Categories",
          ),
          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: Text(
                cartProvider.getCardItems.length.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              child:
                  Icon(_selectedIndex == 2 ? Icons.card_travel : Icons.card_travel),
            ),
            label: 'Cart', // Set your label here
          ),
          BottomNavigationBarItem(
            icon:
            Icon(_selectedIndex == 3 ? Icons.local_dining : Icons.local_dining),
            label: "Recipes",
          ),
          BottomNavigationBarItem(
            icon: Icon(
                _selectedIndex == 4 ? Icons.people : Icons.people),
            label: "User",
          ),
        ],
      ),
    );
  }
}
