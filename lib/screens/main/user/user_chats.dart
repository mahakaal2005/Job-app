import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/models/chat_message.dart';
import 'package:get_work_app/screens/main/user/user_chat_det.dart';
import 'package:get_work_app/services/chat_service.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UserChats extends StatefulWidget {
  const UserChats({super.key});

  @override
  State<UserChats> createState() => _UserChatsState();
}

class _UserChatsState extends State<UserChats> {
  final ChatService _chatService = ChatService();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Notification related
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupMessageListener();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserChats(),
      builder: (context, snapshot) {
        // Check if there are messages
        final hasMessages = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Scaffold(
          backgroundColor: hasMessages ? const Color(0xFFF9F9F9) : const Color(0xFFF9F9F9),
          appBar: hasMessages
              ? AppBar(
                  elevation: 0,
                  title: const Text(
                    'Messages',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.black,
                      fontFamily: 'DM Sans',
                      height: 1.302,
                    ),
                  ),
                  backgroundColor: const Color(0xFFF9F9F9),
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  actions: [
                    // Edit icon
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: IconButton(
                        icon: Image.asset(
                          'assets/images/messages_edit_icon.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.edit, color: Color(0xFFFF9228), size: 24);
                          },
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Create message feature coming soon')),
                          );
                        },
                      ),
                    ),
                    // Three dots menu
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: IconButton(
                        icon: Image.asset(
                          'assets/images/messages_menu_icon.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.more_vert, color: Color(0xFF5B5858), size: 24);
                          },
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                )
              : null, // No AppBar when empty
          body: hasMessages
              ? Column(
                  children: [
                    // Search Bar (only when there are messages) - Figma design
                    Container(
                      color: const Color(0xFFF9F9F9),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF99ABC6).withOpacity(0.18),
                              blurRadius: 62,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search message',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFA0A7B1),
                              fontFamily: 'DM Sans',
                              height: 1.302,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(13),
                              child: Image.asset(
                                'assets/images/messages_search_icon.png',
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.search, color: Color(0xFFA0A7B1), size: 24);
                                },
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 17,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                    ),
                    // Chat List
                    Expanded(child: _buildMessagesList(snapshot)),
                  ],
                )
              : SafeArea(child: _buildContent(snapshot)), // Empty state or error
        );
      },
    );
  }

  // Build messages list or other states
  Widget _buildContent(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMessagesList(snapshot);
  }

  // Build the messages list
  Widget _buildMessagesList(AsyncSnapshot<QuerySnapshot> snapshot) {

    // Filter chats based on search query
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
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF9F9F9),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        itemCount: filteredDocs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 30),
        itemBuilder: (context, index) {
          final doc = filteredDocs[index];
          final chatRoom = ChatRoom.fromFirestore(doc);

          final otherParticipantIndex =
              chatRoom.participants.indexOf(currentUserId!) == 0 ? 1 : 0;
          final otherParticipantId =
              chatRoom.participants[otherParticipantIndex];
          final otherParticipantName =
              chatRoom.participantNames[otherParticipantIndex];

          return FutureBuilder<int>(
            future: _getUnreadCount(chatRoom.id),
            builder: (context, unreadSnapshot) {
              final unreadCount = unreadSnapshot.data ?? 0;
              final hasUnread = unreadCount > 0;

              return InkWell(
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
                child: SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
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
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              otherParticipantName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF150B3D),
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              chatRoom.lastMessage,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                                color: hasUnread
                                    ? const Color(0xFF524B6B)
                                    : const Color(0xFFAAAAAA),
                                fontFamily: 'DM Sans',
                                height: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            _formatTimeAgo(chatRoom.lastMessageTime),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFAAA6B9),
                              fontFamily: 'DM Sans',
                              height: 1.302,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (hasUnread)
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF9228),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Open Sans',
                                    height: 1.362,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    final androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // Setup message listener for real-time notifications
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

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      final senderName = message.data['senderName'] ?? 'Someone';
      final messageText = message.data['message'] ?? 'New message';
      final chatId = message.data['chatId'] ?? '';

      _showLocalNotification(
        ChatMessage(
          id: '',
          senderId: message.data['senderId'] ?? '',
          receiverId: currentUserId!,
          message: messageText,
          timestamp: Timestamp.now(),
        ),
        senderName: senderName,
        chatId: chatId,
      );
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      final chatId = message.data['chatId'];
      final otherUserId = message.data['senderId'];
      final otherUserName = message.data['senderName'];

      if (chatId != null && otherUserId != null && otherUserName != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => UserChatDetailScreen(
                  chatId: chatId,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                ),
          ),
        );
      }
    }
  }

  // Handle local notification tap
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
            builder:
                (context) => UserChatDetailScreen(
                  chatId: chatId,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                ),
          ),
        );
      }
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(
    ChatMessage message, {
    String? senderName,
    String? chatId,
  }) async {
    try {
      // Get sender info if not provided
      String displayName = senderName ?? 'Someone';
      String notificationChatId = chatId ?? '';

      if (senderName == null || chatId == null) {
        // Get chat room info to find sender name and chat ID
        final chatRooms =
            await FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: currentUserId)
                .get();

        for (var doc in chatRooms.docs) {
          final chatRoom = ChatRoom.fromFirestore(doc);
          if (chatRoom.participants.contains(message.senderId)) {
            notificationChatId = chatRoom.id;
            final otherParticipantIndex = chatRoom.participants.indexOf(
              message.senderId,
            );
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

  // Get unread message count for a chat
  Future<int> _getUnreadCount(String chatId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
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

  // Mark messages as read when opening chat
  Future<void> _markMessagesAsRead(String chatId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot =
          await FirebaseFirestore.instance
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

  // Empty state UI matching Figma design
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60), // Top spacing
            // Illustration at (66, 150.18) - 243.91×239.11px
            Image.asset(
              'assets/images/no_message_illustration.png',
              width: 244,
              height: 239,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 244,
                  height: 239,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.mail_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 43), // Space to text group (432 - 389)
            // Text group at (68, 432) - 239×74px
            SizedBox(
              width: 239,
              child: Column(
                children: [
                  // "No Message" title - 16px DM Sans Bold, #150B3D
                  const Text(
                    'No Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF150B3D),
                      fontFamily: 'DM Sans',
                      height: 1.302,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 21), // Space to description (42 - 21)
                  // Description - 12px DM Sans Regular, #524B6B, center-aligned
                  const Text(
                    'You currently have no incoming messages thank you',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF524B6B),
                      fontFamily: 'DM Sans',
                      height: 1.302,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 77), // Space to button (583 - 506)
            // "Create a message" button at (81, 583) - 213×50px
            Container(
              width: 213,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF130160),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF99ABC6).withOpacity(0.18),
                    blurRadius: 62,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Show message - no backend for creating messages from empty state
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Start a conversation by applying to jobs'),
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF130160),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'CREATE A MESSAGE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                    letterSpacing: 0.84, // 6% of 14px
                    height: 1.302,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60), // Bottom spacing
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

