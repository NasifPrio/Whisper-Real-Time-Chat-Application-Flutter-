import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:whisper_chat/apis/apis.dart';
import 'package:whisper_chat/helper/encryption_helper.dart';
import 'package:whisper_chat/helper/my_date_util.dart';
import 'package:whisper_chat/main.dart';
import 'package:whisper_chat/models/chat_user.dart';
import 'package:whisper_chat/models/message.dart';
import 'package:whisper_chat/screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  //last message info(if null -> no message)
  Message? _message;

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // for navigating to chat screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)),
          );
        },
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
            if (list.isNotEmpty) {
              _message = list[0];
            }

            return ListTile(
              //user profile picture
              // leading: const CircleAvatar(child: Icon(Icons.person)),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  width: mq.height * .055,
                  height: mq.height * .055,
                  imageUrl: widget.user.image,
                  // placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                      const CircleAvatar(child: Icon(Icons.person)),
                ),
              ),

              //user name
              title: Text(
                widget.user.name,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              //last message
              subtitle: Text(
                _message != null
                    ? _message!.type == Type.image
                          ? 'image'
                          : EncryptionHelper.decryptText(_message!.msg)
                    : widget.user.about,
                maxLines: 1,
              ),

              // last message time or unread indicator
              trailing: widget.user.isOnline
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 0, 230, 119),
                        shape: BoxShape.circle,
                      ),
                    )
                  : _message != null
                  ? Text(
                      MyDateUtil.getLastMessageTime(
                        context: context,
                        time: _message!.sent,
                      ),
                      style: const TextStyle(color: Colors.black54),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
