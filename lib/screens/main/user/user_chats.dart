import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/models/chat_message.dart';
import 'package:get_work_app/services/chat_service.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_work_app/screens/main/user/user_chat_detail.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupMessageListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getUserChats(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Something went wrong',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation with employers',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final chatRoom = ChatRoom.fromFirestore(doc);
                  final otherParticipantIndex =
                      chatRoom.participants.indexOf(currentUserId!) == 0 ? 1 : 0;
                  final otherParticipantName =
                      chatRoom.participantNames[otherParticipantIndex];
                  
                  return _searchQuery.isEmpty ||
                      otherParticipantName.toLowerCase().contains(_searchQuery) ||
                      chatRoom.lastMessage.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No results found',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return Container(
                  color: Colors.white,
                  child: ListView.separated(
                    itemCount: filteredDocs.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                      indent: 72,
                    ),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final chatRoom = ChatRoom.fromFirestore(doc);

                      final otherParticipantIndex =
                          chatRoom.participants.indexOf(currentUserId!) == 0 ? 1 : 0;
                      final otherParticipantId =
                          chatRoom.participants[otherParticipantIndex];
                      final otherParticipantName =
                          chatRoom.participantNames[otherParticipantIndex];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            otherParticipantName.isNotEmpty
                                ? otherParticipantName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          otherParticipantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            chatRoom.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTimeAgo(chatRoom.lastMessageTime),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<int>(
                              future: _getUnreadCount(chatRoom.id),
                              builder: (context, snapshot) {
                                final unreadCount = snapshot.data ?? 0;
                                if (unreadCount > 0) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          await _markMessagesAsRead(chatRoom.id);
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserChatDetailScreen(
                                chatId: chatRoom.id,
                                otherUserId: otherParticipantId,
                                otherUserName: otherParticipantName,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _initializeNotifications() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  void _setupMessageListener() {
    if (currentUserId == null) return;

    FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final message = ChatMessage.fromFirestore(change.doc);
          _showLocalNotification(message);
        }
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      final senderName = message.data['senderName'] ?? 'Someone';
      final messageText = message.data['message'] ?? 'New message';
      final chatId = message.data['chatId'] ?? '';
      
      _showLocalNotification(ChatMessage(
        id: '',
        senderId: message.data['senderId'] ?? '',
        receiverId: currentUserId!,
        message: messageText,
        timestamp: Timestamp.now(),
      ), senderName: senderName, chatId: chatId);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      final chatId = message.data['chatId'];
      final otherUserId = message.data['senderId'];
      final otherUserName = message.data['senderName'];
      
      if (chatId != null && otherUserId != null && otherUserName != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatDetailScreen(
              chatId: chatId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            ),
          ),
        );
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final parts = payload.split('|');
      if (parts.length >= 3) {
        final chatId = parts[0];
        final otherUserId = parts[1];
        final otherUserName = parts[2];
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatDetailScreen(
              chatId: chatId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            ),
          ),
        );
      }
    }
  }

  Future<void> _showLocalNotification(ChatMessage message, {String? senderName, String? chatId}) async {
    try {
      String displayName = senderName ?? 'Someone';
      String notificationChatId = chatId ?? '';
      
      if (senderName == null || chatId == null) {
        final chatRooms = await FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .get();
            
        for (var doc in chatRooms.docs) {
          final chatRoom = ChatRoom.fromFirestore(doc);
          if (chatRoom.participants.contains(message.senderId)) {
            notificationChatId = chatRoom.id;
            final otherParticipantIndex = 
                chatRoom.participants.indexOf(message.senderId);
            if (otherParticipantIndex != -1) {
              displayName = chatRoom.participantNames[otherParticipantIndex];
            }
            break;
          }
        }
      }

      const androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        'New message from $displayName',
        message.message,
        notificationDetails,
        payload: '$notificationChatId|${message.senderId}|$displayName',
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<int> _getUnreadCount(String chatId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> _markMessagesAsRead(String chatId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}