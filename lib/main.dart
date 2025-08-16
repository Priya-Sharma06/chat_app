import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Chat App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

// ---------------------------
// Home Screen (Login Page)
// ---------------------------
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Navigate to Chat Screen after login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    } catch (e) {
      print("Sign-in error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to Chat App",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Icon(Icons.chat, size: 100, color: Colors.pinkAccent), // Simple Chat Icon
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              icon: Icon(Icons.login, color: Colors.white),
              label: Text("Sign in with Google", style: TextStyle(fontSize: 18,color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------
// Chat Screen
// ---------------------------
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  Future<void> _detectEmotions() async {
    DateTime fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('messages')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
        .orderBy('timestamp')
        .get();


    List<String> chatHistory = snapshot.docs.map((doc) => doc.data()['text'] as String).toList();

    if (chatHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No chat history in the last 5 minutes.")),
      );
      return;
    }

    String backendUrl = 'http://10.0.2.2:8000/analyze_bulk_emotions';
    try {
      var response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': chatHistory}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> results = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmotionResultsScreen(emotionResults: results),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error communicating with the backend.")),
        );
        print("Backend error: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not connect to the backend.")),
      );
      print("Error sending data to backend: $e");
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _firestore.collection('messages').add({
        'text': _messageController.text,
        'sender': _user?.displayName ?? 'Anonymous',
        'photoUrl': _user?.photoURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_user?.photoURL != null)
              CircleAvatar(backgroundImage: NetworkImage(_user!.photoURL!)),
            SizedBox(width: 10),
            Text("Chat App"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.mood),
            onPressed: _detectEmotions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        var messages = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var data = messages[index].data() as Map<String, dynamic>;
            bool isMe = data['sender'] == _user?.displayName;
            return _buildMessageBubble(data, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    String timestamp = data['timestamp'] != null
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
                  CircleAvatar(radius: 15, backgroundImage: NetworkImage(data['photoUrl'])),
                SizedBox(width: 8),
                Text(data['sender'], style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Text(timestamp, style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            SizedBox(height: 5),
            Text(data['text'], style: TextStyle(color: isMe ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Enter message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(icon: Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
          )
        ],
      ),
    );
  }
}

// ---------------------------
// Emotion Results Screen
// ---------------------------
class EmotionResultsScreen extends StatelessWidget {
  final Map<String, dynamic> emotionResults;

  EmotionResultsScreen({required this.emotionResults});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emotion Detection Results"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Emotion Analysis of Last 5 Minutes of Chat:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (emotionResults['dominant_emotion'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  "Dominant Emotion: ${emotionResults['dominant_emotion']} (${emotionResults['dominant_emotion_count']} messages)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 10),
            Text(
              "Emotions per Message:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (emotionResults['emotion_results'] != null && emotionResults['emotion_results'] is List)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: (emotionResults['emotion_results'] as List).length,
                itemBuilder: (context, index) {
                  final result = emotionResults['emotion_results'][index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '"${result['message']}" - Emotion: ${result['emotion']}',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            if (emotionResults['emotion_results'] == null || (emotionResults['emotion_results'] as List).isEmpty)
              Text("No emotions detected in the messages."),
            SizedBox(height: 20),
            Text(
              "Emotion Breakdown:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (emotionResults['emotion_counts'] != null && (emotionResults['emotion_counts'] as Map).isNotEmpty)
              for (var entry in (emotionResults['emotion_counts'] as Map).entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text("${entry.key}: ${entry.value}", style: TextStyle(fontSize: 16)),
                ),
            if (emotionResults['emotion_counts'] == null || (emotionResults['emotion_counts'] as Map).isEmpty)
              Text("No emotion counts available."),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the Chat Screen
              },
              child: Text("Back to Chat"),
            ),
          ],
        ),
      ),
    );
  }
}