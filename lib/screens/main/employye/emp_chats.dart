import 'package:flutter/material.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  Widget _buildChatTile({
    required String name,
    required String lastMessage,
    required String time,
    required String avatar,
    int unreadCount = 0,
    bool isOnline = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              child: Text(
                avatar,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          lastMessage,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildChatTile(
            name: 'TechCorp Solutions',
            lastMessage:
                'Thank you for your application. We will review it shortly.',
            time: '2:15 PM',
            avatar: 'TC',
            unreadCount: 2,
            isOnline: true,
          ),
          _buildChatTile(
            name: 'Creative Studio',
            lastMessage: 'Can you share your portfolio?',
            time: '1:30 PM',
            avatar: 'CS',
            unreadCount: 1,
            isOnline: false,
          ),
          _buildChatTile(
            name: 'Digital Agency',
            lastMessage: 'Your interview is scheduled for tomorrow at 10 AM',
            time: '12:45 PM',
            avatar: 'DA',
            unreadCount: 0,
            isOnline: true,
          ),
          _buildChatTile(
            name: 'StartupHub',
            lastMessage:
                'We liked your profile. Are you available for a quick call?',
            time: '11:20 AM',
            avatar: 'SH',
            unreadCount: 3,
            isOnline: false,
          ),
          _buildChatTile(
            name: 'InnovateLab',
            lastMessage:
                'Congratulations! You have been selected for the next round.',
            time: 'Yesterday',
            avatar: 'IL',
            unreadCount: 0,
            isOnline: false,
          ),
          _buildChatTile(
            name: 'DesignCo',
            lastMessage: 'Please submit your final designs by Friday.',
            time: 'Yesterday',
            avatar: 'DC',
            unreadCount: 0,
            isOnline: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
