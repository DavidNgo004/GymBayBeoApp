import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createDefaultAdmin() async {
  try {
    // Kiểm tra nếu tài khoản admin đã tồn tại
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'admin@gmail.com',
      password: 'Admin@2011',
    );
    print('Admin account already exists.');
  } catch (e) {
    try {
      // Tạo tài khoản admin mới
      final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'admin@gmail.com',
        password: 'Admin@2011',
      );

      // Gán quyền admin trong Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.user!.uid)
          .set({'email': user.user!.email, 'role': 'admin'});

      print('Admin account created.');
    } catch (error) {
      print('Error creating admin: $error');
    }
  }
}
