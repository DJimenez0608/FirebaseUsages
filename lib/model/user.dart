class User {
  final String id;
  final String name;
  final String lastName;
  final String email;
  final String idNumber;
  final String? imageUrl;

  User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.idNumber,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'email': email,
      'idNumber': idNumber,
      'imageUrl': imageUrl,
    };
  }

  factory User.fromMap(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      name: data['name'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      idNumber: data['idNumber'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
    );
  }
}
