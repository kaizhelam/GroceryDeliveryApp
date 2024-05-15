import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app/screens/recipes_details_page.dart';
import 'package:grocery_delivery_app/screens/recipes_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../consts/firebase_consts.dart';
import '../provider/dark_theme_provider.dart';
import '../widgets/text_widget.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({Key? key}) : super(key: key);

  @override
  _MyRecipesScreenState createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  late Future<List<Map<String, dynamic>>> _userRecipesFuture;

  @override
  void initState() {
    super.initState();
    _userRecipesFuture = _fetchUserRecipes();
  }

  Future<List<Map<String, dynamic>>> _fetchUserRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userRecipes = snapshot.data()?['userRecipes'] ?? [];

      return List<Map<String, dynamic>>.from(userRecipes);
    }

    return [];
  }

  String formatCookingTime(int cookingTime) {
    if (cookingTime >= 100) {
      int hours = cookingTime ~/ 100;
      int minutes = cookingTime % 100;
      return '$hours hour${hours > 1 ? 's' : ''} ${minutes} mins';
    } else {
      return '$cookingTime mins';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context, listen: false);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextWidget(
          text: 'My Recipes',
          color: color,
          textSize: 24,
          isTitle: true,
        ),
        titleSpacing: 10,
        iconTheme: IconThemeData(
          color: color, // Change the color of the back arrow here
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _userRecipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final userRecipes = snapshot.data ?? [];

            if (userRecipes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No Recipes found. \nShare your Recipes Now',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }


            return ListView.builder(
              itemCount: userRecipes.length,
              itemBuilder: (context, index) {
                final recipe = userRecipes[index];

                Timestamp timestamp = recipe['timestamp'];
                DateTime dateTime = timestamp.toDate();
                String formattedTime =
                    DateFormat('dd MMM yyyy, HH:mm').format(dateTime);

                return GestureDetector(
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: SizedBox(
                        height: 100,
                        width: 100,
                        child: Stack(
                          children: [
                            Image.network(
                              recipe['imageUrl'],
                              height: 300,
                              width: 300,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.cyan),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe['text'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black, // Change text color here
                            ),
                            softWrap: true,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Difficulty Level: ${recipe['difficultyLevel']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black, // Change text color here
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time Posted: $formattedTime',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black, // Change text color here
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cooking Time: ${formatCookingTime(recipe['cookingTime'])}',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Handle edit action
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.edit,
                                        color: Colors.black),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    final recipeId = recipe['recipeID'];
                                    final User? user = authInstance.currentUser;
                                    if (user == null) {
                                      print('User not authenticated.');
                                      return;
                                    }

                                    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                                    final userDocSnapshot = await userDocRef.get();
                                    final userRecipes = List<Map<String, dynamic>>.from(userDocSnapshot['userRecipes'] ?? []);
                                    userRecipes.removeWhere((recipe) => recipe['recipeID'] == recipeId);
                                    await userDocRef.update({
                                      'userRecipes': userRecipes,
                                    });
                                    await FirebaseFirestore.instance.collection('recipes').doc(recipeId).delete();


                                    Fluttertoast.showToast(
                                      msg: "Recipe Removed",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 2,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 13,
                                    );

                                    setState(() {
                                      _userRecipesFuture = Future.value(userRecipes);
                                    });

                                  } catch (error) {
                                    print('Error deleting recipe: $error');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete recipe. Please try again later.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        color: Colors.black), // Delete icon
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
