class TrainerModel {
  final String id;
  final String name;
  final String phone;
  final String imageUrl;

  TrainerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'imageUrl': imageUrl};
  }

  factory TrainerModel.fromMap(String id, Map<String, dynamic> map) {
    return TrainerModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
