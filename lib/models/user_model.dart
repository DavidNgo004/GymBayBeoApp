class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? name;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      role: data['role'],
      name: data['name'],
      photoUrl: data['photoUrl'],
    );
  }
}
