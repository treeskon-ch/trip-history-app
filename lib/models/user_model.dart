class UserModel {
  final String? userId;
  final String? email;
  final String? name;
  final String? role;

  UserModel({this.userId, this.email, this.name, this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId']?.toString(),
      email: json['email']?.toString(),
      name: json['name']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
    };
  }
}
