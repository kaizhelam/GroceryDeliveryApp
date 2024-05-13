import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  const RecipesScreen({super.key});

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesScreen> {
  bool _isLoading = false;
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
              final User? user = authInstance.currentUser;
              if (user == null) {
                GlobalMethods.errorDialog(
                    subtitle: 'No user found, Please login in first',
                    context: context);
              } else {
                _fetchProductCategoryNames(user.uid);
              }
            },
          ),
        ],
      ),
      body: Center(
        // Display either the loading spinner or the normal UI based on the value of _isLoading
        child: _isLoading ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
        ) : _buildBody(color),
      ),
    );
  }


  Widget _buildBody(Color color) {
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
          return Center(
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
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var recipe = snapshot.data!.docs[index];
              Timestamp timestamp = recipe['timestamp'];
              DateTime dateTime = timestamp.toDate(); // Convert Timestamp to DateTime
              String formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(dateTime); // Format DateTime

              // Get number of likes and dislikes
              int likes = recipe['liked'];
              int dislikes = recipe['disliked'];

              String formatCookingTime(int cookingTime) {
                if (cookingTime >= 100) {
                  int hours = cookingTime ~/ 100;
                  int minutes = cookingTime % 100;
                  return '$hours hour${hours > 1 ? 's' : ''} ${minutes} mins';
                } else {
                  return '$cookingTime mins';
                }
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailsScreen(recipe: recipe as QueryDocumentSnapshot<Map<String, dynamic>>),
                    ),
                  );
                },
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 0, left: 10, right: 10),
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
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              } else {
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
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
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 8),
                        Text('Difficulty Level: ${recipe['difficultyLevel']}', style: TextStyle(
                          fontSize: 12,
                        ),),
                        const SizedBox(height: 4),
                        Text('Shared by: ${recipe['userName']}', style: TextStyle(
                          fontSize: 12,
                        ),),
                        const SizedBox(height: 4),
                        Text(
                          'Cooking Time: ${formatCookingTime(recipe['cookingTime'])}',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.thumb_up, color: Colors.green), // Like (thumbs-up) icon
                                const SizedBox(width: 3),
                                Text(likes.toString(), style: TextStyle(fontSize: 12),), // Number of likes
                              ],
                            ),
                            const SizedBox(width: 13),
                            Row(
                              children: [
                                Icon(Icons.thumb_down, color: Colors.red), // Dislike (thumbs-down) icon
                                const SizedBox(width: 3),
                                Text(dislikes.toString(), style: TextStyle(fontSize: 12),), // Number of dislikes
                              ],
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
    );
  }

  void _fetchProductCategoryNames(String? uid) async {
    print(uid);

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentSnapshot userSnapshot =
        await firestore.collection('users').doc(uid).get();
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
          title: Text(
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
              child: Text(
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
                    _showPickedProductMessage(title, category, userName);
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

  void _showPickedProductMessage(
      String title, String category, String userName) {
    String text = '';
    String secondTitle = '';
    String? difficultyLevel;
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
                    backgroundColor: Colors.cyan,
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
                      backgroundColor: Colors.cyan,
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
                    style: TextStyle(fontSize: 15)),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.image),
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
                          SizedBox(
                            width: 20,
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.video_library),
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
                    child: Text(
                      'Next',
                      style: TextStyle(color: Colors.cyan),
                    ),
                    onPressed: () {
                      if (imageFile == null && videoThumbnail == null) {
                        Fluttertoast.showToast(
                            msg: "Please upload Image & Video chosen",
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
                            title, imageFile, videoFile, userName);
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

  void _showTextFieldsDialog(
      String title, File? imageFile, File? videoFile, String userName) {
    String text = '';
    String secondTitle = '';
    String? difficultyLevel;
    int? prepHours;
    int? prepMinutes;

    final GlobalKey<FormState> _formKey =
    GlobalKey<FormState>(); // Add form key

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Share Recipes for $title', style: TextStyle(fontSize: 15)),
              content: SingleChildScrollView(
                child: Form(
                  // Wrap the content with Form widget
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(color: Colors.black),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                        ),
                        onChanged: (value) {
                          text = value;
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
                        decoration: InputDecoration(
                          labelText: 'Instructions',
                          labelStyle: TextStyle(color: Colors.black),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                        ),
                        onChanged: (value) {
                          secondTitle = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter instructions';
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
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cook Time',
                                style: TextStyle(color: Colors.black),
                              ),
                              Text(
                                _formatTime(prepHours, prepMinutes),
                                style: TextStyle(color: Colors.black),
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
                            child: Text(value, style: TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            difficultyLevel = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Difficulty Level',
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyan),
                          ),
                          labelStyle: TextStyle(color: Colors.black),
                        ),
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.arrow_drop_down,
                            color: Colors.black), // Change the color here
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
                  child: Text(
                    'Share',
                    style: TextStyle(color: Colors.cyan),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      int totalPrepTime = (prepHours ?? 0) * 60 + (prepMinutes ?? 0);
                      _processInput(text, secondTitle, difficultyLevel,
                          imageFile, videoFile, userName, totalPrepTime);
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

  void _showTimePickerDialog(BuildContext context, Function(int, int) onTimeSelected) {
    int selectedHours = 0;
    int selectedMinutes = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('How long does it take to cook this recipe?', style: TextStyle(fontSize: 13),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TimePickerSpinner(
                is24HourMode: true,
                normalTextStyle: TextStyle(fontSize: 16, color: Colors.black),
                highlightedTextStyle: TextStyle(fontSize: 22, color: Colors.cyan),
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
              child: Text('Cancel', style: TextStyle(color: Colors.cyan),),
            ),
            TextButton(
              onPressed: () {
                onTimeSelected(selectedHours, selectedMinutes);
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: Colors.cyan),),
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


  Future<void> _processInput(
      String title,
      String instructions,
      String? difficultyLevel,
      File? imageFile,
      File? videoFile,
      String userName,
      int totalPrepTime,
      ) async {
    setState(() {
      _isLoading = true; // Set _isLoading to true when upload begins
    });

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
      'text': title,
      'secondTitle': instructions,
      'difficultyLevel': difficultyLevel,
      'userName': userName,
      'timestamp': now,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'liked': 0,
      'disliked': 0,
      'cookingTime': totalPrepTime,
    };

    try {
      await firestore.collection('recipes').add(data);
      Fluttertoast.showToast(
          msg: "Recipes Shared",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.cyan,
          textColor: Colors.white,
          fontSize: 13);
    } catch (error) {
      print('Error uploading data: $error');
    } finally {
      setState(() {
        _isLoading = false; // Set _isLoading to false when upload completes
      });
    }
  }

  Future<String?> _uploadFile(File file, String folder) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      Reference reference = storage.ref().child('$folder/$fileName');
      UploadTask uploadTask = reference.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (error) {
      print('Error uploading file: $error');
      return null;
    }
  }}
