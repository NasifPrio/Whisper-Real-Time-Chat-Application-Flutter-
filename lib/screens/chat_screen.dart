//import 'dart:nativewrappers/_internal/vm/lib/developer.dart';
// import 'dart:convert';
// import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whisper_chat/apis/apis.dart';
import 'package:whisper_chat/helper/dialogs.dart';
import 'package:whisper_chat/helper/my_date_util.dart';
import 'package:whisper_chat/main.dart';
import 'package:whisper_chat/models/chat_user.dart';
import 'package:whisper_chat/models/message.dart';
import 'package:whisper_chat/widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //list for messages
  List<Message> _list = [];

  //for handling message text changes
  final _textController = TextEditingController();

  //showEmoji for showing value of showing ir hiding emojis
  //isUploading for checking if image is uploading or not
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        // if emojis shown & back button is pressed then hide emojis
        // or else simple close current screen on back button click
        onWillPop: () {
          if (_showEmoji) {
            setState(() {
              _showEmoji = !_showEmoji;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          //appBar
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: SafeArea(child: _appBar()),
          ),

          //backgroundColor: const Color.fromARGB(255, 255, 255, 255),

          //body
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: APIs.getAllMessages(widget.user),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      //if data is loading
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const SizedBox();

                      //if data is loaded then show
                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot.data?.docs;
                        _list =
                            data
                                ?.map((e) => Message.fromJson(e.data()))
                                .toList() ??
                            [];

                        if (_list.isNotEmpty) {
                          return ListView.builder(
                            reverse: true,
                            itemCount: _list.length,
                            padding: EdgeInsets.only(top: mq.height * .01),
                            physics: BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            itemBuilder: (context, index) {
                              return MessageCard(message: _list[index]);
                            },
                          );
                        } else {
                          return const Center(
                            child: Text(
                              'Say Hi... 👋🏼',
                              style: TextStyle(fontSize: 20),
                            ),
                          );
                        }
                    }
                  },
                ),
              ),

              //image uploading indicator
              if (_isUploading)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),

              //calling bottom chat input field
              _chatInput(),

              if (_showEmoji)
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController: _textController,
                      config: Config(
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax: 30 * (Platform.isIOS ? 1.20 : 1.0),
                        ),
                        bottomActionBarConfig: BottomActionBarConfig(
                          enabled: false,
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          backgroundColor: Colors.white,
                          iconColorSelected: Colors.black,
                          indicatorColor: Colors.black, // or darkGrey
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  //appBar widget
  Widget _appBar() {
    return InkWell(
      onTap: () {},
      child: StreamBuilder(
        stream: APIs.getUserInfo(widget.user),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list =
              data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

          return Row(
            children: [
              //back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.black87,
                ),
              ),

              //user profile picture
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  width: mq.height * .05,
                  height: mq.height * .05,
                  imageUrl: list.isNotEmpty ? list[0].image : widget.user.image,
                  // placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                      const CircleAvatar(child: Icon(Icons.person)),
                ),
              ),

              //for adding some space
              SizedBox(width: 10),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //user name
                  Text(
                    list.isNotEmpty ? list[0].name : widget.user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  //last seen time
                  Text(
                    list.isNotEmpty
                        ? list[0].isOnline
                              ? 'Online'
                              : MyDateUtil.getLastActiveTime(
                                  context: context,
                                  lastActive: list[0].lastActive,
                                )
                        : MyDateUtil.getLastActiveTime(
                            context: context,
                            lastActive: widget.user.lastActive,
                          ),

                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  //bottom chat input field
  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mq.width * .01, // left
        mq.height * .008, // top
        mq.width * .01, // right
        mq.height * .025, // bottom
      ),
      child: Row(
        children: [
          //input field and buttons
          Expanded(
            child: Card(
              color: Colors.white,
              elevation: 2,
              child: Row(
                children: [
                  //emoji button
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _showEmoji = !_showEmoji);
                    },
                    icon: const Icon(Icons.emoji_emotions_rounded, size: 26),
                  ),

                  //text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        if (_showEmoji)
                          setState(() => _showEmoji = !_showEmoji);
                      },
                      decoration: InputDecoration(
                        hintText: 'Type something...',
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  //gallery button
                  // IconButton(
                  //   onPressed: () {},
                  //   icon: const Icon(Icons.image, size: 26),
                  // ),

                  // camera button
                  // IconButton(
                  //   onPressed: () {},
                  //   icon: const Icon(Icons.camera_alt_rounded, size: 26),
                  // ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // gallery button
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          try {
                            final ImagePicker picker = ImagePicker();

                            // Pick multiple images
                            final List<XFile> images = await picker
                                .pickMultiImage();

                            if (images.isNotEmpty) {
                              final String conversationID =
                                  APIs.getConversationID(widget.user.id);

                              for (XFile image in images) {
                                File file = File(image.path);

                                setState(() => _isUploading = true);

                                // Upload image to Cloudinary inside conversation-specific folder
                                final String? url =
                                    await APIs.uploadImageToCloudinary(
                                      file,
                                      conversationID,
                                    );

                                if (url != null) {
                                  await APIs.sendImageMessage(widget.user, url);
                                } else {
                                  if (context.mounted) {
                                    Dialogs.showSnackbar(
                                      context,
                                      'Image upload failed!',
                                    );
                                  }
                                }

                                setState(() => _isUploading = false);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Dialogs.showSnackbar(
                                context,
                                'Something went wrong!',
                              );
                            }
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.image, size: 26),
                        ),
                      ),

                      // camera button
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                            );

                            if (image != null) {
                              File file = File(image.path);
                              final String conversationID =
                                  APIs.getConversationID(widget.user.id);

                              // Pass only the conversationID, no 'chats/' prefix here
                              final String? url =
                                  await APIs.uploadImageToCloudinary(
                                    file,
                                    conversationID,
                                  );

                              if (url != null) {
                                await APIs.sendImageMessage(widget.user, url);
                              } else {
                                if (context.mounted) {
                                  Dialogs.showSnackbar(
                                    context,
                                    'Image upload failed!',
                                  );
                                }
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Dialogs.showSnackbar(
                                context,
                                'Something went wrong!',
                              );
                            }
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.camera_alt_rounded, size: 26),
                        ),
                      ),
                    ],
                  ),

                  // Row(
                  //   mainAxisSize: MainAxisSize.min,
                  //   crossAxisAlignment: CrossAxisAlignment.center,
                  //   children: [
                  //     // gallery button
                  //     InkWell(
                  //       customBorder: CircleBorder(),
                  //       onTap: () {
                  //         // handle gallery
                  //       },
                  //       child: const Padding(
                  //         padding: EdgeInsets.all(8), // Adjust for touch area
                  //         child: Icon(Icons.image, size: 26),
                  //       ),
                  //     ),

                  //     // camera button
                  //     InkWell(
                  //       customBorder: CircleBorder(),
                  //       onTap: () {
                  //         // handle camera
                  //       },
                  //       child: const Padding(
                  //         padding: EdgeInsets.all(8), // Same touch area
                  //         child: Icon(Icons.camera_alt_rounded, size: 26),
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  // for adding some space
                  SizedBox(width: mq.width * 0.01),
                ],
              ),
            ),
          ),

          // for adding some space
          SizedBox(width: mq.width * 0.007),

          //send message button
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if (_list.isEmpty) {
                  //on first message (add user to my_user collection of chat user)
                  APIs.sendFirstMessage(
                      widget.user, _textController.text, Type.text);
                } else {
                  //simply send message
                  APIs.sendMessage(
                      widget.user, _textController.text, Type.text);
                }
                _textController.text = '';
              }
            },
            elevation: 1,
            minWidth: 0,
            color: Colors.white,
            padding: EdgeInsets.only(top: 10, bottom: 10, right: 7, left: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.send, size: 30),
          ),
        ],
      ),
    );
  }
}
