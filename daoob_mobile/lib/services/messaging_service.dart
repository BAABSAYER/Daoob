import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final bool read;
  final DateTime createdAt;
  final String? senderName;
  final String? receiverName;
  
  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.read,
    required this.createdAt,
    this.senderName,
    this.receiverName,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      senderName: json['senderName'],
      receiverName: json['receiverName'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'senderName': senderName,
      'receiverName': receiverName,
    };
  }
}

class MessagingService extends ChangeNotifier {
  WebSocketChannel? _channel;
  Database? _database;
  bool _isConnected = false;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  
  List<Message> get messages => _messages;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  MessagingService() {
    _initDatabase();
  }
  
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'messages.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE messages(
          id INTEGER PRIMARY KEY,
          senderId INTEGER,
          receiverId INTEGER,
          content TEXT,
          read INTEGER,
          createdAt TEXT,
          senderName TEXT,
          receiverName TEXT
        )
        ''');
      },
    );
  }
  
  Future<void> connect(AuthService authService) async {
    if (_isConnected) return;
    
    try {
      final userId = authService.user?.id;
      if (userId == null) {
        _error = 'User not authenticated';
        notifyListeners();
        return;
      }
      
      // Create a WebSocket connection
      _channel = IOWebSocketChannel.connect(Uri.parse(ApiConfig.wsUrl));
      
      // Send authentication message to identify the user
      _channel!.sink.add(jsonEncode({
        'type': 'auth',
        'sender': userId,
        'receiver': 0,
        'content': userId.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      // Listen for incoming messages
      _channel!.stream.listen(
        (message) => _handleIncomingMessage(message),
        onError: (error) {
          _error = 'WebSocket error: $error';
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
      );
      
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _error = 'Connection error: $e';
      _isConnected = false;
      notifyListeners();
    }
  }
  
  void _handleIncomingMessage(dynamic data) {
    try {
      final Map<String, dynamic> messageData = jsonDecode(data);
      
      if (messageData['type'] == 'message') {
        final Message newMessage = Message(
          id: messageData['id'] ?? 0,
          senderId: messageData['sender'],
          receiverId: messageData['receiver'],
          content: messageData['content'],
          read: false,
          createdAt: messageData['timestamp'] != null 
              ? DateTime.parse(messageData['timestamp']) 
              : DateTime.now(),
          senderName: messageData['senderName'],
          receiverName: messageData['receiverName'],
        );
        
        // Add to in-memory list
        _messages.add(newMessage);
        
        // Save to local database
        _saveMessageLocally(newMessage);
        
        notifyListeners();
      }
    } catch (e) {
      print('Error processing message: $e');
    }
  }
  
  Future<void> sendMessage(int receiverId, String content, AuthService authService) async {
    final userId = authService.user?.id;
    if (userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }
    
    try {
      if (_isConnected && _channel != null) {
        // Create a temporary message ID (negative to indicate unsent)
        final tempId = -DateTime.now().millisecondsSinceEpoch;
        
        // Add message to local list immediately for UI responsiveness
        final Message pendingMessage = Message(
          id: tempId,
          senderId: userId,
          receiverId: receiverId,
          content: content,
          read: false,
          createdAt: DateTime.now(),
          senderName: authService.user?.name,
        );
        
        _messages.add(pendingMessage);
        notifyListeners();
        
        // Send via WebSocket
        _channel!.sink.add(jsonEncode({
          'type': 'message',
          'sender': userId,
          'receiver': receiverId,
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
        }));
        
        // Message will be saved with proper ID when server acknowledges it
      } else if (authService.isOfflineMode) {
        // Generate a local message ID if offline
        final tempId = DateTime.now().millisecondsSinceEpoch;
        
        final Message offlineMessage = Message(
          id: tempId,
          senderId: userId,
          receiverId: receiverId,
          content: content,
          read: false,
          createdAt: DateTime.now(),
          senderName: authService.user?.name,
        );
        
        _messages.add(offlineMessage);
        _saveMessageLocally(offlineMessage);
        notifyListeners();
      } else {
        _error = 'Not connected to server';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error sending message: $e';
      notifyListeners();
    }
  }
  
  Future<void> loadMessages(int otherUserId, AuthService authService) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final userId = authService.user?.id;
    if (userId == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    try {
      if (!authService.isOfflineMode && authService.token != null) {
        // Try to fetch messages from server first
        final response = await http.get(
          Uri.parse('${ApiConfig.messagesEndpoint}?otherUserId=$otherUserId'),
          headers: ApiConfig.authHeaders(authService.token!),
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          _messages = data.map((item) => Message.fromJson(item)).toList();
          
          // Save to local database
          await _saveMessagesLocally(_messages);
          
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
      
      // Fallback to local database if server request fails or offline
      await _loadMessagesLocally(userId, otherUserId);
    } catch (e) {
      _error = 'Error loading messages: $e';
      // Fallback to local database if network request fails
      await _loadMessagesLocally(userId, otherUserId);
    }
  }
  
  Future<void> _loadMessagesLocally(int userId, int otherUserId) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    try {
      // Get messages where current user is sender or receiver and other user is the counterpart
      final List<Map<String, dynamic>> messages = await _database!.rawQuery(
        '''
        SELECT * FROM messages 
        WHERE (senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)
        ORDER BY createdAt ASC
        ''',
        [userId, otherUserId, otherUserId, userId]
      );
      
      if (messages.isNotEmpty) {
        _messages = messages.map((item) => Message.fromJson(item)).toList();
      } else {
        _messages = [];
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Database error: $e';
      _isLoading = false;
      _messages = [];
      notifyListeners();
    }
  }
  
  Future<void> _saveMessageLocally(Message message) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    await _database!.insert(
      'messages',
      message.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<void> _saveMessagesLocally(List<Message> messages) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    // Use a transaction for better performance when saving multiple messages
    await _database!.transaction((txn) async {
      for (var message in messages) {
        await txn.insert(
          'messages',
          message.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
  
  Future<void> markAsRead(int messageId) async {
    // Find the message in memory
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      // Create a new message with read set to true
      final updatedMessage = Message(
        id: _messages[index].id,
        senderId: _messages[index].senderId,
        receiverId: _messages[index].receiverId,
        content: _messages[index].content,
        read: true,
        createdAt: _messages[index].createdAt,
        senderName: _messages[index].senderName,
        receiverName: _messages[index].receiverName,
      );
      
      // Update in memory
      _messages[index] = updatedMessage;
      
      // Update in database
      if (_database != null) {
        await _database!.update(
          'messages',
          {'read': 1},
          where: 'id = ?',
          whereArgs: [messageId],
        );
      }
      
      notifyListeners();
    }
  }
  
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}