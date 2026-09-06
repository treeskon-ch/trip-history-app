import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
// import 'plans_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final GlobalKey<MapScreenState> _mapKey = GlobalKey();
  final GlobalKey<HistoryScreenState> _historyKey = GlobalKey();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MapScreen(key: _mapKey),
      // PlansScreen(
      //   onPlanSelected: (plan) {
      //     _mapKey.currentState?.setPlan(plan);
      //     setState(() {
      //       _selectedIndex = 0; // Go back to Map
      //     });
      //   },
      // ),
      HistoryScreen(key: _historyKey),
      const ProfileScreen(),
    ];
    _setupFCMForegroundListener();
  }

  void _setupFCMForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(message.notification!.title ?? 'แจ้งเตือนใหม่'),
            content: Text(message.notification!.body ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง', style: TextStyle(color: AppColors.primaryGreen)),
              ),
            ],
          ),
        );
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      _historyKey.currentState?.loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.mapLocationDot, size: 20),
              label: 'แผนที่',
            ),
            // BottomNavigationBarItem(
            //   icon: FaIcon(FontAwesomeIcons.listCheck, size: 20),
            //   label: 'แผนงาน',
            // ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.clipboardList, size: 20),
              label: 'ประวัติ',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.circleUser, size: 20),
              label: 'โปรไฟล์',
            ),
          ],
        ),
      ),
    );
  }
}
