import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/services/message_service.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/screens/chat_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
  }

  Future<void> _loadChatUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messageService = Provider.of<MessageService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await messageService.loadChatUsers(authService);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageService = Provider.of<MessageService>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.getTranslations();
    final chatUsers = messageService.chatUsers;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(translations['messages'] ?? 'Messages'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChatUsers,
            tooltip: translations['refresh'] ?? 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChatUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            translations['errorLoadingChats'] ?? 'Error loading chats',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadChatUsers,
                            icon: const Icon(Icons.refresh),
                            label: Text(translations['tryAgain'] ?? 'Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : chatUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              translations['noChats'] ?? 'No conversations yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              translations['noChatsDescription'] ?? 
                              'When you have conversations with event organizers, they will appear here',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: chatUsers.length,
                        itemBuilder: (context, index) {
                          final chatUser = chatUsers[index];
                          final lastMessageTime = chatUser.lastMessageTime != null
                              ? _formatMessageTime(chatUser.lastMessageTime!)
                              : '';
                              
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  chatUser.name.isNotEmpty
                                      ? chatUser.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                chatUser.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: chatUser.lastMessage != null
                                  ? Text(
                                      chatUser.lastMessage!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    lastMessageTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (chatUser.unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        chatUser.unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      recipientId: chatUser.id,
                                      recipientName: chatUser.name,
                                    ),
                                  ),
                                ).then((_) => _loadChatUsers());
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
  
  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return DateFormat.jm().format(dateTime); // Today, show time
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat.EEEE().format(dateTime); // Weekday name
    } else {
      return DateFormat.yMd().format(dateTime); // Full date for older messages
    }
  }
}