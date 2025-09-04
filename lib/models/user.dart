class AppUser {
  final int? id;
  final String userId;
  final String userPw;
  final String createdAt;
  final String? userName;
  final String? profileImg;

  AppUser({
    this.id,
    required this.userId,
    required this.userPw,
    required this.createdAt,
    this.userName,
    this.profileImg,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userPw': userPw,
    'createdAt': createdAt,
    'userName': userName,
    'profileImg': profileImg,
  };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id: m['id'] as int?,
    userId: m['userId'] as String,
    userPw: m['userPw'] as String,
    createdAt: m['createdAt'] as String,
    userName: m['userName'] as String?,
    profileImg: m['profileImg'] as String?,
  );
}
