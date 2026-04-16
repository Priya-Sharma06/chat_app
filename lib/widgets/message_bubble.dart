import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;

  const MessageBubble({super.key, required this.data, required this.isMe});

  @override
  Widget build(BuildContext context) {
    String timestamp =
        data['timestamp'] != null
            ? DateFormat('hh:mm a').format(data['timestamp'].toDate())
            : "Just now";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.pinkAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isMe ? Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : Radius.circular(15),
          ),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['photoUrl'] != null && data['photoUrl'] != '')
                  CircleAvatar(
                    radius: 15,
                    backgroundImage: NetworkImage(data['photoUrl']),
                  ),
                SizedBox(width: 8),
                Text(
                  data['sender'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  timestamp,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              data['text'],
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
