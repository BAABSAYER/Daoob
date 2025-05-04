import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/services/message_service.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/screens/chat_screen.dart'; // Add missing import

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
  }

  Future<void> _loadChatUsers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final messageService = Provider.of<MessageService>(context, listen: false);
    
    await messageService.initialize(authService);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final messageService = Provider.of<MessageService>(context);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (messageService.chatUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد محادثات' : 'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic 
                ? 'ابدأ بالتواصل مع مزودي الخدمات'
                : 'Start connecting with service providers',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: messageService.chatUsers.length,
      itemBuilder: (context, index) {
        final chatUser = messageService.chatUsers[index];
        return _buildChatUserTile(context, chatUser, isArabic);
      },
    );
  }
  
  Widget _buildChatUserTile(BuildContext context, ChatUser chatUser, bool isArabic) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(userId: chatUser.id, userName: chatUser.name),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6A3DE8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: chatUser.avatar != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      chatUser.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          chatUser.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A3DE8),
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      chatUser.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A3DE8),
                      ),
                    ),
                  ),
            ),
            const SizedBox(width: 16),
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chatUser.name,
                        style: TextStyle(
                          fontWeight: chatUser.hasUnreadMessages 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      if (chatUser.lastMessageTime != null)
                        Text(
                          _formatTimeAgo(chatUser.lastMessageTime!, isArabic),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chatUser.lastMessage ?? '',
                          style: TextStyle(
                            color: chatUser.hasUnreadMessages
                                ? Colors.black
                                : Colors.grey.shade600,
                            fontWeight: chatUser.hasUnreadMessages
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chatUser.hasUnreadMessages)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6A3DE8),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimeAgo(DateTime dateTime, bool isArabic) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      if (isArabic) {
        return difference.inDays == 1 ? 'أمس' : 'منذ ${difference.inDays} أيام';
      } else {
        return difference.inDays == 1 ? 'Yesterday' : '${difference.inDays} days ago';
      }
    } else if (difference.inHours > 0) {
      if (isArabic) {
        return 'منذ ${difference.inHours} ساعات';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else if (difference.inMinutes > 0) {
      if (isArabic) {
        return 'منذ ${difference.inMinutes} دقائق';
      } else {
        return '${difference.inMinutes} mins ago';
      }
    } else {
      return isArabic ? 'الآن' : 'Just now';
    }
  }
}
