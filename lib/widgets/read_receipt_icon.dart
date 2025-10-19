import 'package:flutter/material.dart';

class ReadReceiptIcon extends StatelessWidget {
  final bool isRead;
  final bool isDelivered;

  const ReadReceiptIcon({
    super.key,
    required this.isRead,
    required this.isDelivered,
  });

  @override
  Widget build(BuildContext context) {
    if (isRead) {
      // Blue double check (read)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: 14,
            color: const Color(0xFF05B016), // Green for read
          ),
        ],
      );
    } else if (isDelivered) {
      // Gray double check (delivered)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: 14,
            color: const Color(0xFF898989), // Gray for delivered
          ),
        ],
      );
    } else {
      // Single gray check (sent)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done,
            size: 14,
            color: const Color(0xFF898989), // Gray for sent
          ),
        ],
      );
    }
  }
}
