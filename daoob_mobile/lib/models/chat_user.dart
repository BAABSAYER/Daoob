class ChatUser {
  final int id;
  final String name;
  final String email;
  final int unreadCount;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    required this.unreadCount,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? json['fullName'] as String? ?? json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'unreadCount': unreadCount,
    };
  }
}