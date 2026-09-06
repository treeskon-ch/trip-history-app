# คู่มือการใช้งาน Firebase Auth ใน Flutter

การใช้งาน Firebase Auth ในฝั่ง Flutter (Frontend) เป็นวิธีที่ถูกต้องและปลอดภัยที่สุดตามมาตรฐานของ Firebase ครับ เมื่อผู้ใช้ Login สำเร็จผ่านมือถือ คุณจะได้ค่า `uid` มาเพื่อใช้ในการส่งข้อมูลหา Backend (Go API) ของเราครับ

---

## 1. ติดตั้ง Packages ที่จำเป็น
เข้าไปที่โฟลเดอร์โปรเจกต์ Flutter ของคุณ (เช่น `trip_history_app`) แล้วรันคำสั่ง:
```bash
flutter pub add firebase_core
flutter pub add firebase_auth
```

## 2. ตั้งค่าเริ่มต้นใน `main.dart`
ก่อนจะเรียกใช้งาน Firebase ได้ ต้องทำการ Initialized ก่อนครับ
```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ไฟล์นี้ได้มาจากการตั้งค่า flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // เชื่อมต่อแอปกับ Firebase Project ของคุณ
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

## 3. การเขียนฟังก์ชัน Login
คุณสามารถสร้างไฟล์หรือฟังก์ชันสำหรับจัดการเรื่อง Login ได้ง่ายๆ ดังนี้ครับ:

```dart
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
      
      print("✅ Login สำเร็จ! User ID: ${userCredential.user?.uid}");
      return userCredential.user;
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('❌ ไม่พบอีเมลนี้ในระบบ');
      } else if (e.code == 'wrong-password') {
        print('❌ รหัสผ่านไม่ถูกต้อง');
      }
      return null;
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
```

## 4. นำไปประยุกต์ใช้กับ Backend (Go API) ของเรา
เมื่อผู้ใช้ Login ผ่าน Flutter สำเร็จแล้ว คุณสามารถดึง `uid` ไปใช้ต่อกับ API ของเราได้เลยครับ 

**ตัวอย่างเมื่อเริ่มทริป:**
```dart
void startMyTrip() async {
  // 1. ดึงข้อมูลคนที่ล็อกอินอยู่ตอนนี้
  final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {
    String userId = user.uid; // นี่คือ User ID ที่ได้จาก Firebase
    
    // 2. นำ userId ไปยิง API /api/trips/start ของ Go Backend
    // (ดูตัวอย่างการยิง API ได้จากไฟล์ integration_guide.md ก่อนหน้านี้)
    await apiService.startTrip(userId);
    
  } else {
    print("กรุณา Login ก่อนเริ่มทริป");
  }
}
```

---

> [!TIP]
> **ระบบลงทะเบียน (Register)** 
> หากคุณมีหน้าสมัครสมาชิกบนแอปมือถือด้วย คุณสามารถใช้ API `POST /api/users/register` ของฝั่ง Go ได้เหมือนเดิมครับ (เพราะ API เราช่วยบันทึกข้อมูลเข้า Firestore ให้ด้วย) แล้วให้ผู้ใช้มา Login ผ่าน `FirebaseAuth.instance.signInWithEmailAndPassword` ตามตัวอย่างนี้เพื่อเข้าสู่ระบบครับ
