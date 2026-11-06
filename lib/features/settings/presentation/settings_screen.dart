import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../affection/domain/affection_type.dart';
import '../../authentication/data/authentication_repository.dart';
import '../../home/presentation/home_screen.dart';
import '../../touch_echo/data/touch_echo_repository.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.studio = false,
    this.profileOnly = false,
    this.customizeOnly = false,
  });
  final bool studio, profileOnly, customizeOnly;
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  Object? _error;
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

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Stay here'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _clearDrafts({bool cancelTouch = true}) async {
    if (cancelTouch) {
      await ref.read(touchEchoRepositoryProvider)?.discard();
    }
    final uid = ref.read(authProvider).value?.uid;
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where(
      (k) =>
          k.startsWith('draft:$uid:') || k.startsWith('touch_outbox_${uid}_'),
    )) {
      await prefs.remove(key);
    }
    ref.read(affectionRepositoryProvider)?.clearSession();
  }

  Future<String?> _textDialog(
    String title,
    String label, {
    bool secret = false,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: secret,
          maxLength: secret ? null : 40,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Maybe later'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    // Wait until the dialog's exit transition has released its text field.
    Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider),
        controller = ref.read(settingsProvider.notifier);
    final profile = widget.studio
        ? null
        : ref.watch(currentProfileProvider).value;
    final user = widget.studio ? null : ref.watch(authProvider).value;
    final pair = widget.studio ? null : ref.watch(pairProvider).value;
    final world = widget.studio ? null : ref.watch(worldProvider).value;
    final theme = widget.studio
        ? ref.watch(studioThemeProvider)
        : SceneTheme.values.firstWhere(
            (e) => e.name == world?['themeId'],
            orElse: () => SceneTheme.cozyRoom,
          );
    final privateReady = pair?.active == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.profileOnly
              ? 'Your little profile'
              : widget.customizeOnly
              ? 'Make it ours'
              : 'Our settings',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                widget.studio
                    ? '/studio'
                    : privateReady
                    ? '/home'
                    : '/pairing',
              );
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                ErrorNotice(_error!),
                const SizedBox(height: 18),
              ],
              if (_busy) const LinearProgressIndicator(minHeight: 2),
              if (!widget.customizeOnly) ...[
                const Eyebrow('All the little details'),
                const SizedBox(height: 10),
                Text(
                  widget.studio
                      ? 'Your kind of cozy.'
                      : profile?.displayName ?? 'Little bear',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.studio
                      ? 'Settle into your little world.'
                      : user?.email ?? '',
                  style: const TextStyle(color: Palette.muted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                if (!widget.studio)
                  PaperCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline_rounded),
                          title: const Text('Your name'),
                          subtitle: Text(profile?.displayName ?? 'Little bear'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _busy
                              ? null
                              : () async {
                                  final name = await _textDialog(
                                    'What should we call you?',
                                    'Your name',
                                    initial: profile?.displayName ?? '',
                                  );
                                  if (name != null && user != null) {
                                    _run(
                                      () => UserRepository(
                                        FirebaseFirestore.instance,
                                      ).updateName(user.uid, name),
                                    );
                                  }
                                },
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock_outline_rounded),
                          title: const Text('Change password'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _busy
                              ? null
                              : () async {
                                  final current = await _textDialog(
                                    'Keep your world safe',
                                    'Current password',
                                    secret: true,
                                  );
                                  if (current == null || !mounted) return;
                                  final next = await _textDialog(
                                    'A fresh password',
                                    'New password (8+ characters)',
                                    secret: true,
                                  );
                                  if (next != null) {
                                    _run(() async {
                                      await ref
                                          .read(authRepositoryProvider)
                                          .changePassword(current, next);
                                      if (context.mounted) {
                                        notify(
                                          context,
                                          'Your password has been updated.',
                                        );
                                      }
                                    });
                                  }
                                },
                        ),
                        ListTile(
                          leading: const Icon(Icons.mail_outline_rounded),
                          title: const Text('Send a password reset link'),
                          onTap: _busy
                              ? null
                              : () => _run(() async {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .reset(user!.email!);
                                  if (context.mounted) {
                                    notify(
                                      context,
                                      'A reset link is on its way.',
                                    );
                                  }
                                }),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
              ],
              if (!widget.profileOnly) ...[
                const Eyebrow('Make yourself at home'),
                const SizedBox(height: 12),
                PaperCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Animation intensity'),
                        subtitle: Slider(
                          label:
                              '${(settings.animationIntensity * 100).round()}%',
                          semanticFormatterCallback: (v) =>
                              '${(v * 100).round()} percent',
                          value: settings.animationIntensity,
                          divisions: 4,
                          onChanged: (v) => controller.update(
                            settings.copyWith(animationIntensity: v),
                          ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Little sounds'),
                        subtitle: const Text(
                          'Soft sounds when you interact',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: settings.sound,
                        onChanged: (v) =>
                            controller.update(settings.copyWith(sound: v)),
                      ),
                      SwitchListTile(
                        title: const Text('Gentle haptics'),
                        value: settings.haptics,
                        onChanged: (v) =>
                            controller.update(settings.copyWith(haptics: v)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Touch Echo haptic strength',
                              style: TextStyle(fontSize: 12),
                            ),
                            Slider(
                              value: settings.touchHapticStrength,
                              min: 0,
                              max: 1,
                              divisions: 4,
                              label: settings.touchHapticStrength < .5
                                  ? 'Soft'
                                  : 'Light',
                              onChanged: settings.haptics
                                  ? (v) => controller.update(
                                      settings.copyWith(touchHapticStrength: v),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('A quieter kind of motion'),
                        subtitle: const Text(
                          'Reduce bouncing and movement',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: settings.reducedMotion,
                        onChanged: (v) => controller.update(
                          settings.copyWith(reducedMotion: v),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Surprise nudges'),
                        subtitle: const Text(
                          'In-app alerts while you’re here',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: settings.notifications,
                        onChanged: (v) => controller.update(
                          settings.copyWith(notifications: v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.studio || privateReady) ...[
                  const Eyebrow('Our little backdrop'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (final t in SceneTheme.values)
                        ChoiceChip(
                          label: Text(
                            t.label,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: theme == t,
                          showCheckmark: false,
                          selectedColor: Palette.lavender,
                          onSelected: _busy
                              ? null
                              : (_) {
                                  if (widget.studio) {
                                    ref
                                        .read(studioThemeProvider.notifier)
                                        .select(t);
                                  } else {
                                    _run(
                                      () => FirebaseFirestore.instance
                                          .collection('couples')
                                          .doc(pair!.invitationId)
                                          .update({'themeId': t.name}),
                                    );
                                  }
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!widget.studio) ...[
                    const Eyebrow('A little something to wear'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 9,
                      children: [
                        for (final accessory in [
                          'none',
                          'bow',
                          'scarf',
                          'flower',
                        ])
                          ChoiceChip(
                            label: Text(accessory),
                            selected: profile?.accessory == accessory,
                            selectedColor: Palette.blush,
                            showCheckmark: false,
                            onSelected: _busy
                                ? null
                                : (_) => _run(
                                    () => UserRepository(
                                      FirebaseFirestore.instance,
                                    ).updateAccessory(user!.uid, accessory),
                                  ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PaperCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.people_outline_rounded),
                        title: const Text('Spend a little time together'),
                        subtitle: const Text(
                          'A shared room while you’re both online',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/together'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
                const Eyebrow('A private little place'),
                const SizedBox(height: 12),
                const PaperCard(
                  child: Text(
                    'Only your two approved accounts can share this world. Notes are stored in Firebase and can be accessed by project administrators. They are not end-to-end encrypted.\n\nSurprises sync while you’re in the app. Automatic background push notifications are not included.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Palette.muted,
                      height: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (!widget.studio && !widget.customizeOnly) ...[
                PaperCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_outlined),
                        title: const Text('Clear local drafts & replay cache'),
                        onTap: _busy
                            ? null
                            : () => _run(() async {
                                await _clearDrafts();
                                if (context.mounted) {
                                  notify(
                                    context,
                                    'Local drafts and session replays cleared.',
                                  );
                                }
                              }),
                      ),
                      if (pair != null && pair.status != 'revoked')
                        ListTile(
                          leading: const Icon(
                            Icons.link_off_rounded,
                            color: Palette.rose,
                          ),
                          title: const Text('Disconnect our accounts'),
                          onTap: _busy
                              ? null
                              : () async {
                                  if (await _confirm(
                                    'Leave this little world?',
                                    'Both accounts immediately lose client access to this world’s moments. A new pairing starts a new book. Old data remains in the Firebase project until the owner removes it.',
                                    'Disconnect',
                                  )) {
                                    _run(
                                      () => ref
                                          .read(pairingRepositoryProvider)
                                          .revoke(),
                                    );
                                  }
                                },
                        ),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded),
                        title: const Text('See you soon · Sign out'),
                        onTap: _busy
                            ? null
                            : () => _run(() async {
                                await _clearDrafts(cancelTouch: false);
                                await ref.read(authRepositoryProvider).logout();
                              }),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.person_remove_outlined,
                          color: Palette.rose,
                        ),
                        title: const Text(
                          'Delete my account',
                          style: TextStyle(color: Palette.rose),
                        ),
                        onTap: _busy
                            ? null
                            : () async {
                                if (!await _confirm(
                                  'Close your little chapter?',
                                  'Your pairing will be revoked, your profile and sign-in account deleted. Shared moments become inaccessible to app clients. The project owner must delete retained Firestore records in the Firebase Console; account deletion alone does not erase them.',
                                  'Continue',
                                )) {
                                  return;
                                }
                                if (!mounted) return;
                                final password = await _textDialog(
                                  'Confirm it’s you',
                                  'Your password',
                                  secret: true,
                                );
                                if (password == null) return;
                                _run(() async {
                                  final auth = ref.read(authRepositoryProvider);
                                  await auth.reauthenticate(password);
                                  if (pair != null &&
                                      pair.status != 'revoked') {
                                    await ref
                                        .read(pairingRepositoryProvider)
                                        .revoke();
                                  }
                                  await _clearDrafts(cancelTouch: false);
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user!.uid)
                                      .delete();
                                  await FirebaseAuth.instance.currentUser!
                                      .delete();
                                });
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'bear with me · 1.0.0\nMade for two. With a little love. ♡',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Palette.muted,
                    height: 1.9,
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
