import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userType; // 'user' or 'employer'

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userType = 'user', // Default to user
  });

  @override
  Widget build(BuildContext context) {
    // Get bottom padding for system navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      height: 72 + bottomPadding, // Add system navigation bar height
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFACC8D3).withOpacity(0.15),
            blurRadius: 159,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding), // Push content up
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_outlined,
            index: 0,
            isActive: currentIndex == 0,
            useSpecialHomeColor: true,
          ),
          _buildImageNavItem(
            imagePath: 'assets/images/connection_icon.png',
            index: 1,
            isActive: currentIndex == 1,
          ),
          _buildCenterButton(),
          _buildNavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble_outline,
            index: 3,
            isActive: currentIndex == 3,
          ),
          // Conditional last item based on user type
          userType == 'employer'
              ? _buildAnalyticsNavItem(
                  index: 4,
                  isActive: currentIndex == 4,
                )
              : _buildBookmarkNavItem(
                  index: 4,
                  isActive: currentIndex == 4,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required bool isActive,
    bool useSpecialHomeColor = false,
  }) {
    // All icons use the same color scheme
    Color iconColor = isActive 
        ? AppColors.lookGigActiveIcon 
        : AppColors.lookGigInactiveIcon;

    // Home icon needs to be slightly larger to match other icons visually
    double iconSize = useSpecialHomeColor ? 28 : 24;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Icon(
          isActive ? activeIcon : icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildImageNavItem({
    required String imagePath,
    required int index,
    required bool isActive,
  }) {
    Color iconColor = isActive 
        ? AppColors.lookGigActiveIcon 
        : AppColors.lookGigInactiveIcon;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            iconColor,
            BlendMode.srcIn,
          ),
          child: Image.asset(
            imagePath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to search icon if image fails to load
              return Icon(
                Icons.search_outlined,
                color: iconColor,
                size: 24,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsNavItem({
    required int index,
    required bool isActive,
  }) {
    Color iconColor = isActive 
        ? AppColors.lookGigActiveIcon 
        : AppColors.lookGigInactiveIcon;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Icon(
          Icons.analytics_outlined,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBookmarkNavItem({
    required int index,
    required bool isActive,
  }) {
    Color iconColor = isActive 
        ? AppColors.lookGigActiveIcon 
        : AppColors.lookGigInactiveIcon;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: CustomPaint(
          size: const Size(24, 24),
          painter: _BookmarkOutlinePainter(color: iconColor),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.lookGigPurple,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF99ABC6).withOpacity(0.18),
              blurRadius: 62,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(10, 10),
            painter: _PlusIconPainter(),
          ),
        ),
      ),
    );
  }
}

// Custom painter for outlined bookmark icon (always outlined, never filled)
class _BookmarkOutlinePainter extends CustomPainter {
  final Color color;

  _BookmarkOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Draw bookmark outline shape
    // Starting from top-left, going clockwise
    final width = size.width;
    final height = size.height;
    
    // Top-left corner
    path.moveTo(width * 0.25, height * 0.1);
    
    // Top edge
    path.lineTo(width * 0.75, height * 0.1);
    
    // Right edge
    path.lineTo(width * 0.75, height * 0.9);
    
    // Bottom point (center)
    path.lineTo(width * 0.5, height * 0.75);
    
    // Left edge back to top
    path.lineTo(width * 0.25, height * 0.9);
    path.lineTo(width * 0.25, height * 0.1);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for the plus icon with 1.5px stroke
class _PlusIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
