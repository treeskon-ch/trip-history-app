import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/app_colors.dart';
import '../core/local_storage.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final userId = await LocalStorage.getUserId();
    if (userId != null && userId.isNotEmpty) {
      _updateFCMToken(userId); // Update FCM token in background
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  Future<void> _updateFCMToken(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) {
        await ApiService().updateFCMToken(userId, token);
        debugPrint('FCM Token updated for user $userId');
      }
    } catch (e) {
      debugPrint('FCM Token error: $e');
    }
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลและรหัสผ่าน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = AuthService();
      final user = await auth.login(_emailCtrl.text, _passCtrl.text);

      if (user != null) {
        // Save Firebase UID to LocalStorage
        await LocalStorage.saveUserId(user.uid);

        // Update FCM token
        await _updateFCMToken(user.uid);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32.0,
                            vertical: 48.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 40),
                              // Fake Logo
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: GridView.count(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 4,
                                      mainAxisSpacing: 4,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: List.generate(
                                        6,
                                        (index) => Container(
                                          decoration: const BoxDecoration(
                                            color: AppColors.brandGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Treesukon',
                                          style: TextStyle(
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'TMS',
                                          style: TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Transportation Management System',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Login Form
                              const Text(
                                'ชื่อผู้ใช้งาน',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              CustomTextField(
                                controller: _emailCtrl,
                                hintText: 'Username / Email',
                                prefixIcon: const FaIcon(
                                  FontAwesomeIcons.user,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'รหัสผ่าน',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              CustomTextField(
                                controller: _passCtrl,
                                hintText: 'Password',
                                prefixIcon: const FaIcon(
                                  FontAwesomeIcons.lock,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryGreen,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('ลืมรหัสผ่าน?'),
                                ),
                              ),
                              const SizedBox(height: 16),

                              _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryGreen,
                                      ),
                                    )
                                  : PrimaryButton(
                                      text: 'เข้าสู่ระบบ',
                                      onPressed: _login,
                                    ),

                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'ยังไม่มีบัญชี? ',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'สมัครสมาชิก',
                                      style: TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 120,
                      width: double.infinity,
                      color: AppColors.primaryGreen,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
