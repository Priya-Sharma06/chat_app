import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/message_input.dart';
import 'emotion_results_screen.dart';
import 'home_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? initialPeerEmail;
  final bool initialIsGlobal;

  const ChatScreen({
    super.key,
    this.initialPeerEmail,
    this.initialIsGlobal = true,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _peerEmail;
  bool _isGlobalChat = true;

  String? get _currentUserEmail {
    final email = _user?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      return null;
    }
    return email;
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value);
  }

  String? get _conversationId {
    final me = _currentUserEmail;
    final peer = _peerEmail;
    if (me == null || peer == null) {
      return null;
    }

    final participants = [me, peer]..sort();
    return '${participants[0]}__${participants[1]}';
  }

  CollectionReference<Map<String, dynamic>>? get _messagesCollection {
    if (_isGlobalChat) {
      return _firestore.collection('messages');
    }

    final conversationId = _conversationId;
    if (conversationId == null) {
      return null;
    }

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');
  }

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _peerEmail = widget.initialPeerEmail?.trim().toLowerCase();
    _isGlobalChat = widget.initialIsGlobal;

    if (_peerEmail != null) {
      _isGlobalChat = false;
    }

    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    }
  }

  void _switchToGlobal() {
    setState(() {
      _isGlobalChat = true;
      _peerEmail = null;
    });
  }

  Future<void> _openRecentConversations() async {
    final userEmail = _currentUserEmail;
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account email is not available.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Global Chat'),
                  subtitle: const Text('Open everyone chat room'),
                  onTap: () {
                    Navigator.pop(context);
                    _switchToGlobal();
                  },
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream:
                        _firestore
                            .collection('conversations')
                            .where('participants', arrayContains: userEmail)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Private recents are blocked by Firestore permissions. You can still use Global Chat or New Private.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      docs.sort((a, b) {
                        final aTime =
                            (a.data()['updatedAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0;
                        final bTime =
                            (b.data()['updatedAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0;
                        return bTime.compareTo(aTime);
                      });

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('No recent private conversations yet.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final participants =
                              (data['participants'] as List?)?.cast<String>() ??
                              [];

                          final peer = participants.firstWhere(
                            (email) => email.toLowerCase() != userEmail,
                            orElse: () => '',
                          );

                          if (peer.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final lastMessage =
                              (data['lastMessage'] as String?) ??
                              'No messages yet';

                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(peer),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              setState(() {
                                _isGlobalChat = false;
                                _peerEmail = peer;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRecipientDialog() async {
    final controller = TextEditingController(text: _peerEmail ?? '');

    final selectedEmail = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start chat by email'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter recipient email',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim().toLowerCase());
              },
              child: const Text('Open Chat'),
            ),
          ],
        );
      },
    );

    if (!mounted || selectedEmail == null) {
      return;
    }

    final myEmail = _currentUserEmail;
    if (myEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account email is not available.')),
      );
      return;
    }

    if (!_isValidEmail(selectedEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    if (selectedEmail == myEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with your own email.')),
      );
      return;
    }

    setState(() {
      _isGlobalChat = false;
      _peerEmail = selectedEmail;
    });
  }

  Future<void> _detectEmotions() async {
    final messagesCollection = _messagesCollection;
    if (messagesCollection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a recipient first.')),
      );
      return;
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      DateTime fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );
      snapshot =
          await messagesCollection
              .where(
                'timestamp',
                isGreaterThan: Timestamp.fromDate(fiveMinutesAgo),
              )
              .orderBy('timestamp')
              .get();
    } on FirebaseException catch (e) {
      final message =
          e.code == 'permission-denied'
              ? 'No permission to read this chat for emotion detection.'
              : 'Could not read chat history.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    List<String> chatHistory =
        snapshot.docs.map((doc) => doc.data()['text'] as String).toList();

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

  Future<void> _sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final senderEmail = _currentUserEmail;
    final conversationId = _conversationId;
    final messagesCollection = _messagesCollection;

    if (senderEmail == null || messagesCollection == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid chat state')));
      return;
    }

    final messageData = {
      'text': trimmedText,
      'sender': _user?.displayName ?? senderEmail,
      'senderEmail': senderEmail,
      'receiverEmail': _peerEmail,
      'isGlobal': _isGlobalChat,
      'photoUrl': _user?.photoURL ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // ✅ GLOBAL CHAT (simple)
      if (_isGlobalChat) {
        await _firestore.collection('messages').add(messageData);
        return;
      }

      // ✅ PRIVATE CHAT
      if (conversationId == null || _peerEmail == null) {
        throw Exception("Conversation ID missing");
      }

      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      // 🔥 STEP 1: FORCE CREATE CONVERSATION (VERY IMPORTANT)
      await conversationRef.set({
        'participants': [senderEmail, _peerEmail],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': trimmedText,
      }, SetOptions(merge: true));

      // 🔥 STEP 2: ADD MESSAGE (AFTER conversation exists)
      await conversationRef.collection('messages').add(messageData);

      // 🔥 STEP 3: UPDATE LAST MESSAGE
      await conversationRef.update({
        'lastMessage': trimmedText,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("ERROR SENDING MESSAGE: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    }
  }

  Widget _modeButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ModePillButton(
              onPressed: _switchToGlobal,
              icon: const Icon(Icons.public),
              label: const Text('Global Chat'),
              isPrimary: _isGlobalChat,
            ),
            const SizedBox(width: 8),
            _ModePillButton(
              onPressed: _openRecentConversations,
              icon: const Icon(Icons.history),
              label: const Text('Recents'),
            ),
            const SizedBox(width: 8),
            _ModePillButton(
              onPressed: _openRecipientDialog,
              icon: const Icon(Icons.person_search),
              label: const Text('Private Chat'),
              isPrimary: !_isGlobalChat,
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowSenderLabel(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
    int index,
  ) {
    if (!_isGlobalChat) {
      return false;
    }

    if (index == messages.length - 1) {
      return true;
    }

    final currentSender =
        (messages[index].data()['senderEmail'] as String?)
            ?.trim()
            .toLowerCase() ??
        (messages[index].data()['sender'] as String?)?.trim().toLowerCase() ??
        '';
    final previousSender =
        (messages[index + 1].data()['senderEmail'] as String?)
            ?.trim()
            .toLowerCase() ??
        (messages[index + 1].data()['sender'] as String?)
            ?.trim()
            .toLowerCase() ??
        '';

    return currentSender != previousSender;
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> data, {
    required bool showSenderLabel,
    required bool compactTopSpacing,
  }) {
    final isMe =
        data['senderEmail'] == _currentUserEmail ||
        data['sender'] == _user?.displayName;

    final timestamp = data['timestamp'] as Timestamp?;
    final timeText =
        timestamp != null
            ? TimeOfDay.fromDateTime(timestamp.toDate()).format(context)
            : 'Just now';
    final messageText = (data['text'] as String?) ?? '';
    final bubbleColor = Colors.white;
    final bubbleBorderColor = const Color(0xFFD9E1DE);

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 48,
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isMe ? const Radius.circular(18) : const Radius.circular(6),
              bottomRight:
                  isMe ? const Radius.circular(6) : const Radius.circular(18),
            ),
            border: Border.all(color: bubbleBorderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141F3D38),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSenderLabel && !isMe) ...[
                Text(
                  (data['sender'] as String?) ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
              ],
              Text(
                messageText,
                style: const TextStyle(color: Color(0xFF111111), height: 1.15),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A9491),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, compactTopSpacing ? 2 : 5, 10, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bubble,
              const SizedBox(width: 8),
              if ((data['photoUrl'] as String?)?.isNotEmpty == true)
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(data['photoUrl'] as String),
                )
              else
                const SizedBox(width: 28),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, compactTopSpacing ? 2 : 5, 10, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if ((data['photoUrl'] as String?)?.isNotEmpty == true)
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(data['photoUrl'] as String),
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
            bubble,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F6F3),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            if (_user?.photoURL != null)
              CircleAvatar(backgroundImage: NetworkImage(_user!.photoURL!)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isGlobalChat ? 'Global Chat' : 'Chat with $_peerEmail',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1D2A28),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2A4A44)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Recent conversations',
            onPressed: _openRecentConversations,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.mood), onPressed: _detectEmotions),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F1E8), Color(0xFFEAF6F3), Color(0xFFFDF8EF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x332F8F83),
                ),
              ),
            ),
            Positioned(
              left: -70,
              bottom: 120,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33D88A4D),
                ),
              ),
            ),
            Column(
              children: [
                _modeButtons(),
                Expanded(
                  child:
                      _messagesCollection == null
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Tap Private Chat and enter an email to start chatting.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF4D615D)),
                              ),
                            ),
                          )
                          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream:
                                _messagesCollection!
                                    .orderBy('timestamp', descending: true)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Access denied for this chat path. You can still use Global Chat or open another private chat.',
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: _switchToGlobal,
                                          icon: const Icon(Icons.public),
                                          label: const Text(
                                            'Go to Global Chat',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2F8F83),
                                  ),
                                );
                              }

                              final messages = snapshot.data!.docs;

                              if (messages.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No messages yet. Say hello!',
                                    style: TextStyle(color: Color(0xFF4D615D)),
                                  ),
                                );
                              }

                              return ListView.builder(
                                reverse: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 10,
                                ),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final data = messages[index].data();
                                  final compactTopSpacing =
                                      index < messages.length - 1 &&
                                      ((messages[index].data()['senderEmail']
                                                      as String?)
                                                  ?.trim()
                                                  .toLowerCase() ??
                                              (messages[index].data()['sender']
                                                      as String?)
                                                  ?.trim()
                                                  .toLowerCase() ??
                                              '') ==
                                          ((messages[index + 1]
                                                          .data()['senderEmail']
                                                      as String?)
                                                  ?.trim()
                                                  .toLowerCase() ??
                                              (messages[index + 1]
                                                          .data()['sender']
                                                      as String?)
                                                  ?.trim()
                                                  .toLowerCase() ??
                                              '');
                                  return _buildMessageBubble(
                                    data,
                                    showSenderLabel: _shouldShowSenderLabel(
                                      messages,
                                      index,
                                    ),
                                    compactTopSpacing: compactTopSpacing,
                                  );
                                },
                              );
                            },
                          ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.56),
                    border: const Border(
                      top: BorderSide(color: Color(0x22FFFFFF)),
                    ),
                  ),
                  child: MessageInput(onSend: _sendMessage),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModePillButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;
  final bool isPrimary;

  const _ModePillButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        isPrimary ? const Color(0xFF1F5D54) : const Color(0xFF4D615D);

    return TextButton.icon(
      onPressed: onPressed,
      icon: IconTheme(
        data: IconThemeData(color: foregroundColor, size: 19),
        child: icon,
      ),
      label: DefaultTextStyle.merge(
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        child: label,
      ),
      style: TextButton.styleFrom(
        backgroundColor:
            isPrimary ? const Color(0x332F8F83) : const Color(0xD9FFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color:
                isPrimary ? const Color(0xFF5FAE9C) : const Color(0xFFD5E0DC),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
