import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app/screens/recipes_details_page.dart';
import 'package:grocery_delivery_app/screens/recipes_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../consts/firebase_consts.dart';
import '../provider/dark_theme_provider.dart';
import '../widgets/text_widget.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

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
    final imageUrl = "";

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

  final ImagePicker _picker = ImagePicker();
  String? _pickedImage;
  bool _isUploading = false;

  Future<void> _pickImage(String recipeID, String userID) async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _pickedImage = pickedImage.path;
      });
      _showImagePreviewDialog(pickedImage, recipeID, userID);
    }
  }

  void _showImagePreviewDialog(XFile pickedImage, String recipeID, String userID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Image', style: TextStyle(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(
                File(pickedImage.path),
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              const Text('Do you want to update the image?', style: TextStyle(color: Colors.black)),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.cyan)),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isUploading = true;
                });
                _uploadImageToFirebase(pickedImage, recipeID, userID);
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.cyan)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadImageToFirebase(XFile pickedImage, String recipeID, String userID) async {

    Fluttertoast.showToast(
        msg: "Image Uploading...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 13
    );
    try {
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('recipe_images')
          .child('recipe_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(pickedImage.path));
      String imageUrl = await ref.getDownloadURL();

      await _updateRecipeImageUrl(recipeID, userID, imageUrl);

      setState(() {
        _isUploading = false;
      });
    } catch (error) {
      setState(() {
        _isUploading = false;
      });
      print('Firebase Storage upload error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload image. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateRecipeImageUrl(String recipeID, String userID, String imageUrl) async {
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userID);
      DocumentSnapshot userDoc = await userRef.get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> userRecipes = userData['userRecipes'] ?? [];

        for (var recipe in userRecipes) {
          if (recipe['recipeID'] == recipeID) {
            recipe['imageUrl'] = imageUrl;
            break;
          }
        }

        await userRef.update({'userRecipes': userRecipes});
      } else {
        print('User not found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      DocumentReference recipeRef = FirebaseFirestore.instance.collection('recipes').doc(recipeID);
      await recipeRef.update({'imageUrl': imageUrl});

      Fluttertoast.showToast(
          msg: "Image Updated",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 13
      );

    } catch (error) {
      print('Firestore update error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update recipe image. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  final User? user = authInstance.currentUser;
  String _uid = "";

  void _viewAllFavouriteRecipes(BuildContext context) {
    if (user != null) {
      _uid = user!.uid;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Your Favourite Recipes",
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          content: FutureBuilder(
            future: FirebaseFirestore.instance.collection('users').doc(_uid).get(),
            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child:  CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(
                      Colors.cyan),
                ),);
              }
              if (productSnapshot.hasError) {
                return Center(child: Text('Error: ${productSnapshot.error}'));
              }
              if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                return const Center(child: Text('Product not found'));
              }
              final List<dynamic> userFavouriteRecipesArray = productSnapshot.data!['userFavouriteRecipes'];

              if (userFavouriteRecipesArray.isEmpty) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: const Center(
                    child: Text(
                      'No Favourite Recipes available',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: userFavouriteRecipesArray.map((favouriteRecipe) {
                    final String name = favouriteRecipe['text'] ?? '';
                    final String description = favouriteRecipe['description'] ?? '';
                    final String profileImageUrl = favouriteRecipe['imageUrl'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: profileImageUrl != null && profileImageUrl.toString().isNotEmpty
                            ? NetworkImage(profileImageUrl.toString()) as ImageProvider<Object>?
                            : const AssetImage('assets/images/user_icon.png'),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              "Title : $name",
                              style: const TextStyle(color: Colors.black, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Description: $description",
                              style: const TextStyle(color: Colors.black, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close', style: TextStyle(color: Colors.cyan)),
            ),
          ],
        );
      },
    );
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
          textSize: 22,
          isTitle: true,
        ),
        titleSpacing: 10,
        iconTheme: IconThemeData(
          color: color,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_outlined),
            color: color,
            onPressed: () {
              _viewAllFavouriteRecipes(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _userRecipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child:  CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation<Color>(
                  Colors.cyan),
            ),);
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final userRecipes = snapshot.data ?? [];

            if (userRecipes.isEmpty) {
              return const Center(
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
                    margin: const EdgeInsets.fromLTRB(
                        10,
                        7,
                        10,
                        7
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: SizedBox(
                        height: 100,
                        width: 100,
                        child: Stack(
                          children: [
                            Center(
                              child: _pickedImage != null
                                  ? Image.file(
                                      File(_pickedImage!),
                                      height: 300,
                                      width: 300,
                                    )
                                  : Image.network(
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
                            ),
                            Positioned(
                              top: 25,
                              right: 25,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(IconlyLight.upload,
                                      color: Colors.white),
                                  onPressed: () {
                                    final User? user = authInstance.currentUser;
                                    final _uid = user!.uid;
                                    _pickImage(recipe['recipeID'], _uid);
                                  },
                                ),
                              ),
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
                              color: Colors.black,
                            ),
                            softWrap: true,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Difficulty Level: ${recipe['difficultyLevel']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time Posted: $formattedTime',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cooking Time: ${formatCookingTime(recipe['cookingTime'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      final recipeNameController =
                                          TextEditingController(
                                              text: recipe['text']);
                                      final recipeDescriptionController =
                                          TextEditingController(
                                              text: recipe['description']);
                                      final recipeIngredientsController =
                                          TextEditingController(
                                              text: recipe['ingredients']);
                                      final recipeInstructionController =
                                          TextEditingController(
                                              text: recipe['instructions']);
                                      final recipeCookingTimeController =
                                          TextEditingController(
                                              text: recipe['cookingTime']
                                                      ?.toString() ??
                                                  '');
                                      String difficultyLevel = recipe[
                                              'difficultyLevel'] ??
                                          'Easy'; // Default to 'Easy' if null
                                      final TextEditingController
                                          recipeImageController =
                                          TextEditingController(
                                              text: recipe['imageUrl']);
                                      final TextEditingController
                                          recipeVideoController =
                                          TextEditingController(
                                              text: recipe['videoUrl']);

                                      return AlertDialog(
                                        title: const Text('Edit Recipe',
                                            style: TextStyle(fontSize: 18)),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller:
                                                    recipeNameController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Title',
                                                  labelStyle: TextStyle(
                                                      color: Colors.black),
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.cyan),
                                                  ),
                                                ),
                                                cursorColor: Colors.cyan,
                                              ),
                                              TextField(
                                                controller:
                                                    recipeDescriptionController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Description',
                                                  labelStyle: TextStyle(
                                                      color: Colors.black),
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.cyan),
                                                  ),
                                                ),
                                                cursorColor: Colors.cyan,
                                              ),
                                              TextField(
                                                controller:
                                                    recipeInstructionController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Instruction',
                                                  labelStyle: TextStyle(
                                                      color: Colors.black),
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.cyan),
                                                  ),
                                                ),
                                                cursorColor: Colors.cyan,
                                              ),
                                              TextField(
                                                controller:
                                                    recipeIngredientsController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Ingredients',
                                                  labelStyle: TextStyle(
                                                      color: Colors.black),
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.cyan),
                                                  ),
                                                ),
                                                cursorColor: Colors.cyan,
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  _showTimePickerDialog(context,
                                                      (int hours, int minutes) {
                                                    final totalMinutes =
                                                        (hours * 60) + minutes;
                                                    recipeCookingTimeController
                                                            .text =
                                                        totalMinutes.toString();
                                                  });
                                                },
                                                child: AbsorbPointer(
                                                  child: TextField(
                                                    controller:
                                                        recipeCookingTimeController,
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: 'Cooking Time',
                                                      labelStyle: TextStyle(
                                                          color: Colors.black),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: Colors.cyan),
                                                      ),
                                                    ),
                                                    cursorColor: Colors.cyan,
                                                    keyboardType:
                                                        TextInputType.number,
                                                  ),
                                                ),
                                              ),
                                              DropdownButtonFormField<String>(
                                                value: difficultyLevel,
                                                decoration: const InputDecoration(
                                                  labelText: 'Difficulty Level',
                                                  labelStyle: TextStyle(
                                                      color: Colors.black),
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.cyan),
                                                  ),
                                                ),
                                                dropdownColor: Colors.white,
                                                icon: const Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Colors.black),
                                                items: [
                                                  'Easy',
                                                  'Medium',
                                                  'Challenging',
                                                  'Expert',
                                                ].map((String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Colors
                                                              .black),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (newValue) {
                                                  difficultyLevel = newValue!;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('Save',
                                                style: TextStyle(
                                                    color: Colors.cyan)),
                                            onPressed: () async {
                                              final updatedName =
                                                  recipeNameController.text;
                                              final updatedDescription =
                                                  recipeDescriptionController
                                                      .text;
                                              final updatedIngredients =
                                                  recipeIngredientsController
                                                      .text;
                                              final updatedInstructions =
                                                  recipeInstructionController
                                                      .text;
                                              final updatedCookingTime =
                                                  int.tryParse(
                                                      recipeCookingTimeController
                                                          .text);
                                              final recipeId =
                                                  recipe['recipeID'];
                                              final User? user =
                                                  authInstance.currentUser;

                                              if (user == null) {
                                                print(
                                                    'User not authenticated.');
                                                Navigator.of(context).pop();
                                                return;
                                              }

                                              Navigator.of(context)
                                                  .pop();

                                              try {
                                                final userDocRef =
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(user.uid);
                                                final userDocSnapshot =
                                                    await userDocRef.get();
                                                final userRecipes = List<
                                                        Map<String,
                                                            dynamic>>.from(
                                                    userDocSnapshot[
                                                            'userRecipes'] ??
                                                        []);
                                                final recipeIndex = userRecipes
                                                    .indexWhere((r) =>
                                                        r['recipeID'] ==
                                                        recipeId);

                                                if (recipeIndex != -1) {
                                                  userRecipes[recipeIndex] = {
                                                    ...userRecipes[recipeIndex],
                                                    'text': updatedName,
                                                    'description':
                                                        updatedDescription,
                                                    'ingredients':
                                                        updatedIngredients,
                                                    'instructions':
                                                        updatedInstructions,
                                                    'cookingTime':
                                                        updatedCookingTime,
                                                    'difficultyLevel':
                                                        difficultyLevel,
                                                  };

                                                  await userDocRef.update({
                                                    'userRecipes': userRecipes,
                                                  });
                                                }
                                                final recipeDocRef =
                                                    FirebaseFirestore.instance
                                                        .collection('recipes')
                                                        .doc(recipeId);
                                                await recipeDocRef.update({
                                                  'text': updatedName,
                                                  'description':
                                                      updatedDescription,
                                                  'ingredients':
                                                      updatedIngredients,
                                                  'instructions':
                                                      updatedInstructions,
                                                  'cookingTime':
                                                      updatedCookingTime,
                                                  'difficultyLevel':
                                                      difficultyLevel,
                                                });

                                                Fluttertoast.showToast(
                                                  msg: "Recipe Updated",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.BOTTOM,
                                                  timeInSecForIosWeb: 2,
                                                  backgroundColor: Colors.green,
                                                  textColor: Colors.white,
                                                  fontSize: 13,
                                                );

                                                setState(() {
                                                  _userRecipesFuture =
                                                      Future.value(userRecipes);
                                                });
                                                print(
                                                    'Firestore update successful');
                                              } catch (error) {
                                                print(
                                                    'Firestore update error: $error');
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Failed to update recipe. Please try again later.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          TextButton(
                                            child: const Text('Cancel',
                                                style: TextStyle(
                                                    color: Colors.cyan)),
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Icon(IconlyLight.edit,
                                        color: Colors.black),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final recipeId = recipe['recipeID'];
                                  final User? user = authInstance.currentUser;

                                  if (user == null) {
                                    print('User not authenticated.');
                                    return;
                                  }

                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text(
                                          'Confirm Deletion',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        content: const Text(
                                          'Are you sure you want to remove this recipe?',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text(
                                              'Remove',
                                              style:
                                                  TextStyle(color: Colors.cyan),
                                            ),
                                            onPressed: () async {
                                              Navigator.of(context)
                                                  .pop();
                                              try {
                                                final userDocRef =
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(user.uid);
                                                final userDocSnapshot =
                                                    await userDocRef.get();
                                                final userRecipes = List<
                                                        Map<String,
                                                            dynamic>>.from(
                                                    userDocSnapshot[
                                                            'userRecipes'] ??
                                                        []);
                                                userRecipes.removeWhere(
                                                    (recipe) =>
                                                        recipe['recipeID'] ==
                                                        recipeId);
                                                await userDocRef.update({
                                                  'userRecipes': userRecipes,
                                                });
                                                await FirebaseFirestore.instance
                                                    .collection('recipes')
                                                    .doc(recipeId)
                                                    .delete();

                                                Fluttertoast.showToast(
                                                  msg: "Recipe Removed",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.BOTTOM,
                                                  timeInSecForIosWeb: 2,
                                                  backgroundColor: Colors.orange,
                                                  textColor: Colors.white,
                                                  fontSize: 13,
                                                );

                                                setState(() {
                                                  _userRecipesFuture =
                                                      Future.value(userRecipes);
                                                });
                                              } catch (error) {
                                                print(
                                                    'Error deleting recipe: $error');
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Failed to delete recipe. Please try again later.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          TextButton(
                                            child: const Text(
                                              'Cancel',
                                              style:
                                                  TextStyle(color: Colors.cyan),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Icon(IconlyLight.delete,
                                        color: Colors.black),
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

  void _showTimePickerDialog(
      BuildContext context, Function(int, int) onTimeSelected) {
    int selectedHours = 0;
    int selectedMinutes = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('How long does it take to cook this recipe?',
              style: TextStyle(fontSize: 13)),
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
              child: const Text('Cancel', style: TextStyle(color: Colors.cyan)),
            ),
            TextButton(
              onPressed: () {
                onTimeSelected(selectedHours, selectedMinutes);
                Navigator.of(context).pop();
              },
              child: const Text('OK', style: TextStyle(color: Colors.cyan)),
            ),
          ],
        );
      },
    );
  }
}
