import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whisper_chat/helper/encryption_helper.dart';
import 'package:whisper_chat/models/chat_user.dart';
import 'dart:io';

import 'package:whisper_chat/models/message.dart';

class APIs {
  // for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for storing self information
  static late ChatUser me;

  // for getting current user
  static User get user => auth.currentUser!;

  // for checking if user exists or not
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  // for Initializing Cloudinary with your credentials
  static final _cloudinary = Cloudinary.signedConfig(
    apiKey: '822541239524932', // Cloudinary API Key
    apiSecret: 'Gu4dvvGPdNoq-Baj3D3X3ZeOPCA', // Cloudinary API Secret
    cloudName: 'dispm8xfe', // Cloudinary Cloud Name
  );

  // for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists

      log('user exists: ${data.docs.first.data()}');

      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user doesn't exists

      return false;
    }
  }

  // for getting current user info
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  //for creating a new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
      image: user.photoURL.toString(),
      about: "Hey I'm using Whisper!",
      name: user.displayName.toString(),
      createdAt: time,
      lastActive: time,
      id: user.uid,
      isOnline: false,
      pushToken: '',
      email: user.email.toString(),
    );

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // for getting all known users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  // for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
    List<String> userIds) {
    log('\nUserIds: $userIds');

    return firestore
        .collection('users')
        .where('id',
            whereIn: userIds.isEmpty
                ? ['']
                : userIds) //because empty list throws an error
        // .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }


  // for updating user info
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  // Method to upload an image file to Cloudinary
  // Added a 'folder' parameter to store images in conversation-specific folders
  static Future<String?> uploadImageToCloudinary(
    File imageFile,
    String conversationID,
  ) async {
    try {
      // Upload the image to the specified folder
      final response = await _cloudinary.upload(
        file: imageFile.path, // Path to the image file
        resourceType: CloudinaryResourceType.image, // Specify file type
        folder: 'chats/$conversationID', // Dynamic folder for conversation
      );

      // Check if upload was successful and return the image URL
      if (response.isSuccessful) {
        print('✅ Cloudinary upload successful!');
        print('Image URL: ${response.secureUrl}');
        return response.secureUrl; // Return secure URL for the uploaded image
      } else {
        print('❌ Upload failed: ${response.error.toString()}');
        return null;
      }
    } catch (e) {
      // Handle any unexpected exceptions during upload
      print('❌ Exception during Cloudinary upload: $e');
      return null;
    }
  }

  // for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
    ChatUser ChatUser,
  ) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: ChatUser.id)
        .snapshots();
  }

  // for updating update online or last active status
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  //*********** Chat screen related APIs ***********

  // chats (collection) --> conversation_id (doc) --> messages (collection) --> message (doc)

  // for getting conversation id
  static getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // for getting all messages of conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
    ChatUser user,
  ) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // for sending messages
  static Future<void> sendMessage(ChatUser chatUser, String msg, Type type) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // message to send
    final Message message = Message(
      toid: chatUser.id,
      msg: EncryptionHelper.encryptText(msg), // Encrypting the message
      read: '',
      type: Type.text,
      fromid: user.uid,
      sent: time,
    );

    final ref = firestore.collection(
      'chats/${getConversationID(chatUser.id)}/messages/',
    );
    await ref.doc(time).set(message.toJson());
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromid)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //for getting last message
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
    ChatUser user,
  ) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //for sending image
  static Future<void> sendImageMessage(
    ChatUser chatUser,
    String imageUrl,
  ) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final Message message = Message(
      toid: chatUser.id,
      msg: imageUrl,
      read: '',
      type: Type.image,
      fromid: user.uid,
      sent: time,
    );

    final ref = firestore.collection(
      'chats/${getConversationID(chatUser.id)}/messages/',
    );
    await ref.doc(time).set(message.toJson());
  }
}
