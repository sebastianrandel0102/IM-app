import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/configuration/bootstrap.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../affection/domain/affection_type.dart';
import '../../animation/presentation/bear_scene.dart';

class PairingSuccessScreen extends StatelessWidget {
  const PairingSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Eyebrow('Two bears. One little world.'),
              const SizedBox(height: 30),
              const AspectRatio(
                aspectRatio: 1.1,
                child: BearScene(action: AffectionType.holdingHands),
              ),
              const SizedBox(height: 30),
              const Text(
                'Our little world\nbegins here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A place for all the little ways\nyou say “I love you”.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Palette.muted, height: 1.8),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Enter our world',
                icon: Icons.favorite_border_rounded,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});
  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _invite = TextEditingController();
  String? _token;
  BearCharacter _bear = BearCharacter.brown;
  bool _busy = false;
  Object? _error;
  @override
  void dispose() {
    _invite.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final state = ref.watch(pairProvider);
    final pair = state.value;
    final allowed =
        AppConfig.membershipConfigured &&
        AppConfig.partnerOf(user?.uid ?? '') != null;
    final exists = pair != null && pair.status != 'revoked';
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Just the two of us',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Account settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 235, child: BearScene()),
              const SizedBox(height: 25),
              const Eyebrow('A world for two'),
              const SizedBox(height: 12),
              Text(
                !allowed
                    ? 'Your story needs two bears.'
                    : pair?.status == 'confirming'
                    ? 'Is this your favorite person?'
                    : 'Find your other bear.',
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                !allowed
                    ? 'Your account is ready. Add both account UIDs to the private membership configuration, then rebuild the app.'
                    : pair?.status == 'confirming'
                    ? 'Your invitation was accepted. Each of you needs to confirm, on your own device.'
                    : 'A private invitation connects your two accounts. No one else can enter.',
                style: const TextStyle(color: Palette.muted, height: 1.7),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                ErrorNotice(_error!),
                const SizedBox(height: 16),
              ],
              if (state.hasError) ...[
                ErrorNotice(
                  state.error!,
                  retry: () => ref.invalidate(pairProvider),
                ),
                const SizedBox(height: 16),
              ],
              if (!allowed)
                PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Your Firebase account UID'),
                      const SizedBox(height: 12),
                      SelectableText(
                        user?.uid ?? 'Restoring account…',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: user == null
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: user.uid),
                                );
                                if (context.mounted) {
                                  notify(context, 'Account UID copied.');
                                }
                              },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy my UID'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'See docs/setup/firebase.md for the one-time allowlist setup. Both accounts must be created first.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Palette.muted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              if (allowed && !exists) ...[
                const Text(
                  'Which bear feels like you?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                SegmentedButton<BearCharacter>(
                  segments: const [
                    ButtonSegment(
                      value: BearCharacter.brown,
                      label: Text('Caramel bear'),
                    ),
                    ButtonSegment(
                      value: BearCharacter.white,
                      label: Text('White bear'),
                    ),
                  ],
                  selected: {_bear},
                  onSelectionChanged: (s) => setState(() => _bear = s.first),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Create our invitation',
                  icon: Icons.favorite_border_rounded,
                  busy: _busy,
                  onPressed: () => _run(() async {
                    final token = await ref
                        .read(pairingRepositoryProvider)
                        .create(_bear);
                    if (mounted) setState(() => _token = token);
                  }),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          'or join your person',
                          style: TextStyle(fontSize: 12, color: Palette.muted),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                TextField(
                  controller: _invite,
                  decoration: const InputDecoration(
                    labelText: 'Paste your private invitation',
                    hintText: 'The full invitation token',
                  ),
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => ref
                                .read(pairingRepositoryProvider)
                                .join(_invite.text),
                          ),
                    child: const Text('Join our little world'),
                  ),
                ),
              ],
              if (allowed && pair?.status == 'pending') ...[
                if (_token != null)
                  PaperCard(
                    color: const Color(0xFFF0E4F1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('For your person’s eyes only'),
                        const SizedBox(height: 12),
                        SelectableText(
                          _token!,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Copy private invitation',
                          icon: Icons.copy_rounded,
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: _token!),
                            );
                            if (context.mounted) {
                              notify(
                                context,
                                'Invitation copied. Share it privately with your person.',
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Valid for 23 hours. If you leave this screen, revoke and create a new token.',
                          style: TextStyle(fontSize: 11, color: Palette.muted),
                        ),
                      ],
                    ),
                  )
                else if (pair!.receiverUid == user?.uid) ...[
                  TextField(
                    controller: _invite,
                    decoration: const InputDecoration(
                      labelText: 'Paste your private invitation',
                    ),
                    autocorrect: false,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Accept invitation',
                    busy: _busy,
                    onPressed: () => _run(
                      () => ref
                          .read(pairingRepositoryProvider)
                          .join(_invite.text),
                    ),
                  ),
                ] else
                  const PaperCard(
                    child: Text(
                      'Waiting for your person to accept. Lost your token? Revoke this invitation and create a new one.',
                    ),
                  ),
              ],
              if (pair?.status == 'confirming') ...[
                PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You’ll be the ${pair!.bearFor(user!.uid).name} bear.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${pair.approvedBy.length} of 2 bears have confirmed.',
                        style: const TextStyle(color: Palette.muted),
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: pair.approvedBy.contains(user.uid)
                            ? 'Waiting for your bear…'
                            : 'Yes, let’s make this our world',
                        busy: _busy,
                        onPressed: pair.approvedBy.contains(user.uid)
                            ? null
                            : () => _run(
                                () => ref
                                    .read(pairingRepositoryProvider)
                                    .confirm(),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
              if (exists) ...[
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => ref.read(pairingRepositoryProvider).revoke(),
                          ),
                    child: const Text(
                      'Revoke this invitation or pairing',
                      style: TextStyle(color: Palette.rose),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Only your two approved accounts can join. ♡',
                  style: TextStyle(fontSize: 11, color: Palette.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
