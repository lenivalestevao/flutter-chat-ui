import 'package:flutter/material.dart';

import 'models.dart';

/// Demo conversations built relative to [now], so "Today" and "Yesterday" always show.
List<Conversation> seedConversations(DateTime now) {
  Message m(String id, Sender from, String text, Duration ago) =>
      Message(id: id, from: from, text: text, at: now.subtract(ago));
  const them = Sender.them;
  const me = Sender.me;

  return [
    Conversation(
      id: 'ana',
      name: 'Ana Souza',
      status: 'Online',
      color: const Color(0xFF7C5CFF),
      unread: 2,
      messages: [
        m('a1', them, 'Hi! Did you get a chance to look at the new designs?', const Duration(days: 2, hours: 3)),
        m('a2', me, 'Yes, they look great. I left a few notes in the doc.', const Duration(days: 2, hours: 2)),
        m('a3', them, 'Perfect, thank you!', const Duration(days: 1, hours: 5)),
        m('a4', them, 'Are we still on for the review at 3?', const Duration(minutes: 40)),
        m('a5', them, 'I will bring the updated mockups.', const Duration(minutes: 38)),
      ],
    ),
    Conversation(
      id: 'team',
      name: 'Design Team',
      status: '5 members',
      color: const Color(0xFF0EA5A4),
      messages: [
        m('t1', them, 'Reminder: sprint demo is tomorrow morning.', const Duration(days: 1, hours: 2)),
        m('t2', me, 'I will have the prototype ready tonight.', const Duration(days: 1, hours: 1)),
        m('t3', them, 'Awesome, see you all there.', const Duration(hours: 3)),
      ],
    ),
    Conversation(
      id: 'bruno',
      name: 'Bruno Lima',
      status: 'Last seen 1h ago',
      color: const Color(0xFFF59E0B),
      unread: 1,
      messages: [
        m('b1', me, 'Lunch tomorrow?', const Duration(hours: 6)),
        m('b2', them, 'Sure! The new place on Main Street?', const Duration(minutes: 90)),
      ],
    ),
    Conversation(
      id: 'carla',
      name: 'Carla Mendes',
      status: 'Online',
      color: const Color(0xFFEC4899),
      messages: [
        m('c1', them, 'Thanks for sending the invoice.', const Duration(days: 3)),
        m('c2', me, 'Anytime! Let me know if anything is missing.', const Duration(days: 2, hours: 23)),
      ],
    ),
    Conversation(
      id: 'diego',
      name: 'Diego Alves',
      status: 'Last seen yesterday',
      color: const Color(0xFF3B82F6),
      messages: [
        m('d1', them, 'Happy birthday! 🎉', const Duration(days: 5)),
      ],
    ),
  ];
}

/// Short canned replies used by the demo to simulate the other person.
const autoReplies = [
  'Sounds good to me!',
  'Thanks, I will take a look.',
  'Got it. Talk soon!',
  'Perfect, let us do that.',
  'Great idea 👍',
];
