class ChatUser {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String userType;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool hasUnreadMessages;
  final int unreadCount;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.userType = 'client',
    this.lastMessage,
    this.lastMessageTime,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? json['fullName'] as String? ?? json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatar: json['avatar'] as String?,
      userType: json['userType'] as String? ?? 'client',
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.tryParse(json['lastMessageTime']) 
          : null,
      hasUnreadMessages: json['hasUnreadMessages'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'userType': userType,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'hasUnreadMessages': hasUnreadMessages,
      'unreadCount': unreadCount,
    };
  }
}