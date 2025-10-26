import 'package:flutter/material.dart';
import 'dart:async';

/// Hiển thị thông báo kiểu toast trong app
/// title: tiêu đề hoặc nội dung
/// duration: thời gian hiển thị (mặc định 3s)
/// color: màu background (mặc định xanh dương)
void showAppNotification(
  BuildContext context,
  String title, {
  Duration duration = const Duration(seconds: 3),
  Color color = Colors.blueAccent,
}) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;

  final overlayEntry = OverlayEntry(
    builder: (context) => _NotificationWidget(title: title, color: color),
  );

  overlay.insert(overlayEntry);

  // Tự ẩn sau duration
  Timer(duration, () {
    overlayEntry.remove();
  });
}

class _NotificationWidget extends StatefulWidget {
  final String title;
  final Color color;

  const _NotificationWidget({required this.title, required this.color});

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Tự ẩn sau 3s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offsetAnim,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: widget.color,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
