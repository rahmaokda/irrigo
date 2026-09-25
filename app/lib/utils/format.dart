import 'package:intl/intl.dart';

/// "just now", "5 min ago", "3 h ago", "2 days ago".
String timeAgo(DateTime time, DateTime now) {
  final d = now.difference(time);
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  final days = d.inDays;
  return days == 1 ? '1 day ago' : '$days days ago';
}

/// "10:42 AM" today, otherwise "Sep 24, 10:42 AM".
String shortDateTime(DateTime time, DateTime now) {
  final sameDay =
      time.year == now.year && time.month == now.month && time.day == now.day;
  return sameDay
      ? DateFormat.jm().format(time)
      : DateFormat('MMM d, ').add_jm().format(time);
}

String greeting(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 18) return 'Good afternoon';
  return 'Good evening';
}
