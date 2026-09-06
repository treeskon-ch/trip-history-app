import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ฟังก์ชันสำหรับ Login ด้วย Email และ Password
  Future<User?> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint("✅ Login สำเร็จ! User ID: ${userCredential.user?.uid}");
      return userCredential.user;
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('ไม่พบอีเมลนี้ในระบบ');
      } else if (e.code == 'wrong-password') {
        throw Exception('รหัสผ่านไม่ถูกต้อง');
      } else if (e.code == 'invalid-email') {
        throw Exception('รูปแบบอีเมลไม่ถูกต้อง');
      } else {
        throw Exception('เข้าสู่ระบบล้มเหลว: ${e.message}');
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดที่ไม่รู้จัก: $e');
    }
  }

  // ฟังก์ชันสำหรับ Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
  
  // เช็กว่าตอนนี้ใคร Login อยู่
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
