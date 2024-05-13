import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../provider/dark_theme_provider.dart';
import '../widgets/text_widget.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final QueryDocumentSnapshot recipe;

  RecipeDetailsScreen({required this.recipe});

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  bool _isLoading = true;
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    // Initialize the video player controller
    _videoPlayerController = VideoPlayerController.network(
      widget.recipe['videoUrl'],
    );
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoInitialize: true,
      autoPlay: false,
      looping: false,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.isInitialized) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController.dispose();
    _chewieController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context, listen: false);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;
    Map<String, dynamic> recipeData =
        widget.recipe.data() as Map<String, dynamic>;

    Timestamp timestamp = recipeData['timestamp'];
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(dateTime);

    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextWidget(
          text: 'Recipes Details',
          color: color,
          textSize: 24,
          isTitle: true,
        ),
        titleSpacing: 10,
        iconTheme: IconThemeData(
          color: color, // Change the color of the back arrow here
        ),
      ),
      body: Container(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 300, // Adjust height as needed
                      width: MediaQuery.of(context)
                          .size
                          .width, // Adjust width as needed
                      child: Padding(
                        padding: EdgeInsets.all(8), // Adjust padding as needed
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Chewie(controller: _chewieController);
                          },
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.all(8),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              recipeData['text'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Difficulty Level: ${recipeData['difficultyLevel']}',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Shared by: ${recipeData['userName']}',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Instructions: ${recipeData['secondTitle']}',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Time Posted: ${formattedTime}',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
