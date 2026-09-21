import 'package:flutter/material.dart';

class ActivityItem {
  const ActivityItem({
    required this.authorName,
    required this.initials,
    required this.avatarColors,
    required this.role,
    required this.time,
    required this.body,
    this.mine = false,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentMimeType,
  });

  final String authorName;
  final String initials;
  final List<Color> avatarColors;
  final String role;
  final String time;
  final String body;
  final bool mine;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMimeType;
}

class ActivityGroup {
  const ActivityGroup({required this.dateLabel, required this.items});

  final String dateLabel;
  final List<ActivityItem> items;
}
