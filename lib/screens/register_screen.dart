import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')));
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final res = await api.registerUser(
        _emailCtrl.text,
        _passCtrl.text,
        _nameCtrl.text,
        'driver',
      );

      final userId = res['userId'];
      if (userId != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ')));
        
        // กลับไปหน้า Login (pop ออกจากหน้า Register)
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderLight, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderLight, width: 2),
                    ),
                    child: const Center(
                      child: FaIcon(FontAwesomeIcons.camera, color: AppColors.textLight, size: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('อัพโหลดรูปโปรไฟล์', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildFieldLabel('ชื่อ - นามสกุล'),
            CustomTextField(controller: _nameCtrl, hintText: 'John Doe'),
            const SizedBox(height: 16),
            
            _buildFieldLabel('เบอร์โทรศัพท์'),
            CustomTextField(controller: _phoneCtrl, hintText: '08x-xxx-xxxx', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            
            _buildFieldLabel('อีเมล'),
            CustomTextField(controller: _emailCtrl, hintText: 'example@email.com', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            
            _buildFieldLabel('รหัสผ่าน'),
            CustomTextField(controller: _passCtrl, hintText: '••••••••', obscureText: true),
            const SizedBox(height: 16),
            
            _buildFieldLabel('ยืนยันรหัสผ่าน'),
            CustomTextField(controller: _confirmPassCtrl, hintText: '••••••••', obscureText: true),
            const SizedBox(height: 32),
            
            _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : PrimaryButton(
                    text: 'ยืนยันการสมัคร',
                    onPressed: _register,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
      ),
    );
  }
}
