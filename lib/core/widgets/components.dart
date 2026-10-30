import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../errors/friendly_error.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = Palette.rose});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.3,
      color: color,
    ),
  );
}

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.color = Palette.paper,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: Palette.ink.withValues(alpha: .065)),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (icon != null)
            Icon(icon, size: 19),
          if (busy || icon != null) const SizedBox(width: 10),
          Text(label),
        ],
      ),
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.error, {super.key, this.retry});
  final Object error;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => PaperCard(
    color: const Color(0xFFF9E3E4),
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 20, color: Palette.rose),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            error is String ? error as String : friendlyError(error),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (retry != null)
          IconButton(
            onPressed: retry,
            tooltip: 'Try again',
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.favorite_border_rounded,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Palette.blush,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Palette.muted, height: 1.6),
        ),
        if (action != null) ...[const SizedBox(height: 22), action!],
      ],
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 600});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

String shortDate(DateTime? date) {
  if (date == null) return 'Syncing…';
  final local = date.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day} · ${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'am' : 'pm'}';
}

void notify(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

IconData affectionIcon(String scene) => switch (scene) {
  'hug' || 'cuddle' => Icons.favorite_border_rounded,
  'kiss' => Icons.favorite_rounded,
  'hands' => Icons.handshake_outlined,
  'pat' || 'boop' || 'tickle' => Icons.front_hand_outlined,
  'flower' => Icons.local_florist_outlined,
  'sleep' || 'moon' => Icons.nightlight_outlined,
  'gift' => Icons.card_giftcard_rounded,
  'sun' => Icons.wb_sunny_outlined,
  'rain' => Icons.umbrella_outlined,
  'dance' => Icons.music_note_rounded,
  'ride' => Icons.emoji_people_rounded,
  'tear' => Icons.water_drop_outlined,
  _ => Icons.favorite_border_rounded,
};
