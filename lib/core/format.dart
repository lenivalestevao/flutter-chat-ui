import '../data/models.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String initials(String name) {
  final parts = name.split(' ').where((p) => p.isNotEmpty).take(2);
  return parts.map((p) => p[0].toUpperCase()).join();
}

String formatTime(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// "Today", "Yesterday" or a short date such as "Nov 20".
String dayLabel(DateTime at, DateTime now) {
  // UTC dates avoid daylight saving surprises when counting days.
  final a = DateTime.utc(at.year, at.month, at.day);
  final b = DateTime.utc(now.year, now.month, now.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_months[at.month - 1]} ${at.day}';
}

class DayGroup {
  const DayGroup(this.label, this.messages);

  final String label;
  final List<Message> messages;
}

/// Groups messages by calendar day, keeping their order.
List<DayGroup> groupByDay(List<Message> messages, DateTime now) {
  final groups = <DayGroup>[];
  DateTime? currentDay;
  for (final m in messages) {
    final d = dayOnly(m.at);
    if (currentDay != null && d == currentDay) {
      groups.last.messages.add(m);
    } else {
      currentDay = d;
      groups.add(DayGroup(dayLabel(m.at, now), [m]));
    }
  }
  return groups;
}

/// One-line preview for the conversation list.
String preview(Conversation c, {int max = 42}) {
  final m = c.last;
  if (m == null) return 'No messages yet';
  final text = (m.from == Sender.me ? 'You: ' : '') + m.text;
  return text.length > max ? '${text.substring(0, max - 1).trimRight()}…' : text;
}
