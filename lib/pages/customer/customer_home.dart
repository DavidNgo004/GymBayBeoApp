import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'package:gym_bay_beo/widgets/app_notification.dart';
import 'package:gym_bay_beo/widgets/confirm_logout_dialog.dart';
import 'package:gym_bay_beo/pages/customer/profile/profile_page.dart';
import 'package:gym_bay_beo/pages/customer/package/packages_page.dart';
import 'package:gym_bay_beo/pages/customer/schedule/workout_schedule_page.dart';
import 'package:gym_bay_beo/pages/customer/check-in/checkin_page.dart';
import 'package:gym_bay_beo/pages/customer/progress/progress_page.dart';
import 'package:gym_bay_beo/pages/customer/pt/pt_list_page.dart';
import 'package:gym_bay_beo/pages/customer/notification/notification_page.dart';
import 'package:gym_bay_beo/services/notification_service.dart';

import 'package:gym_bay_beo/pages/customer/chatbot_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String? userName;
  String? imageUrl;
  bool hasPT = false;
  String? ptId;
  late final PageController _pageController;
  StreamSubscription? _chatNotifSub;
  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initData();
    _checkTodayWorkout();

    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        resumeCallBack: () async {
          _listenAllNotifications();
        },
      ),
    );
  }

  Future<void> _initData() async {
    await _fetchUserInfo();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _listenAllNotifications();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chatNotifSub?.cancel();
    super.dispose();
  }

  Future<void> _checkTodayWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await NotificationService().checkWorkoutScheduleAndNotify(user.uid);
    }
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? "Người dùng";
          imageUrl = doc.data()?['imageUrl'];
          ptId = doc.data()?['ptId'];
          hasPT = ptId != null && ptId!.isNotEmpty;
        });
      }
    }
  }

  void _listenAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _chatNotifSub?.cancel();

    _chatNotifSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isShown', isEqualTo: false)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) async {
          if (!mounted || snapshot.docChanges.isEmpty) return;

          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data == null) continue;

              final title = data['title'] ?? "Thông báo mới";
              final body = data['body'] ?? "";

              HapticFeedback.mediumImpact();

              try {
                await _audioPlayer.play(AssetSource('sounds/quack.mp3'));
              } catch (e) {
                debugPrint("Lỗi phát âm thanh thông báo: $e");
              }

              showAppNotification(context, "$title: $body");
              change.doc.reference.update({'isShown': true});
            }
          }
        });
  }

  List<Widget> get _pages => [
    _buildHomeContent(context),
    const WorkoutSchedulePage(),
    const CheckinPage(),
    const ProgressPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          userName != null ? "Xin chào, $userName 👋" : "Xin chào...",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.primary,
          ),
        ),
        actions: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where(
                  'userId',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                )
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unread = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                      if (result == 'go_to_schedule') {
                        setState(() => _selectedIndex = 1);
                        _pageController.jumpToPage(1);
                      }
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread > 9 ? "9+" : unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.of(
                context,
              ).push(_createRoute(const ProfilePage()));
              _fetchUserInfo();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: Hero(
                tag: 'user-avatar',
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                      ? NetworkImage(imageUrl!)
                      : const AssetImage('assets/images/avatar_placeholder.png')
                            as ImageProvider,
                ),
              ),
            ),
          ),
        ],
      ),

      //floating chatbot button
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatBotPage()),
          );
        },
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) async {
          if (index == 4) {
            await showLogoutConfirmDialog(context);
          } else {
            _navigateTo(index);
          }
        },
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.primary,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Lịch tập",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: "Check-in",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: "Tiến trình",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Đăng xuất"),
        ],
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  void _navigateTo(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowTotoro.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.network(
              "https://media3.giphy.com/media/DtkOAxWAFUkCI/giphy.gif",
              height: 275,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Tính năng của bạn",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildMenuCard(
                Icons.fitness_center_rounded,
                "Gói tập",
                Colors.blueAccent,
                () {
                  Navigator.of(
                    context,
                  ).push(_createRoute(PackagesPage(userId: user!.uid)));
                },
              ),
              _buildMenuCard(
                Icons.calendar_today_rounded,
                "Lịch tập",
                Colors.orangeAccent,
                () => _navigateTo(1),
              ),
              _buildMenuCard(
                Icons.qr_code_scanner_rounded,
                "Check-in",
                Colors.teal,
                () => _navigateTo(2),
              ),
              _buildMenuCard(
                Icons.show_chart_rounded,
                "Tiến trình",
                Colors.purpleAccent,
                () => _navigateTo(3),
              ),
              _buildMenuCard(
                Icons.people_alt_rounded,
                "Huấn luyện viên",
                Colors.limeAccent,
                () => Navigator.of(
                  context,
                ).push(_createRoute(const PTListPage())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.1),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  radius: 30,
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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

class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function()? resumeCallBack;

  LifecycleEventHandler({this.resumeCallBack});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resumeCallBack?.call();
    }
  }
}
