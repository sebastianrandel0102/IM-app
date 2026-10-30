import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../affection/data/affection_repository.dart';
import '../../affection/domain/models.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key, this.studio = false});
  final bool studio;
  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _outgoing = false, _loading = false, _more = true;
  final List<AffectionMoment> _older = [];
  Future<void> _loadOlder(List<AffectionMoment> recent) async {
    final before = _older.isNotEmpty ? _older.last : recent.last;
    if (before.createdAt == null) return;
    setState(() => _loading = true);
    try {
      final list = await InboxRepository(ref.read(affectionRepositoryProvider)!)
          .older(before, outgoing: _outgoing);
      if (mounted) {
        setState(() {
          _older.addAll(list);
          _more = list.length == 30;
        });
      }
    } catch (e) {
      if (mounted) {
        notify(
          context,
          e.toString().contains('permission')
              ? 'Your world needs to reconnect.'
              : 'Older moments couldn’t load. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.studio
        ? null
        : ref.watch(_outgoing ? outgoingProvider : inboxProvider);
    final recent = state?.value ?? <AffectionMoment>[];
    final seen = <String>{};
    final moments = [
      ...recent,
      ..._older,
    ].where((m) => seen.add(m.id)).toList();
    final partner = widget.studio ? null : ref.watch(partnerProvider).value;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 36),
      child: PageBody(
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('A little mailbox, a lot of love'),
            const SizedBox(height: 12),
            const Text(
              'Something just for you.',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'The sweetest things are worth opening slowly.',
              style: TextStyle(color: Palette.muted, height: 1.6),
            ),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('For you'),
                  icon: Icon(Icons.mail_outline_rounded),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('From you'),
                  icon: Icon(Icons.send_outlined),
                ),
              ],
              selected: {_outgoing},
              onSelectionChanged: (v) => setState(() {
                _outgoing = v.first;
                _older.clear();
                _more = true;
              }),
            ),
            const SizedBox(height: 24),
            if (state?.isLoading == true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (state?.hasError == true)
              ErrorNotice(
                state!.error!,
                retry: () => ref.invalidate(
                  _outgoing ? outgoingProvider : inboxProvider,
                ),
              ),
            if (moments.isEmpty &&
                state?.isLoading != true &&
                state?.hasError != true)
              EmptyState(
                icon: Icons.mark_email_unread_outlined,
                title: _outgoing
                    ? 'Your first little love.'
                    : 'Your mailbox is a quiet little place.',
                message: widget.studio
                    ? 'Surprises from another person will appear here after Firebase is connected and your accounts are paired.'
                    : _outgoing
                    ? 'Send a small gesture. Make their day a little warmer.'
                    : 'When your bear sends you a surprise, it will wait here, sealed just for you.',
                action: TextButton(
                  onPressed: () => context.go(
                    widget.studio ? '/studio/affection' : '/affection',
                  ),
                  child: const Text('Send a little love  ›'),
                ),
              ),
            for (final moment in moments)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PaperCard(
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 64,
                        decoration: BoxDecoration(
                          color: moment.openedAt == null
                              ? Palette.blush.withValues(alpha: .65)
                              : Palette.cream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          moment.openedAt == null
                              ? Icons.mark_email_unread_outlined
                              : Icons.drafts_outlined,
                          size: 28,
                          color: Palette.rose,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _outgoing
                                  ? 'A little love for ${partner?.displayName ?? 'your bear'}'
                                  : 'A little surprise from ${partner?.displayName ?? 'your bear'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              shortDate(moment.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Palette.muted,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              moment.openedAt == null
                                  ? (_outgoing
                                        ? 'Waiting for their curious paws'
                                        : 'Still a secret. Just for you.')
                                  : 'Opened with love ♡',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Palette.rose,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                              onPressed: () => context.push(
                                _outgoing
                                    ? '/moment/${moment.id}/play'
                                    : '/inbox/${moment.id}',
                              ),
                              child: Text(
                                _outgoing
                                    ? 'Revisit your moment  ›'
                                    : moment.openedAt == null
                                    ? 'Open surprise  ›'
                                    : 'Replay this moment  ›',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_more && recent.length >= 30)
              Center(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => _loadOlder(recent),
                  child: Text(
                    _loading ? 'Finding more love…' : 'A few older moments',
                  ),
                ),
              ),
            if (moments.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    'Your recent 30 moments stay in sync. Load older ones anytime.',
                    style: TextStyle(fontSize: 10, color: Palette.muted),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SurpriseScreen extends ConsumerStatefulWidget {
  const SurpriseScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<SurpriseScreen> createState() => _SurpriseScreenState();
}

class _SurpriseScreenState extends ConsumerState<SurpriseScreen> {
  bool _busy = false;
  Object? _error;
  Future<void> _open() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = await ref
          .read(affectionRepositoryProvider)!
          .openSurprise(widget.id);
      if (mounted) {
        context.pushReplacement('/moment/${widget.id}/play', extra: payload);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'For your eyes only',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    body: PageBody(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Eyebrow('Someone’s thinking of you'),
            const SizedBox(height: 40),
            Transform.rotate(
              angle: -.08,
              child: Container(
                width: 245,
                height: 180,
                decoration: BoxDecoration(
                  color: Palette.blush,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Palette.ink.withValues(alpha: .06),
                      blurRadius: 25,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(245, 180),
                      painter: _EnvelopePainter(),
                    ),
                    Container(
                      width: 47,
                      height: 47,
                      decoration: const BoxDecoration(
                        color: Palette.paper,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Palette.rose,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
            const Text(
              'A little surprise.\nA whole lot of love.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                height: 1.25,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'What’s inside? That’s between you\nand your favorite bear.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.muted, height: 1.8),
            ),
            const SizedBox(height: 35),
            if (_error != null) ...[
              ErrorNotice(_error!),
              const SizedBox(height: 18),
            ],
            PrimaryButton(
              label: 'Open my surprise',
              busy: _busy,
              icon: Icons.favorite_border_rounded,
              onPressed: _open,
            ),
            const SizedBox(height: 16),
            const Text(
              'Open it whenever your heart is ready.',
              style: TextStyle(fontSize: 11, color: Palette.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE3A8B9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(
      Path()
        ..moveTo(3, 3)
        ..lineTo(size.width / 2, size.height * .53)
        ..lineTo(size.width - 3, 3),
      p,
    );
    canvas.drawLine(
      Offset(3, size.height - 3),
      Offset(size.width * .38, size.height * .44),
      p,
    );
    canvas.drawLine(
      Offset(size.width - 3, size.height - 3),
      Offset(size.width * .62, size.height * .44),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
