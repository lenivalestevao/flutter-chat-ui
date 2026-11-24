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

/// 75 seconds becomes "1:15".
String formatDuration(Duration d) {
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$s';
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

/// "Missed video call", "Cancelled voice call", "Voice call"...
String callTitle(Message m) {
  final info = m.call!;
  final kind = info.video ? 'video' : 'voice';
  if (info.missed) {
    return m.from == Sender.them ? 'Missed $kind call' : 'Cancelled $kind call';
  }
  return info.video ? 'Video call' : 'Voice call';
}

/// Text shown in the conversation list for one message.
String previewText(Message m) {
  switch (m.kind) {
    case MessageKind.text:
      return m.text;
    case MessageKind.image:
      return '📷 Photo';
    case MessageKind.audio:
      return '🎤 ${formatDuration(m.audioDuration)}';
    case MessageKind.location:
      return '📍 Location';
    case MessageKind.call:
      return '${m.call!.video ? '📹' : '📞'} ${callTitle(m)}';
  }
}

/// One-line preview for the conversation list.
String preview(Conversation c, {int max = 42}) {
  final m = c.last;
  if (m == null) return 'No messages yet';
  final text = (m.from == Sender.me && m.kind != MessageKind.call ? 'You: ' : '') + previewText(m);
  return text.length > max ? '${text.substring(0, max - 1).trimRight()}…' : text;
}
