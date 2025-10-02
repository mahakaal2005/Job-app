import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/glassmorphism_utils.dart';

class Floating3DHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool hasBackButton;
  final VoidCallback? onBackPressed;

  const Floating3DHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.margin = const EdgeInsets.all(16.0),
    this.borderRadius = 28.0,
    this.hasBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismUtils.floating3DHeader(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

/// Portfolio-style welcome header (like in reference image)
class PortfolioWelcomeHeader extends StatelessWidget {
  final String welcomeText;
  final String userName;
  final String balanceAmount;
  final String balanceLabel;
  final Widget? profileImage;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;

  const PortfolioWelcomeHeader({
    super.key,
    required this.welcomeText,
    required this.userName,
    required this.balanceAmount,
    this.balanceLabel = "Portfolio Balance",
    this.profileImage,
    this.onProfileTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Floating3DHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with profile and notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: GlassmorphismUtils.floating3DContainer(
                  padding: const EdgeInsets.all(2),
                  borderRadius: 25,
                  elevation: 6,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryAccent,
                    child: profileImage ?? 
                      Icon(
                        Icons.person,
                        color: AppColors.textOnAccent,
                        size: 24,
                      ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onNotificationTap,
                child: GlassmorphismUtils.floating3DContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 20,
                  elevation: 6,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Welcome text
          Text(
            welcomeText,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // User name
          Text(
            userName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Balance section
          Row(
            children: [
              GlassmorphismUtils.floating3DContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: 12,
                elevation: 4,
                backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.1),
                borderColor: AppColors.primaryAccent.withValues(alpha: 0.3),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balanceLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    balanceAmount,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Job search header with 3D floating search bar
class JobSearchHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController? searchController;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final Widget? profileImage;

  const JobSearchHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.searchController,
    this.onSearchTap,
    this.onFilterTap,
    this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Floating3DHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GlassmorphismUtils.floating3DContainer(
                padding: const EdgeInsets.all(2),
                borderRadius: 25,
                elevation: 6,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryAccent,
                  child: profileImage ?? 
                    Icon(
                      Icons.person,
                      color: AppColors.textOnAccent,
                      size: 24,
                    ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Search bar
          GlassmorphismUtils.floating3DContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            borderRadius: 25,
            elevation: 8,
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onTap: onSearchTap,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Search jobs...",
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onFilterTap,
                  child: GlassmorphismUtils.floating3DContainer(
                    padding: const EdgeInsets.all(8),
                    borderRadius: 15,
                    elevation: 4,
                    child: Icon(
                      Icons.tune,
                      color: AppColors.primaryAccent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}