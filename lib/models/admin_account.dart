import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createDefaultAdmin() async {
  try {
    // Kiểm tra nếu email admin đã tồn tại trong Firebase Auth
    final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
      'admin@gmail.com',
    );

    if (methods.isNotEmpty) {
      print('Admin account already exists.');
      return;
    }

    // Nếu chưa tồn tại thì tạo mới
    final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'admin@gmail.com',
      password: 'Admin@2011',
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.user!.uid)
        .set({'email': user.user!.email, 'role': 'admin'});

    print('Admin account created successfully.');
  } catch (error) {
    print('Error creating admin: $error');
  }
}
