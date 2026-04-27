// import 'dart:convert';
import 'dart:developer';
import 'dart:io';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'dart:nativewrappers/_internal/vm/lib/developer.dart';

import 'package:cached_network_image/cached_network_image.dart';
//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whisper_chat/apis/apis.dart';
import 'package:whisper_chat/helper/dialogs.dart';
import 'package:whisper_chat/main.dart';
import 'package:whisper_chat/models/chat_user.dart';
import 'package:whisper_chat/screens/auth/login_screen.dart';
//import 'package:whisper_chat/widgets/chat_user_card.dart';

//Profile Screen to show signed in user info
class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formkey = GlobalKey<FormState>();
  String? _image; // Local path of selected image
  // ignore: unused_field
  String? _uploadedImageUrl; // Cloudinary image URL

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    
    return GestureDetector(
      //for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,

        //appBar
        appBar: AppBar(title: const Text('Profile')),

        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 10),
          child: FloatingActionButton.extended(
            onPressed: () async {
              Dialogs.showProgressbar(context);
              //sign out from app
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  //hiding progress dialog
                  Navigator.pop(context);
                  //for moving to home screen
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                });
              });
            },
            icon: Icon(Icons.logout_outlined),
            label: Text('LogOut'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),

        body: Form(
          key: _formkey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  //for adding some space
                  SizedBox(width: mq.width, height: mq.height * .07),
                  //user profile picture
                  Stack(
                    children: [
                      // profile picture
                      _image != null
                          ?
                            // local image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(35),
                              child: Image.file(
                                File(_image!),
                                width: mq.height * .2,
                                height: mq.height * .2,
                                fit: BoxFit.cover,
                              ),
                            )
                          :
                            // image from server
                            ClipRRect(
                              borderRadius: BorderRadius.circular(35),
                              child: CachedNetworkImage(
                                width: mq.height * .2,
                                height: mq.height * .2,
                                fit: BoxFit.cover,
                                imageUrl: widget.user.image,
                                // placeholder: (context, url) => CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                              ),
                            ),

                      // edit image button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          onPressed: () {
                            _showBottomSheet();
                          },
                          elevation: 1,
                          shape: const CircleBorder(),
                          color: Colors.white70,
                          child: Icon(Icons.edit),
                        ),
                      ),
                    ],
                  ),

                  //for adding some space
                  SizedBox(height: mq.height * .03),

                  Text(
                    widget.user.email,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  //for adding some space
                  SizedBox(height: mq.height * .03),

                  TextFormField(
                    initialValue: widget.user.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required field',
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person,
                        //color: Colors.deepPurple
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter your name!',
                      label: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  //for adding some space
                  SizedBox(height: mq.height * .03),

                  TextFormField(
                    initialValue: widget.user.about,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required field',
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.info_outline,
                        //color: Colors.deepPurple,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'eg. Using Whisper!',
                      label: Text(
                        'About',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  //for adding some space
                  SizedBox(height: mq.height * .05),

                  // for update button
                  // ElevatedButton.icon(
                  //   style: ElevatedButton.styleFrom(
                  //     elevation: 2,
                  //     minimumSize: Size(mq.width * .4, mq.height * .06)),
                  //   onPressed: () {
                  //     if(_formkey.currentState!.validate()) {
                  //       _formkey.currentState!.save();
                  //       APIs.updateUserInfo().then((value) {
                  //         Dialogs.showSnackbar(context,
                  //         'Profile updated successfully');
                  //       });
                  //       log('Inside validator!');
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 2.5,
                      backgroundColor: Color.fromARGB(225, 252, 246, 255),
                      foregroundColor: Colors.black,
                      minimumSize: Size(mq.width * .4, mq.height * .06),
                    ),
                    onPressed: () async {
                      if (_formkey.currentState!.validate()) {
                        _formkey.currentState!.save();

                        // show progress dialog
                        Dialogs.showProgressbar(context);

                        // if user selected new image, upload it to Cloudinary
                        // if(_image != null) {
                        //   try {
                        //     final url = await APIs.uploadImageToCloudinary(File(_image!));
                        //     _uploadedImageUrl = url;
                        //     APIs.me.image = url; // update profile image url
                        //   } catch(e) {
                        //     Navigator.pop(context);
                        //     Dialogs.showSnackbar(context, 'Image upload failed!');
                        //     return;
                        //   }
                        // }
                        // if user selected new image, upload it to Cloudinary
                        if (_image != null) {
                          try {
                            final String? url =
                                await APIs.uploadImageToCloudinary(
                                  File(_image!),
                                  'whisper_chat_profiles/${APIs.user.uid}'
                                );

                            if (url != null) {
                              _uploadedImageUrl = url;
                              APIs.me.image = url; // update profile image url
                            } else {
                              throw 'Image upload returned null URL';
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            Dialogs.showSnackbar(
                              context,
                              'Image upload failed!',
                            );
                            return;
                          }
                        }

                        // update user info to server
                        await APIs.updateUserInfo();

                        // hide progress dialog
                        Navigator.pop(context);

                        // notify user
                        Dialogs.showSnackbar(
                          context,
                          'Profile updated successfully',
                        );

                        log('Profile updated!');
                      }
                    },
                    icon: Icon(Icons.edit, size: 26),
                    label: Text('Update', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // bottom sheet for picking profile picture
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
            top: mq.height * 0.03,
            bottom: mq.height * 0.05,
          ),
          children: [
            // pick dp label
            const Text(
              'Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),

            // for adding some space
            SizedBox(height: mq.height * .02),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // pick from gallery button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    fixedSize: Size(mq.width * 0.27, mq.height * 0.12),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    // Pick an image.
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      log(
                        'Image Path: ${image.path} -- MimeType: ${image.mimeType}',
                      );
                      setState(() {
                        _image = image.path;
                      });
                      // for hiding bottom sheet
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/add_image.png'),
                ),

                // pick camera button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    fixedSize: Size(mq.width * 0.27, mq.height * 0.12),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    // Pick an image.
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      log('Image Path: ${image.path}');
                      setState(() {
                        _image = image.path;
                      });
                      // for hiding bottom sheet
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/camera.png'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
