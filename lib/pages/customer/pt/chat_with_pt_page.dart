import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../conf/app_colors.dart';

class ChatWithPTPage extends StatefulWidget {
  final String chatId;
  final String ptId;
  final String? ptName;
  final String? ptAvatar;

  const ChatWithPTPage({
    super.key,
    required this.chatId,
    required this.ptId,
    this.ptName,
    this.ptAvatar,
  });

  @override
  State<ChatWithPTPage> createState() => _ChatWithPTPageState();
}

class _ChatWithPTPageState extends State<ChatWithPTPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late String chatId;
  String? currentUid;
  Map<String, dynamic>? ptData;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    currentUid = _auth.currentUser?.uid;
    chatId = widget.chatId ?? '${currentUid}_${widget.ptId}';
    _ensureChatDoc();
    _loadPT();
    _loadUser();
  }

  Future<void> _ensureChatDoc() async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final snap = await chatRef.get();
    if (!snap.exists) {
      await chatRef.set({
        'userId': currentUid,
        'ptId': widget.ptId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _loadPT() async {
    final doc = await _firestore.collection('pts').doc(widget.ptId).get();
    if (doc.exists) setState(() => ptData = doc.data());
  }

  Future<void> _loadUser() async {
    final doc = await _firestore.collection('customers').doc(currentUid).get();
    if (doc.exists) setState(() => userData = doc.data());
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final msg = {
      'senderId': currentUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final chatRef = _firestore.collection('chats').doc(chatId);
    await chatRef.collection('messages').add(msg);
    await chatRef.update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final userName = userData != null
        ? (userData!['name'] ?? 'Khách hàng')
        : 'Khách hàng';

    // tạo thông báo cho PT
    await _firestore.collection('pt_notifications').add({
      'ptId': widget.ptId,
      'title': '💬 $userName',
      'body': text,
      'isRead': false,
      'isShown': false,
      'createdAt': FieldValue.serverTimestamp(),
      'chatId': chatId,
      'userId': currentUid,
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageItem(DocumentSnapshot msgDoc, bool isMe) {
    final data = msgDoc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final time = createdAt != null ? DateFormat('HH:mm').format(createdAt) : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    widget.ptAvatar != null && widget.ptAvatar!.isNotEmpty
                    ? NetworkImage(widget.ptAvatar!)
                    : const NetworkImage(
                        'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                      ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isMe ? AppColors.bgMyChat : AppColors.bgNotMeChat,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 14),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 2),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    data['text'] ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final messagesRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100);

    return StreamBuilder<QuerySnapshot>(
      stream: messagesRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final isMe = d['senderId'] == currentUid;
            return _buildMessageItem(d, isMe);
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = ptData != null
        ? (ptData!['name'] ?? 'PT')
        : 'Trò chuyện với PT';
    final avatar = ptData != null ? (ptData!['imageUrl'] as String? ?? '') : '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              backgroundColor: Colors.grey[300],
              child: avatar.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildInput(),
        ],
      ),
    );
  }
}
