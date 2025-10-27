class UserModel {
  final int id;
  final String fullName;
  final String userName;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.userName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? 0,
    fullName: json['fullName'] ?? '',
    userName: json['userName'] ?? '',
    role: json['role'] ?? '',
  );
}
