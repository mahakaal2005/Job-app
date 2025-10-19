import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/models/chat_message.dart';
import 'package:get_work_app/services/chat_service.dart';
import 'package:get_work_app/services/media_upload_service.dart';
import 'package:get_work_app/widgets/read_receipt_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final currentUserName =
      FirebaseAuth.instance.currentUser?.displayName ?? 'Employer';
  final ImagePicker _imagePicker = ImagePicker();
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mark messages as read when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mark messages as read when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  // Mark messages as read
  Future<void> _markMessagesAsRead() async {
    if (currentUserId != null) {
      await _chatService.markMessagesAsRead(widget.chatId, currentUserId!);
    }
  }

  // Toggle search
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  // Handle attachment
  Future<void> _handleAttachment() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Send Attachment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'DM Sans',
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF130160)),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF130160)),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Color(0xFF130160)),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Pick and send image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Uploading image...'),
                ],
              ),
              duration: Duration(seconds: 30),
            ),
          );
        }

        // Upload to Cloudinary
        final uploadResult = await _mediaUploadService.uploadImage(image.path);
        
        // Send media message with image URL
        await _chatService.sendMediaMessage(
          receiverId: widget.otherUserId,
          message: 'Photo',
          senderName: currentUserName,
          receiverName: widget.otherUserName,
          messageType: 'image',
          fileUrl: uploadResult['url'],
          fileSize: uploadResult['size'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image sent successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Pick and send document
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Uploading document...'),
                ],
              ),
              duration: Duration(seconds: 30),
            ),
          );
        }

        // Upload to Cloudinary
        final uploadResult = await _mediaUploadService.uploadDocument(
          file.path!,
          file.name,
        );
        
        // Send media message with document URL
        await _chatService.sendMediaMessage(
          receiverId: widget.otherUserId,
          message: file.name,
          senderName: currentUserName,
          receiverName: widget.otherUserName,
          messageType: 'document',
          fileUrl: uploadResult['url'],
          fileName: file.name,
          fileSize: file.size,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document sent successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Make phone call
  Future<void> _makeCall() async {
    try {
      // Get user's phone number from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      
      String? phoneNumber;
      if (userDoc.exists) {
        final userData = userDoc.data();
        // Try different possible field names
        // 'phone' is used by students/users
        // 'companyPhone' is used by employers/EMPLOYERs
        phoneNumber = userData?['phone'] as String? ?? 
                     userData?['companyPhone'] as String? ??
                     userData?['phoneNumber'] as String? ?? 
                     userData?['mobile'] as String? ??
                     userData?['contactNumber'] as String?;
      }

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Clean phone number (remove spaces, dashes, etc.)
        phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        
        final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot make call at this time')),
            );
          }
        }
      } else {
        // Show dialog to manually enter phone number
        if (mounted) {
          _showPhoneNumberDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Show dialog to manually enter phone number
  Future<void> _showPhoneNumberDialog() async {
    final TextEditingController phoneController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Phone Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+1234567890',
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, phoneController.text),
            child: const Text('Call'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final phoneNumber = result.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    }
    
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 156,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF99ABC6).withOpacity(0.18),
                blurRadius: 62,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top row with back button and menu
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/images/chat_back_icon.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.arrow_back, size: 24);
                          },
                        ),
                      ),
                      // Menu icon
                      Image.asset(
                        'assets/images/chat_menu_icon.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.more_vert, size: 24);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // User info row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // User avatar
                      Stack(
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.otherUserId)
                                .get(),
                            builder: (context, snapshot) {
                              String? profilePhotoUrl;
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                profilePhotoUrl = userData?['profilePhotoUrl'] as String?;
                              }

                              return CircleAvatar(
                                radius: 25,
                                backgroundColor: const Color(0xFF130160), // Purple
                                backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                                    ? NetworkImage(profilePhotoUrl)
                                    : null,
                                child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
                                    ? Text(
                                        widget.otherUserName.isNotEmpty
                                            ? widget.otherUserName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                          // Online indicator
                          Positioned(
                            left: 0,
                            bottom: 5,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4EC133),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 11),
                      // Name and status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.otherUserName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF101828),
                                fontFamily: 'DM Sans',
                                height: 2,
                              ),
                            ),
                            const Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF524B6B),
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Call icon
                      GestureDetector(
                        onTap: _makeCall,
                        child: Image.asset(
                          'assets/images/chat_call_icon.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.call, color: Color(0xFFFF9228), size: 24);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Search icon
                      GestureDetector(
                        onTap: _toggleSearch,
                        child: Image.asset(
                          'assets/images/chat_search_icon.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.search, color: Color(0xFFFF9228), size: 24);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar overlay
          if (_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAAA6B9),
                    fontFamily: 'DM Sans',
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF130160)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF130160)),
                    onPressed: _toggleSearch,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF130160)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
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
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var messages = snapshot.data!.docs
                    .map((doc) => ChatMessage.fromFirestore(doc))
                    .toList();

                // Filter messages based on search query
                if (_searchQuery.isNotEmpty) {
                  messages = messages
                      .where((msg) => msg.message.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                // Mark messages as read when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesAsRead();
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    
                    // Check if we should show time separator
                    bool showTimeSeparator = false;
                    if (index == messages.length - 1) {
                      // Always show time for the oldest message
                      showTimeSeparator = true;
                    } else {
                      final currentTime = message.timestamp.toDate();
                      final nextTime = messages[index + 1].timestamp.toDate();
                      final timeDifference = nextTime.difference(currentTime).inMinutes;
                      
                      // Show time separator if more than 5 minutes apart
                      if (timeDifference > 5) {
                        showTimeSeparator = true;
                      }
                    }

                    return Column(
                      children: [
                        // Time separator
                        if (showTimeSeparator)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _formatDateSeparator(message.timestamp),
                              style: const TextStyle(
                                color: Color(0xFFAAA6B9),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'DM Sans',
                                height: 1.302,
                              ),
                            ),
                          ),
                        // Message bubble
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar for received messages
            if (!isMe) ...[
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.otherUserId)
                    .get(),
                builder: (context, snapshot) {
                  String? profilePhotoUrl;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    profilePhotoUrl = userData?['profilePhotoUrl'] as String?;
                  }

                  return CircleAvatar(
                    radius: 17.5,
                    backgroundColor: const Color(0xFF130160), // Purple
                    backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                        ? NetworkImage(profilePhotoUrl)
                        : null,
                    child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
                        ? Text(
                            widget.otherUserName.isNotEmpty
                                ? widget.otherUserName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 10),
            ],
            // Message bubble
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF130160) : const Color(0xFFFF9228).withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isMe ? 15 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display image if message type is image
                        if (message.messageType == 'image' && message.fileUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft: Radius.circular(message.message.isEmpty ? (isMe ? 15 : 0) : 0),
                              bottomRight: Radius.circular(message.message.isEmpty ? (isMe ? 0 : 15) : 0),
                            ),
                            child: Image.network(
                              message.fileUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 50),
                                  ),
                                );
                              },
                            ),
                          ),
                        // Display document if message type is document
                        if (message.messageType == 'document' && message.fileUrl != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/pdf_icon.png',
                                  width: 44,
                                  height: 44,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5252A),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.fileName ?? 'Document',
                                        style: TextStyle(
                                          color: isMe ? Colors.white : const Color(0xFF524B6B),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'DM Sans',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (message.fileSize != null)
                                        Text(
                                          '${(message.fileSize! / 1024).toStringAsFixed(1)} KB',
                                          style: TextStyle(
                                            color: isMe ? Colors.white70 : const Color(0xFF898989),
                                            fontSize: 11,
                                            fontFamily: 'DM Sans',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.download,
                                    color: isMe ? Colors.white : const Color(0xFF130160),
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final uri = Uri.parse(message.fileUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        // Display text message
                        if (message.messageType == 'text' || message.message.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              message.message,
                              style: TextStyle(
                                color: isMe ? Colors.white : const Color(0xFF524B6B),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'DM Sans',
                                height: isMe ? 1.302 : 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Timestamp and read receipt
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMe) const SizedBox(width: 0),
                      Text(
                        _formatTime(message.timestamp),
                        style: const TextStyle(
                          color: Color(0xFFAAA6B9),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 5),
                        ReadReceiptIcon(
                          isRead: message.isRead,
                          isDelivered: message.isDelivered,
                        ),
                      ],
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      color: const Color(0xFFF9F9F9),
      child: SafeArea(
        child: Row(
          children: [
            // Input field with attachment icon
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF99ABC6).withOpacity(0.18),
                      blurRadius: 62,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Attachment icon
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 10),
                      child: GestureDetector(
                        onTap: _handleAttachment,
                        child: Image.asset(
                          'assets/images/chat_attachment_icon.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.attach_file, color: Color(0xFF524B6B), size: 24);
                          },
                        ),
                      ),
                    ),
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Write your massage',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFAAA6B9),
                            fontFamily: 'DM Sans',
                            height: 1.302,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 16,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF130160),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF99ABC6).withOpacity(0.18),
                      blurRadius: 62,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/chat_send_icon.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.send, color: Colors.white, size: 20);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _chatService.sendMessage(
      receiverId: widget.otherUserId,
      message: message,
      senderName: currentUserName,
      receiverName: widget.otherUserName,
    );

    _messageController.clear();
    
    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  String _formatDateSeparator(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatMessageTime(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(timestamp)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(timestamp)}';
    } else if (difference.inDays < 7) {
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekdays[date.weekday - 1]} ${_formatTime(timestamp)}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${_formatTime(timestamp)}';
    }
  }
}