import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app/screens/recipes_details_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../consts/firebase_consts.dart';
import '../provider/dark_theme_provider.dart';
import '../services/global_method.dart';
import '../widgets/text_widget.dart';
import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

class RecipesScreen extends StatefulWidget {
  static const routeName = '/RecipesScreen';
  const RecipesScreen({super.key});

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesScreen> {
  bool _isLoading = false;
  List<String> productCategoryNames = [];
  String? selectedCategory;

  final List<String> categories = [
    'Easy',
    'Medium',
    'Challenging',
    'Expert',
  ];

  Future<bool> _isRecipeInFavorites(String productId) async {
    final User? user = authInstance.currentUser;

    if (user == null) {
      return false;
    }

    final userId = user.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final List<dynamic> favoriteRecipes = userDoc['userFavouriteRecipes'];

    return favoriteRecipes.any((recipe) => recipe['productID'] == productId);
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
              final User? user = authInstance.currentUser;
              if (user == null) {
                Fluttertoast.showToast(
                    msg: "No user found, please login first.",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 13);
              } else {
                _fetchProductCategoryNames(user.uid);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
              )
            : _buildBody(color),
      ),
    );
  }

  Widget _buildBody(Color color) {
    final User? user = authInstance.currentUser;
    final userId = user?.uid;
    bool hasRecipesForSelectedCategory = false;
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
            ),
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error fetching data'),
          );
        } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Welcome to Recipes Hub, \nHere we share delicious recipes with everyone!',
              style: TextStyle(
                fontSize: 17,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          );
        } else {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 10.0, top: 10.0, right: 10.0, bottom: 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Difficulty Level :',
                      style: TextStyle(color: color, fontSize: 15),
                    ),
                    DropdownButton<String>(
                      value: selectedCategory,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                      items: categories
                          .map<DropdownMenuItem<String>>((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(color: color, fontSize: 15),
                          ),
                        );
                      }).toList(),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.cyan),
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedCategory = null;
                        });
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var recipe = snapshot.data!.docs[index];

                    if (selectedCategory != null &&
                        recipe['difficultyLevel'] != selectedCategory) {
                      return const SizedBox.shrink();
                    }
                    hasRecipesForSelectedCategory = true;

                    Timestamp timestamp = recipe['timestamp'];
                    DateTime dateTime = timestamp.toDate();
                    String formattedTime =
                        DateFormat('dd MMM yyyy, HH:mm').format(dateTime);

                    int likes = recipe['liked'];
                    int dislikes = recipe['disliked'];

                    String formatCookingTime(int cookingTime) {
                      if (cookingTime >= 100) {
                        int hours = cookingTime ~/ 100;
                        int minutes = cookingTime % 100;
                        return '$hours hour${hours > 1 ? 's' : ''} $minutes mins';
                      } else {
                        return '$cookingTime mins';
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailsScreen(
                                recipe: recipe as QueryDocumentSnapshot<
                                    Map<String, dynamic>>),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        elevation: 4,
                        margin: const EdgeInsets.only(
                            top: 10, bottom: 0, left: 10, right: 10),
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
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                softWrap: true,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Difficulty Level: ${recipe['difficultyLevel']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Shared by: ${recipe['userName']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cooking Time: ${formatCookingTime(recipe['cookingTime'])}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              FutureBuilder(
                                future:
                                    _isRecipeInFavorites(recipe['productID']),
                                builder:
                                    (context, AsyncSnapshot<bool> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.cyan),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }

                                  bool isFavorite = snapshot.data!;

                                  return Row(
                                    children: [
                                      GestureDetector(
                                      onTap: () {
                                    _addOrRemoveRecipeFromFavourite(
                                      recipe.data() as Map<String, dynamic>,
                                      isFavorite,
                                    );
                                  },
                                      child: Icon(
                                      isFavorite ? IconlyBold.heart : IconlyLight.heart,
                                      color: isFavorite ? Colors.red : null,
                                      ),
                                      ),
                                      const SizedBox(width: 25),
                                      GestureDetector(
                                        onTap: () {
                                          if (userId == null) {
                                            Fluttertoast.showToast(
                                                msg:
                                                    "No user found, please login first.",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                                timeInSecForIosWeb: 1,
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white,
                                                fontSize: 13);
                                          } else {
                                            if (!recipe['likedBy']
                                                .contains(userId)) {
                                              FirebaseFirestore.instance
                                                  .collection('recipes')
                                                  .doc(recipe.id)
                                                  .update({
                                                'liked':
                                                    FieldValue.increment(1),
                                                'likedBy':
                                                    FieldValue.arrayUnion(
                                                        [userId]),
                                              });
                                              if (recipe['dislikedBy']
                                                  .contains(userId)) {
                                                FirebaseFirestore.instance
                                                    .collection('recipes')
                                                    .doc(recipe.id)
                                                    .update({
                                                  'disliked':
                                                      FieldValue.increment(-1),
                                                  'dislikedBy':
                                                      FieldValue.arrayRemove(
                                                          [userId]),
                                                });
                                              }
                                              Fluttertoast.showToast(
                                                  msg: "Liked Recipes!",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.BOTTOM,
                                                  timeInSecForIosWeb: 2,
                                                  backgroundColor: Colors.green,
                                                  textColor: Colors.white,
                                                  fontSize: 13);
                                            } else {
                                              FirebaseFirestore.instance
                                                  .collection('recipes')
                                                  .doc(recipe.id)
                                                  .update({
                                                'liked':
                                                    FieldValue.increment(-1),
                                                'likedBy':
                                                    FieldValue.arrayRemove(
                                                        [userId]),
                                              });
                                            }
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              recipe['likedBy'].contains(userId)
                                                  ? Icons.thumb_up
                                                  : Icons.thumb_up_outlined,
                                              color: recipe['likedBy']
                                                      .contains(userId)
                                                  ? Colors.cyan
                                                  : Colors.cyan,
                                            ),
                                            const SizedBox(width: 3),
                                            Text('${recipe['liked']}',
                                                style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          if (userId == null) {
                                            Fluttertoast.showToast(
                                                msg:
                                                    "No user found, please login first.",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                                timeInSecForIosWeb: 1,
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white,
                                                fontSize: 13);
                                          } else {
                                            if (!recipe['dislikedBy']
                                                .contains(userId)) {
                                              FirebaseFirestore.instance
                                                  .collection('recipes')
                                                  .doc(recipe.id)
                                                  .update({
                                                'disliked':
                                                    FieldValue.increment(1),
                                                'dislikedBy':
                                                    FieldValue.arrayUnion(
                                                        [userId]),
                                              });
                                              if (recipe['likedBy']
                                                  .contains(userId)) {
                                                FirebaseFirestore.instance
                                                    .collection('recipes')
                                                    .doc(recipe.id)
                                                    .update({
                                                  'liked':
                                                      FieldValue.increment(-1),
                                                  'likedBy':
                                                      FieldValue.arrayRemove(
                                                          [userId]),
                                                });
                                              }
                                              Fluttertoast.showToast(
                                                  msg: "Disliked Recipes!",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.BOTTOM,
                                                  timeInSecForIosWeb: 2,
                                                  backgroundColor:
                                                      Colors.orange,
                                                  textColor: Colors.white,
                                                  fontSize: 13);
                                            } else {
                                              FirebaseFirestore.instance
                                                  .collection('recipes')
                                                  .doc(recipe.id)
                                                  .update({
                                                'disliked':
                                                    FieldValue.increment(-1),
                                                'dislikedBy':
                                                    FieldValue.arrayRemove(
                                                        [userId]),
                                              });
                                            }
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              recipe['dislikedBy']
                                                      .contains(userId)
                                                  ? Icons.thumb_down
                                                  : Icons.thumb_down_outlined,
                                              color: recipe['dislikedBy']
                                                      .contains(userId)
                                                  ? Colors.red
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 3),
                                            Text('${recipe['disliked']}',
                                                style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }

  bool loading2 = false;

  void _addOrRemoveRecipeFromFavourite(Map<String, dynamic> recipeData, bool isFavorite) async {
    setState(() {
      loading2 = true;
    });

    try {
      final User? user = authInstance.currentUser;

      if (user == null) {
        Fluttertoast.showToast(
          msg: "No user found, please login first.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 13,
        );
        setState(() {
          loading2 = false;
        });
        return;
      }

      final userId = user.uid;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      final recipeId = recipeData['id'];
      final userSnapshot = await userDoc.get();
      List<dynamic> favoriteRecipes = userSnapshot.data()?['userFavouriteRecipes'] ?? [];

      if (isFavorite) {
        favoriteRecipes.removeWhere((recipe) => recipe['id'] == recipeId);
        await userDoc.update({
          'userFavouriteRecipes': favoriteRecipes,
        });

        Fluttertoast.showToast(
          msg: "Removed recipe from favorites",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          fontSize: 13,
        );
      } else {
        favoriteRecipes.add(recipeData);
        await userDoc.update({
          'userFavouriteRecipes': favoriteRecipes,
        });
        Fluttertoast.showToast(
          msg: "Added recipe to favorites",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 13,
        );
      }
    } catch (error) {
      GlobalMethods.errorDialog(subtitle: '$error', context: context);
    } finally {
      setState(() {
        loading2 = false;
      });
    }
  }



  void _fetchProductCategoryNames(String? uid) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userSnapshot = await firestore.collection('users').doc(uid).get();
    String userName = userSnapshot['name'] ?? 'Unknown';
    QuerySnapshot querySnapshot = await firestore.collection('products').get();
    Set<String> uniqueNames = Set<String>();
    querySnapshot.docs.forEach((doc) {
      uniqueNames.add(doc['productCategoryName']);
    });
    setState(() {
      productCategoryNames = uniqueNames.toList();
    });
    _showCategoryDialog(userName);
  }

  void _showCategoryDialog(String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Pick Your Categories',
            style: TextStyle(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: productCategoryNames.map((name) {
                return Card(
                  child: ListTile(
                    title: Text(name),
                    onTap: () {
                      Navigator.of(context).pop();
                      _fetchProductsByCategory(name, userName);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.cyan),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _fetchProductsByCategory(String category, String userName) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore
        .collection('products')
        .where('productCategoryName', isEqualTo: category)
        .get();
    List<Map<String, String>> products = [];
    querySnapshot.docs.forEach((doc) {
      products.add({'id': doc.id, 'title': doc['title']});
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Products in $category', style: const TextStyle(fontSize: 18)),
          content: SingleChildScrollView(
            child: ListBody(
              children: products.map((product) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showPickedProductMessage(
                        product['id']!, product['title']!, category, userName);
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(product['title']!),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close', style: TextStyle(color: Colors.cyan)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPickedProductMessage(
      String id, String title, String category, String userName) {
    File? imageFile;
    File? videoFile;
    bool isImageChosen = false;
    bool isVideoChosen = false;
    Uint8List? videoThumbnail;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Future<void> _pickImage() async {
              final pickedFile = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                setState(() {
                  imageFile = File(pickedFile.path);
                  isImageChosen = true;
                });
                Fluttertoast.showToast(
                    msg: "Image Chosen",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 13);
              }
            }

            Future<void> _pickVideo() async {
              final pickedFile = await ImagePicker().pickVideo(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                final videoPath = pickedFile.path;
                setState(() {
                  if (videoFile == null) {
                    videoFile = File(videoPath);
                  }
                  isVideoChosen = true;
                });
                final thumbnail = await VideoThumbnail.thumbnailData(
                  video: videoPath,
                  imageFormat: ImageFormat.PNG,
                  maxWidth: 120,
                  quality: 30,
                );
                if (thumbnail != null) {
                  setState(() {
                    videoThumbnail = thumbnail;
                  });
                  Fluttertoast.showToast(
                      msg: "Video chosen",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                      fontSize: 13);
                }
              }
            }

            return WillPopScope(
              onWillPop: () async {
                setState(() {
                  imageFile = null;
                  videoFile = null;
                  isImageChosen = false;
                  isVideoChosen = false;
                });
                return true;
              },
              child: AlertDialog(
                title: Text('Share Image & Video for $title',
                    style: const TextStyle(fontSize: 15)),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.image),
                                onPressed: () => _pickImage(),
                              ),
                              if (imageFile != null)
                                Container(
                                  width: 100,
                                  height: 100,
                                  child: Image.file(
                                    imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.video_library),
                                onPressed: () => _pickVideo(),
                              ),
                              if (videoThumbnail != null)
                                Container(
                                  width: 100,
                                  height: 100,
                                  child: Image.memory(
                                    videoThumbnail!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text(
                      'Next',
                      style: TextStyle(color: Colors.cyan),
                    ),
                    onPressed: () {
                      if (imageFile == null && videoThumbnail == null) {
                        Fluttertoast.showToast(
                            msg: "Please upload Image & Video",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 13);
                      } else if (imageFile == null) {
                        Fluttertoast.showToast(
                            msg: "Image not Found",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 13);
                      } else if (videoThumbnail == null) {
                        Fluttertoast.showToast(
                            msg: "Video not Found",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 13);
                      } else {
                        Navigator.of(context).pop();
                        _showTextFieldsDialog(
                            title, imageFile, videoFile, userName, id);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTextFieldsDialog(String title, File? imageFile, File? videoFile,
      String userName, String productID) {
    String title2 = '';
    String description = '';
    String ingredients = '';
    String instructions = '';
    String? difficultyLevel;
    int? prepHours;
    int? prepMinutes;

    final GlobalKey<FormState> _formKey =
        GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Recipe', style: TextStyle(fontSize: 15)),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Give your recipe a name',
                          labelStyle: TextStyle(color: Colors.black),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                        ),
                        onChanged: (value) {
                          title2 = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                        cursorColor: Colors.cyan,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Introduce your recipe',
                          labelStyle: TextStyle(color: Colors.black),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                        ),
                        onChanged: (value) {
                          description = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a Description';
                          }
                          return null;
                        },
                        cursorColor: Colors.cyan,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Ingredients',
                          hintText: 'Add your ingredients',
                          labelStyle: TextStyle(color: Colors.black),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                        ),
                        onChanged: (value) {
                          ingredients = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a Ingredients';
                          }
                          return null;
                        },
                        cursorColor: Colors.cyan,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Instructions',
                          hintText: 'Add your cooking steps',
                          labelStyle: TextStyle(color: Colors.black),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                        ),
                        onChanged: (value) {
                          instructions = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Instructions';
                          }
                          return null;
                        },
                        cursorColor: Colors.cyan,
                      ),
                      GestureDetector(
                        onTap: () {
                          _showTimePickerDialog(context, (hours, minutes) {
                            setState(() {
                              prepHours = hours;
                              prepMinutes = minutes;
                            });
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: const BoxDecoration(
                            border:
                                Border(bottom: BorderSide(color: Colors.grey)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cook Time',
                                style: TextStyle(color: Colors.black),
                              ),
                              Text(
                                _formatTime(prepHours, prepMinutes),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: difficultyLevel,
                        items: [
                          'Easy',
                          'Medium',
                          'Challenging',
                          'Expert',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            difficultyLevel = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Difficulty Level',
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                          labelStyle: TextStyle(color: Colors.black),
                        ),
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a difficulty level';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Share',
                    style: TextStyle(color: Colors.cyan),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      int totalPrepTime =
                          (prepHours ?? 0) * 60 + (prepMinutes ?? 0);
                      _addRecipes(
                          title2,
                          instructions,
                          ingredients,
                          description,
                          difficultyLevel,
                          imageFile,
                          videoFile,
                          userName,
                          totalPrepTime,
                          productID);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTimePickerDialog(
      BuildContext context, Function(int, int) onTimeSelected) {
    int selectedHours = 0;
    int selectedMinutes = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'How long does it take to cook this recipe?',
            style: TextStyle(fontSize: 13),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TimePickerSpinner(
                is24HourMode: true,
                normalTextStyle: const TextStyle(fontSize: 16, color: Colors.black),
                highlightedTextStyle:
                    const TextStyle(fontSize: 22, color: Colors.cyan),
                spacing: 20,
                itemHeight: 40,
                isForce2Digits: true,
                onTimeChange: (time) {
                  selectedHours = time.hour;
                  selectedMinutes = time.minute;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
            TextButton(
              onPressed: () {
                onTimeSelected(selectedHours, selectedMinutes);
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int? hours, int? minutes) {
    if (hours == null || minutes == null) {
      return '00:00';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> _addRecipes(
    String title2,
    String instructions,
    String ingredients,
    String description,
    String? difficultyLevel,
    File? imageFile,
    File? videoFile,
    String userName,
    int totalPrepTime,
    String productID,
  ) async {
    setState(() {
      _isLoading = true;
    });

    final User? user = authInstance.currentUser;
    final _uid = user!.uid;

    DateTime now = DateTime.now();
    String formattedDateTime =
        '${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}';
    String? imageUrl;
    String? videoUrl;

    if (imageFile != null) {
      imageUrl = await _uploadFile(imageFile, 'images');
    }

    if (videoFile != null) {
      videoUrl = await _uploadFile(videoFile, 'videos');
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    Map<String, dynamic> data = {
      'text': title2,
      'instructions': instructions,
      'description': description,
      'ingredients': ingredients,
      'difficultyLevel': difficultyLevel,
      'userName': userName,
      'timestamp': now,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'liked': 0,
      'disliked': 0,
      'cookingTime': totalPrepTime,
      'productID': productID,
      'userID': user.uid,
      'likedBy': [],
      'dislikedBy': [],
    };

    try {
      DocumentReference recipeRef =
          await firestore.collection('recipes').add(data);
      await firestore.collection('users').doc(user.uid).update({
        'userRecipes': FieldValue.arrayUnion([
          {
            'recipeID': recipeRef.id,
            'text': title2,
            'instructions': instructions,
            'description': description,
            'ingredients': ingredients,
            'difficultyLevel': difficultyLevel,
            'userName': userName,
            'timestamp': now,
            'imageUrl': imageUrl,
            'liked': 0,
            'disliked': 0,
            'cookingTime': totalPrepTime,
            'productID': productID,
            'userID': user.uid,
          }
        ]),
      });

      Fluttertoast.showToast(
          msg: "Recipes Shared",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 13);
    } catch (error) {
      print('Error uploading data: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadFile(File file, String folder) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      Reference reference = storage.ref().child('$folder/$fileName');
      UploadTask uploadTask = reference.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (error) {
      print('Error uploading file: $error');
      return null;
    }
  }
}
