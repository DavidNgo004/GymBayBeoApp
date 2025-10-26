import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:gym_bay_beo/conf/app_colors.dart';

class PTChatPage extends StatefulWidget {
  final String chatId;
  final String customerId;
  final String customerName;
  final String customerAvatar;

  const PTChatPage({
    super.key,
    required this.chatId,
    required this.customerId,
    required this.customerName,
    required this.customerAvatar,
  });

  @override
  State<PTChatPage> createState() => _PTChatPageState();
}

class _PTChatPageState extends State<PTChatPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final currentUser = _auth.currentUser!;
    final ptId = currentUser.uid;
    final messageText = text;
    _msgController.clear();
    FocusScope.of(context).unfocus();

    final chatRef = _firestore.collection('chats').doc(widget.chatId);

    // 📨 Gửi tin nhắn (không chặn UI)
    unawaited(
      chatRef.collection('messages').add({
        'text': messageText,
        'senderId': ptId,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );

    // 🔄 Cập nhật chat summary
    unawaited(
      chatRef.update({
        'lastMessage': messageText,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );

    // 🔔 Gửi thông báo cho khách hàng
    unawaited(() async {
      try {
        final ptUid = _auth.currentUser!.uid;

        // Lấy thông tin PT
        final ptSnap = await _firestore.collection('pts').doc(ptUid).get();
        final ptData = ptSnap.data() ?? {};

        // Lấy đúng ptId đang gắn với chat (vì có thể khác user đang đăng nhập)
        final chatSnap = await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .get();
        final chatData = chatSnap.data() ?? {};
        final chatPtId = chatData['ptId'];

        await _firestore.collection('notifications').add({
          'userId': widget.customerId,
          'title': 'Tin nhắn mới từ PT ${ptData['name'] ?? ''}',
          'body': messageText,
          'isRead': false,
          'type': 'chat',
          'chatId': widget.chatId,
          'ptId': chatPtId, // ✅ Lưu đúng id PT trong chat
          'ptName': ptData['name'] ?? '',
          'ptAvatar': ptData['imageUrl'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('❌ Lỗi khi gửi thông báo: $e');
      }
    }());

    // Cuộn xuống dưới cùng
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
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
                backgroundImage: NetworkImage(widget.customerAvatar),
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
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100);

    return StreamBuilder<QuerySnapshot>(
      stream: messagesRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
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
            final isMe = d['senderId'] == _auth.currentUser!.uid;
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
                controller: _msgController,
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.customerAvatar),
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(width: 12),
            Text(widget.customerName),
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
