import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final bool isRead;
  final bool isDelivered; // New: for WhatsApp-style delivery status
  final String? messageType; // 'text', 'image', 'document'
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.messageType,
    this.fileUrl,
    this.fileName,
    this.fileSize,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
      isDelivered: data['isDelivered'] ?? false,
      messageType: data['messageType'] ?? 'text',
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'messageType': messageType ?? 'text',
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
    };
  }

  // Get read receipt icon based on status
  String getReadReceiptStatus() {
    if (isRead) return 'read'; // Blue double check
    if (isDelivered) return 'delivered'; // Gray double check
    return 'sent'; // Single gray check
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final List<String> participantNames;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final Timestamp updatedAt;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.updatedAt,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: List<String>.from(data['participantNames'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'updatedAt': updatedAt,
    };
  }
}
