import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/auth/login_page.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ===== ĐĂNG XUẤT =====
  static Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      // Kiểm tra widget còn mounted trước khi điều hướng
      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đăng xuất thành công!")));
    } catch (e) {
      debugPrint('Lỗi đăng xuất: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng xuất thất bại, thử lại sau!')),
        );
      }
    }
  }

  /// ===== ĐĂNG KÝ =====
  Future<User?> signUpWithEmail({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(userCred.user!.uid).set({
      'uid': userCred.user!.uid,
      'name': name,
      'phone': phone,
      'email': userCred.user!.email,
      'role': 'Customer',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userCred.user;
  }

  /// ===== ĐĂNG NHẬP =====
  Future<User?> signInWithEmail(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCred.user;
  }

  /// ===== GOOGLE SIGN-IN =====
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // Người dùng bấm “Quay lại” hoặc hủy đăng nhập Google
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // Lưu thông tin user vào Firestore nếu chưa có
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': userCred.user!.uid,
          'name': googleUser.displayName,
          'email': googleUser.email,
          'role': 'Customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCred;
    } catch (e) {
      debugPrint("Google Sign-In error: $e");
      return null; // tránh crash app
    }
  }

  /// ===== SIGN OUT (không cần context) =====
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
