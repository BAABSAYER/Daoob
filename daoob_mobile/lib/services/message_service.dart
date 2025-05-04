import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String senderName;
  final String receiverName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? senderAvatar;
  final String? receiverAvatar;
  
  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.senderAvatar,
    this.receiverAvatar,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      senderName: json['senderName'] ?? 'Unknown',
      receiverName: json['receiverName'] ?? 'Unknown',
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      senderAvatar: json['senderAvatar'],
      receiverAvatar: json['receiverAvatar'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'senderAvatar': senderAvatar,
      'receiverAvatar': receiverAvatar,
    };
  }
}

class ChatUser {
  final int id;
  final String name;
  final String? avatar;
  final String userType;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool hasUnreadMessages;
  
  ChatUser({
    required this.id,
    required this.name,
    this.avatar,
    required this.userType,
    this.lastMessage,
    this.lastMessageTime,
    this.hasUnreadMessages = false,
  });
}

class MessageService extends ChangeNotifier {
  List<Message> _messages = [];
  List<ChatUser> _chatUsers = [];
  bool _isLoading = false;
  String? _error;
  Database? _database;
  int? _currentUserId;
  
  List<Message> get messages => _messages;
  List<ChatUser> get chatUsers => _chatUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  MessageService() {
    _initDatabase();
  }
  
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'messages.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create messages table
        await db.execute('''
        CREATE TABLE messages(
          id INTEGER PRIMARY KEY,
          senderId INTEGER,
          receiverId INTEGER,
          senderName TEXT,
          receiverName TEXT,
          content TEXT,
          timestamp TEXT,
          isRead INTEGER,
          senderAvatar TEXT,
          receiverAvatar TEXT
        )
        ''');
        
        // Create chat users table
        await db.execute('''
        CREATE TABLE chat_users(
          id INTEGER PRIMARY KEY,
          name TEXT,
          avatar TEXT,
          userType TEXT,
          lastMessage TEXT,
          lastMessageTime TEXT,
          hasUnreadMessages INTEGER
        )
        ''');
      },
    );
  }
  
  Future<void> initialize(AuthService authService) async {
    _isLoading = true;
    notifyListeners();
    
    // Always set a default user ID for offline mode testing
    _currentUserId = authService.user?.id ?? 1;
    
    // Load chat users
    await loadChatUsers();
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> loadChatUsers() async {
    if (_database == null) {
      await _initDatabase();
    }
    
    try {
      // Check if we have any chat users stored
      final List<Map<String, dynamic>> maps = await _database!.query('chat_users');
      
      if (maps.isNotEmpty) {
        _chatUsers = maps.map((item) {
          return ChatUser(
            id: item['id'],
            name: item['name'],
            avatar: item['avatar'],
            userType: item['userType'],
            lastMessage: item['lastMessage'],
            lastMessageTime: item['lastMessageTime'] != null 
              ? DateTime.parse(item['lastMessageTime']) 
              : null,
            hasUnreadMessages: item['hasUnreadMessages'] == 1,
          );
        }).toList();
      } else {
        // No chat users found, generate sample data
        _chatUsers = _generateSampleChatUsers();
        await _saveChatUsersLocally(_chatUsers);
      }
    } catch (e) {
      _error = 'Error loading chat users: ${e.toString()}';
      // Fallback to sample data
      _chatUsers = _generateSampleChatUsers();
    }
  }
  
  Future<void> loadMessages(int otherUserId) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    if (_currentUserId == null) {
      _currentUserId = 1; // Default user ID for testing
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Load messages between current user and the selected user
      final List<Map<String, dynamic>> maps = await _database!.rawQuery(
        '''
        SELECT * FROM messages 
        WHERE (senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)
        ORDER BY timestamp ASC
        ''',
        [_currentUserId, otherUserId, otherUserId, _currentUserId]
      );
      
      if (maps.isNotEmpty) {
        _messages = maps.map((item) {
          return Message(
            id: item['id'],
            senderId: item['senderId'],
            receiverId: item['receiverId'],
            senderName: item['senderName'],
            receiverName: item['receiverName'],
            content: item['content'],
            timestamp: DateTime.parse(item['timestamp']),
            isRead: item['isRead'] == 1,
            senderAvatar: item['senderAvatar'],
            receiverAvatar: item['receiverAvatar'],
          );
        }).toList();
      } else {
        // If no saved messages, generate sample conversation
        _messages = _generateSampleMessages(otherUserId);
        await _saveMessagesLocally(_messages);
      }
      
      // Mark messages as read
      await _markMessagesAsRead(otherUserId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Database error: ${e.toString()}';
      _isLoading = false;
      _messages = _generateSampleMessages(otherUserId); // Fallback to sample data
      notifyListeners();
    }
  }
  
  Future<void> _markMessagesAsRead(int otherUserId) async {
    if (_database == null || _currentUserId == null) return;
    
    // Mark messages as read in the database
    await _database!.update(
      'messages',
      {'isRead': 1},
      where: 'senderId = ? AND receiverId = ? AND isRead = 0',
      whereArgs: [otherUserId, _currentUserId],
    );
    
    // Update hasUnreadMessages flag for this chat user
    await _database!.update(
      'chat_users',
      {'hasUnreadMessages': 0},
      where: 'id = ?',
      whereArgs: [otherUserId],
    );
    
    // Update the chat users list
    final index = _chatUsers.indexWhere((user) => user.id == otherUserId);
    if (index != -1) {
      final updatedUser = ChatUser(
        id: _chatUsers[index].id,
        name: _chatUsers[index].name,
        avatar: _chatUsers[index].avatar,
        userType: _chatUsers[index].userType,
        lastMessage: _chatUsers[index].lastMessage,
        lastMessageTime: _chatUsers[index].lastMessageTime,
        hasUnreadMessages: false,
      );
      
      _chatUsers[index] = updatedUser;
    }
    
    // Update messages in memory
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].senderId == otherUserId && _messages[i].receiverId == _currentUserId && !_messages[i].isRead) {
        _messages[i] = Message(
          id: _messages[i].id,
          senderId: _messages[i].senderId,
          receiverId: _messages[i].receiverId,
          senderName: _messages[i].senderName,
          receiverName: _messages[i].receiverName,
          content: _messages[i].content,
          timestamp: _messages[i].timestamp,
          isRead: true,
          senderAvatar: _messages[i].senderAvatar,
          receiverAvatar: _messages[i].receiverAvatar,
        );
      }
    }
  }
  
  Future<bool> sendMessage(int receiverId, String content, String receiverName) async {
    if (_database == null || _currentUserId == null) {
      _error = 'Not initialized';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Generate new message ID (highest ID + 1)
      int newId = 1;
      if (_messages.isNotEmpty) {
        newId = _messages.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
      }
      
      // Get current user's name
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      String senderName = 'You';
      
      if (userData != null) {
        final user = json.decode(userData);
        senderName = user['name'] ?? 'You';
      }
      
      final newMessage = Message(
        id: newId,
        senderId: _currentUserId!,
        receiverId: receiverId,
        senderName: senderName,
        receiverName: receiverName,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        senderAvatar: null,
        receiverAvatar: null,
      );
      
      // Add to in-memory list
      _messages.add(newMessage);
      
      // Save to local database
      await _saveMessageLocally(newMessage);
      
      // Update chat users with last message
      await _updateChatUserWithLastMessage(receiverId, content, newMessage.timestamp);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error sending message: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> _updateChatUserWithLastMessage(int userId, String lastMessage, DateTime timestamp) async {
    if (_database == null) return;
    
    // Check if chat user exists
    final List<Map<String, dynamic>> users = await _database!.query(
      'chat_users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (users.isNotEmpty) {
      // Update existing chat user
      await _database!.update(
        'chat_users',
        {
          'lastMessage': lastMessage,
          'lastMessageTime': timestamp.toIso8601String(),
          'hasUnreadMessages': 1,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      // Update in-memory list
      final index = _chatUsers.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _chatUsers[index] = ChatUser(
          id: _chatUsers[index].id,
          name: _chatUsers[index].name,
          avatar: _chatUsers[index].avatar,
          userType: _chatUsers[index].userType,
          lastMessage: lastMessage,
          lastMessageTime: timestamp,
          hasUnreadMessages: true,
        );
      }
    } else {
      // This shouldn't happen in normal usage as chat users should be loaded
      // But we'll handle it just in case
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      String currentUserType = 'client';
      
      if (userData != null) {
        final user = json.decode(userData);
        currentUserType = user['userType'] ?? 'client';
      }
      
      // Create new chat user
      final newChatUser = ChatUser(
        id: userId,
        name: 'User $userId',
        userType: currentUserType == 'client' ? 'vendor' : 'client',
        lastMessage: lastMessage,
        lastMessageTime: timestamp,
        hasUnreadMessages: true,
      );
      
      await _database!.insert(
        'chat_users',
        {
          'id': newChatUser.id,
          'name': newChatUser.name,
          'avatar': newChatUser.avatar,
          'userType': newChatUser.userType,
          'lastMessage': newChatUser.lastMessage,
          'lastMessageTime': newChatUser.lastMessageTime?.toIso8601String(),
          'hasUnreadMessages': newChatUser.hasUnreadMessages ? 1 : 0,
        },
      );
      
      // Add to in-memory list
      _chatUsers.add(newChatUser);
    }
  }
  
  Future<void> _saveMessageLocally(Message message) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    await _database!.insert(
      'messages',
      {
        'id': message.id,
        'senderId': message.senderId,
        'receiverId': message.receiverId,
        'senderName': message.senderName,
        'receiverName': message.receiverName,
        'content': message.content,
        'timestamp': message.timestamp.toIso8601String(),
        'isRead': message.isRead ? 1 : 0,
        'senderAvatar': message.senderAvatar,
        'receiverAvatar': message.receiverAvatar,
      },
    );
  }
  
  Future<void> _saveMessagesLocally(List<Message> messages) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    // Insert all messages
    for (var message in messages) {
      await _saveMessageLocally(message);
    }
  }
  
  Future<void> _saveChatUsersLocally(List<ChatUser> users) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    // Clear existing chat users
    await _database!.delete('chat_users');
    
    // Insert new chat users
    for (var user in users) {
      await _database!.insert(
        'chat_users',
        {
          'id': user.id,
          'name': user.name,
          'avatar': user.avatar,
          'userType': user.userType,
          'lastMessage': user.lastMessage,
          'lastMessageTime': user.lastMessageTime?.toIso8601String(),
          'hasUnreadMessages': user.hasUnreadMessages ? 1 : 0,
        },
      );
    }
  }
  
  List<ChatUser> _generateSampleChatUsers() {
    final currentUserType = _getCurrentUserType();
    final otherUserType = currentUserType == 'client' ? 'vendor' : 'client';
    
    final List<String> vendorNames = [
      'Elegant Events',
      'Delicious Catering',
      'Photography Masters',
      'Dream Decorations',
      'Sound Solutions'
    ];
    
    final List<String> clientNames = [
      'John Smith',
      'Sarah Johnson',
      'Mohammed Ali',
      'Linda Chen',
      'David Kim'
    ];
    
    final List<String> messages = [
      'Hello, I would like to inquire about your services.',
      'Can you provide more details about your packages?',
      'Is the date still available?',
      'Thank you for the information.',
      'What time can we meet to discuss further?'
    ];
    
    final namesList = currentUserType == 'client' ? vendorNames : clientNames;
    
    return List.generate(5, (index) {
      final chatUserId = 101 + index;
      final name = namesList[index];
      final hasUnread = index % 3 == 0; // Every third user has unread messages
      
      return ChatUser(
        id: chatUserId,
        name: name,
        userType: otherUserType,
        lastMessage: messages[index],
        lastMessageTime: DateTime.now().subtract(Duration(hours: index * 2 + 1)),
        hasUnreadMessages: hasUnread,
      );
    });
  }
  
  List<Message> _generateSampleMessages(int otherUserId) {
    if (_currentUserId == null) {
      _currentUserId = 1; // Default for testing
    }
    
    final currentUserType = _getCurrentUserType();
    final otherUserName = _getChatUserName(otherUserId);
    
    // Create a conversation with 10 messages alternating between users
    final List<Message> sampleMessages = [];
    
    for (int i = 0; i < 10; i++) {
      final bool isFromCurrentUser = i % 2 == 0;
      final senderId = isFromCurrentUser ? _currentUserId! : otherUserId;
      final receiverId = isFromCurrentUser ? otherUserId : _currentUserId!;
      final senderName = isFromCurrentUser ? 'You' : otherUserName;
      final receiverName = isFromCurrentUser ? otherUserName : 'You';
      
      final List<String> clientMessages = [
        'Hello, I\'m interested in your services for my event.',
        'Can you tell me more about your pricing?',
        'Is June 15th available?',
        'That sounds perfect!',
        'What time can we meet to discuss the details?'
      ];
      
      final List<String> vendorMessages = [
        'Hello! Thank you for your interest in our services.',
        'Our packages start from \$500 for basic and go up to \$2000 for premium.',
        'Yes, June 15th is currently available.',
        'Great! We\'d be happy to work with you.',
        'We can meet anytime between 9am and 5pm, what works for you?'
      ];
      
      final List<String> messagePool = currentUserType == 'client' 
        ? (isFromCurrentUser ? clientMessages : vendorMessages)
        : (isFromCurrentUser ? vendorMessages : clientMessages);
      
      final messageIndex = i % messagePool.length;
      
      sampleMessages.add(
        Message(
          id: i + 1,
          senderId: senderId,
          receiverId: receiverId,
          senderName: senderName,
          receiverName: receiverName,
          content: messagePool[messageIndex],
          timestamp: DateTime.now().subtract(Duration(minutes: (10 - i) * 15)),
          isRead: isFromCurrentUser || i < 8, // Only the last 2 messages might be unread if from other user
        ),
      );
    }
    
    return sampleMessages;
  }
  
  String _getCurrentUserType() {
    // Try to get the user type from shared preferences
    try {
      final userData = SharedPreferences.getInstance().then((prefs) {
        return prefs.getString('user');
      });
      
      if (userData != null) {
        final user = json.decode(userData.toString());
        return user['userType'] ?? 'client';
      }
    } catch (e) {
      // Ignore error and return default
    }
    
    return 'client'; // Default user type
  }
  
  String _getChatUserName(int userId) {
    final index = _chatUsers.indexWhere((user) => user.id == userId);
    if (index != -1) {
      return _chatUsers[index].name;
    }
    
    // If not found, generate a vendor name based on the ID
    final vendorTypes = ['Events', 'Catering', 'Photography', 'Decorations', 'Sound'];
    final vendorIndex = userId % vendorTypes.length;
    return 'Vendor ${vendorTypes[vendorIndex]}';
  }
}
