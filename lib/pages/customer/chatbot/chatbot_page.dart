import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import '../../../services/gemini_service.dart';
import '../../../services/firestore_service.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final gemini = GeminiService();
  final fire = FirestoreService();
  bool _isLoading = false;

  late final String userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? "guest";
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    _controller.clear();

    final prompt =
        """
Bạn là chatbot Gym Bay Béo 💪.
Hãy trả lời bằng tiếng Việt thân thiện, vui vẻ, có emoji nếu cần thiết.
Trả lời ngôn ngữ dễ hiểu và đi đúng vào trọng tâm câu trả lời không dài dòng.
Nếu được hỏi:
- Giờ mở cửa: 6h sáng - 22h30 tối hàng ngày.
- Dịch vụ: gym, yoga, PT cá nhân, dinh dưỡng.
- PT: tư vấn PT, giảm cân, tăng cơ, lịch tập.
- Dinh dưỡng: hướng dẫn ăn uống phù hợp với mục tiêu tập, tạo thực đơn cá nhân.
- Địa chỉ: 428/10A Chiến Lược, Bình Trị Đông A, Bình Tân, TP. HCM.
- Tạm biệt: Gym Bay Béo cảm ơn bạn,hẹn gặp lại và chào tạm biệt bạn.
- Chủ phòng tập: Ngô Ngọc Hòa, SĐT: 089646865.
- Khi hỏi về tạo thực đơn trong 1 tuần. Hãy tạo thực đơn chi tiết cho từng bữa trong ngày. Kèm lời khuyên dinh dưỡng.
- Khi hỏi về lịch tập. Hãy tạo lịch tập chi tiết cho từng ngày trong tuần. Kèm lời khuyên tập luyện.
- Khi hỏi về giảm cân hoặc tăng cơ. Hãy đưa ra lời khuyên chi tiết về tập luyện và dinh dưỡng phù hợp với mục tiêu đó.
Fanpage: https://www.facebook.com/hoa.ngo.402850
Câu hỏi: $text
""";

    final response = await gemini.sendMessage(prompt);

    await fire.saveChatMessage(
      userId: userId,
      userMessage: text,
      botResponse: response,
    );

    setState(() => _isLoading = false);
  }

  Future<void> _deleteChat(String id) async {
    await fire.deleteChatEntry(id);
  }

  Future<void> _deleteAllChats() async {
    final chats = await fire.userChatHistoryStream(userId).first;
    for (final chat in chats) {
      await fire.deleteChatEntry(chat['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chatbot Gym Bay Béo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Xóa toàn bộ tin nhắn',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text(
                    'Xóa toàn bộ lịch sử chat?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.caution,
                    ),
                  ),
                  content: const Text(
                    'Hành động này sẽ xóa vĩnh viễn tất cả lịch sử chat.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.caution,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) await _deleteAllChats();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: fire.userChatHistoryStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Xin chào 👋\nChào mừng bạn đến với Chatbot Gym Bay Béo 💪',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Dismissible(
                      key: ValueKey(msg['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteChat(msg['id']),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BubbleNormal(
                            text: msg['userMessage'],
                            isSender: true,
                            color: AppColors.primary,
                            tail: true,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          // Bot response bubble rendered with Markdown inside a decorated Container
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: MarkdownBody(
                                data: msg['botResponse'] ?? '',
                                selectable: true, // cho phép copy text
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  em: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                  code: TextStyle(
                                    backgroundColor: Colors.grey.shade300,
                                    fontFamily: 'monospace',
                                  ),
                                  blockquote: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(10.0),
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
                const SizedBox(width: 10),
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
        ],
      ),
    );
  }
}
