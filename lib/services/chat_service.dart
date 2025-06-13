import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestore.collection('users_specific').doc(userId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Get employer data
  Future<Map<String, dynamic>?> getEmployerData(String employerId) async {
    final doc = await _firestore.collection('employees').doc(employerId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}
