import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Get chat ID between two users
  String getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String message,
    required String senderName,
    required String receiverName,
  }) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = getChatId(currentUserId, receiverId);
    final Timestamp timestamp = Timestamp.now();

    // Create a new message
    final newMessage = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': false, // New messages are unread by default
      'isDelivered': false, // Will be marked as delivered when receiver opens chat list
    };

    // Add message to the chat collection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(newMessage);

    // Update the chat metadata
    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'participants': [currentUserId, receiverId],
      'participantNames': [senderName, receiverName],
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    // Send push notification to receiver
    await _sendPushNotification(
      receiverId: receiverId,
      senderName: senderName,
      message: message,
      chatId: chatId,
    );
  }

  // Send a media message (image or document)
  Future<void> sendMediaMessage({
    required String receiverId,
    required String message,
    required String senderName,
    required String receiverName,
    required String messageType, // 'image' or 'document'
    required String fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    print('💬 [CHAT] Sending $messageType message: ${fileName ?? message}');
    
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = getChatId(currentUserId, receiverId);
    final Timestamp timestamp = Timestamp.now();

    // Create a new media message
    final newMessage = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': false,
      'messageType': messageType,
      'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
    };

    // Add message to the chat collection
    final docRef = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(newMessage);
    
    print('✅ [CHAT] Message saved: ${docRef.id}');

    // Update the chat metadata with appropriate preview
    String lastMessagePreview = message;
    if (messageType == 'image') {
      lastMessagePreview = '📷 Photo';
    } else if (messageType == 'document') {
      lastMessagePreview = '📄 ${fileName ?? 'Document'}';
    }

    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': lastMessagePreview,
      'lastMessageTime': timestamp,
      'participants': [currentUserId, receiverId],
      'participantNames': [senderName, receiverName],
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    // Send push notification
    await _sendPushNotification(
      receiverId: receiverId,
      senderName: senderName,
      message: lastMessagePreview,
      chatId: chatId,
    );
  }

  // Send push notification
  Future<void> _sendPushNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore
          .collection('users') // or your user collection name
          .doc(receiverId)
          .get();

      if (receiverDoc.exists) {
        final receiverData = receiverDoc.data() as Map<String, dynamic>;
        final fcmToken = receiverData['fcmToken'] as String?;

        if (fcmToken != null) {
          // Send notification via your backend or Firebase Functions
          // This is just a placeholder - you'll need to implement the actual notification sending
          await _firestore.collection('notifications').add({
            'to': fcmToken,
            'notification': {
              'title': 'New message from $senderName',
              'body': message,
            },
            'data': {
              'type': 'chat_message',
              'chatId': chatId,
              'senderId': _auth.currentUser!.uid,
              'senderName': senderName,
              'message': message,
            },
            'timestamp': Timestamp.now(),
          });
        }
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Get messages for a chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get all chats for current user
  Stream<QuerySnapshot> getUserChats() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Mark messages as delivered (when user opens chat list)
  Future<void> markMessagesAsDelivered(String chatId, String currentUserId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isDelivered', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isDelivered': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as delivered: $e');
    }
  }

  // Mark messages as read (when user opens specific chat)
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'isDelivered': true, // Also mark as delivered
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count for a specific chat
  Future<int> getUnreadMessageCount(String chatId, String currentUserId) async {
    try {
      final snapshot = await _firestore
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

  // Get total unread message count for all chats
  Stream<int> getTotalUnreadCount() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ No user logged in for unread count');
        return Stream.value(0);
      }
      
      final String currentUserId = currentUser.uid;
      return _firestore
          .collectionGroup('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
            debugPrint('📬 Unread messages count: ${snapshot.docs.length}');
            return snapshot.docs.length;
          })
          .handleError((error) {
            debugPrint('❌ Error in unread count stream: $error');
            return 0;
          });
    } catch (e) {
      debugPrint('❌ Error creating unread count stream: $e');
      return Stream.value(0);
    }
  }

  // Update FCM token for push notifications
  Future<void> updateFCMToken() async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final String? token = await _messaging.getToken();
      
      if (token != null) {
        await _firestore
            .collection('users') // or your user collection name
            .doc(currentUserId)
            .set({
          'fcmToken': token,
          'lastSeen': Timestamp.now(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Get employer data
  Future<Map<String, dynamic>?> getEmployerData(String employerId) async {
    final doc = await _firestore.collection('employers').doc(employerId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}