import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gym_bay_beo/services/app_globals.dart';

/// Hiển thị thông báo kiểu toast (popup nhỏ) trong app.
/// - Nếu context hiện tại không có Overlay, sẽ fallback sang navigatorKey.
void showAppNotification(
  BuildContext? context,
  String title, {
  Duration duration = const Duration(seconds: 3),
  Color color = Colors.blueAccent,
}) {
  // Ưu tiên overlay hiện tại, fallback nếu null
  BuildContext? safeContext;
  try {
    final overlay = Overlay.of(context!);
    if (overlay != null && context.mounted) {
      safeContext = context;
    }
  } catch (_) {}

  safeContext ??= navigatorKey.currentContext; // fallback
  if (safeContext == null) return;

  final overlay = Overlay.of(safeContext);
  if (overlay == null) return;

  final overlayEntry = OverlayEntry(
    builder: (context) => _NotificationWidget(title: title, color: color),
  );

  overlay.insert(overlayEntry);

  Timer(duration, () {
    if (overlayEntry.mounted) overlayEntry.remove();
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

    // Tự ẩn mượt sau 3s
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
