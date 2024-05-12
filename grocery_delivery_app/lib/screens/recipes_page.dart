import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../provider/dark_theme_provider.dart';
import '../widgets/text_widget.dart';
import 'dart:io';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesScreen> {
  List<String> productCategoryNames = [];

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context, listen: false);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextWidget(
          text: 'Recipes Hub',
          color: color,
          textSize: 24,
          isTitle: true,
        ),
        titleSpacing: 10,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: color),
            onPressed: () {
              _fetchProductCategoryNames();
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to Recipes Hub, \nHere we share delicious recipes with everyone!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            color: color,
          ),
        ),
      ),
    );
  }

  void _fetchProductCategoryNames() async {
    // Access Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Access 'products' collection
    QuerySnapshot querySnapshot = await firestore.collection('products').get();

    // Extract product category names from documents
    Set<String> uniqueNames = Set<String>(); // Using a Set to store unique names
    querySnapshot.docs.forEach((doc) {
      uniqueNames.add(doc['productCategoryName']);
    });

    // Update the UI with fetched data
    setState(() {
      productCategoryNames = uniqueNames.toList(); // Convert Set to List
    });

    // Show dialog with product category names
    _showCategoryDialog();
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick Your Categories', style: TextStyle(fontSize: 18),),
          content: SingleChildScrollView(
            child: ListBody(
              children: productCategoryNames.map((name) {
                return Card(
                  child: ListTile(
                    title: Text(name),
                    onTap: () {
                      Navigator.of(context).pop();
                      _fetchProductsByCategory(name);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.cyan),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _fetchProductsByCategory(String category) async {
    // Access Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Access 'products' collection and query by category
    QuerySnapshot querySnapshot = await firestore
        .collection('products')
        .where('productCategoryName', isEqualTo: category)
        .get();

    // Extract product titles from documents
    List<String> productTitles = [];
    querySnapshot.docs.forEach((doc) {
      productTitles.add(doc['title']);
    });

    // Show dialog with product titles
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Products in $category', style: TextStyle(fontSize: 18)),
          content: SingleChildScrollView(
            child: ListBody(
              children: productTitles.map((title) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showPickedProductMessage(title, category);
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(title),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.cyan)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPickedProductMessage(String title, String category) {
    String text = '';
    String secondTitle = '';
    File? imageFile;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Future<void> _pickImage() async {
              final pickedFile =
              await ImagePicker().pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() {
                  imageFile = File(pickedFile.path);
                });
              }
            }

            return AlertDialog(
              title: Text('You picked $title', style: TextStyle(fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Display image icon
                    IconButton(
                      icon: imageFile != null ? Icon(Icons.edit) : Icon(Icons.image),
                      onPressed: () => _pickImage(),
                    ),
                    // Display picked image if available
                    if (imageFile != null)
                      Container(
                        height: 100, // Adjust height as needed
                        child: Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Title'),
                      onChanged: (value) {
                        text = value;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Instructions'),
                      onChanged: (value) {
                        secondTitle = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    // Process the input (imageFile, title, text, secondTitle)
                    print('Image File: $imageFile');
                    print('Title: $title');
                    print('Text: $text');
                    print('Second Title: $secondTitle');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
