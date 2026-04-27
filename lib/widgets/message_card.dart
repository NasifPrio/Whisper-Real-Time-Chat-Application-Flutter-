//import 'dart:nativewrappers/_internal/vm/lib/developer.dart';
//import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:whisper_chat/apis/apis.dart';
import 'package:whisper_chat/helper/encryption_helper.dart';
import 'package:whisper_chat/helper/my_date_util.dart';
import 'package:whisper_chat/main.dart';
import 'package:whisper_chat/models/message.dart';

//for showing single message details
class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    
    return APIs.user.uid == widget.message.fromid
        ? _greyMessages()
        : _silverMessages();
  }

  //sender messages
  Widget _silverMessages() {
    // update last read message if sender and receiver are different
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }

    final isImage = widget.message.type == Type.image;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // message content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(mq.height * 0.01),
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * .04,
              vertical: mq.height * .01,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color.fromARGB(255, 131, 131, 131),
                width: 2,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      widget.message.msg,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          width: 150,
                          height: 150,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100),
                    ),
                  )
                : Text(
                    EncryptionHelper.decryptText(widget.message.msg),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ),

        // sent time
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateUtil.getFormattedTime(
              context: context,
              time: widget.message.sent,
            ),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  //user messages
  Widget _greyMessages() {
    final isImage = widget.message.type == Type.image;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //for showing time and read status
        Row(
          children: [
            SizedBox(width: mq.width * .04),
            if (widget.message.read.isNotEmpty)
              Icon(
                Icons.done_all,
                color: const Color.fromARGB(255, 46, 165, 224),
                size: 20,
              ),
            SizedBox(width: mq.width * .02),
            Text(
              MyDateUtil.getFormattedTime(
                context: context,
                time: widget.message.sent,
              ),
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),

        // message content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(mq.height * 0.01),
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * .04,
              vertical: mq.height * .01,
            ),
            decoration: BoxDecoration(
              color: const Color.fromARGB(206, 218, 218, 218),
              border: Border.all(
                color: const Color.fromARGB(255, 131, 131, 131),
                width: 2,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
                bottomLeft: Radius.circular(25),
              ),
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      widget.message.msg,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          width: 150,
                          height: 150,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100),
                    ),
                  )
                : Text(
                    EncryptionHelper.decryptText(widget.message.msg),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
