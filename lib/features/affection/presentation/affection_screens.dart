import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../animation/presentation/bear_scene.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/affection_type.dart';

class AffectionLibrary extends StatefulWidget {
  const AffectionLibrary({super.key, this.studio = false});
  final bool studio;
  @override
  State<AffectionLibrary> createState() => _AffectionLibraryState();
}

class _AffectionLibraryState extends State<AffectionLibrary> {
  String _category = 'All little loves', _query = '';
  @override
  Widget build(BuildContext context) {
    final types = AffectionType.values
        .where(
          (t) =>
              (_category == 'All little loves' || t.category == _category) &&
              t.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 36),
      child: PageBody(
        maxWidth: 1060,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('From your heart to theirs'),
            const SizedBox(height: 12),
            const Text(
              'Send a little love.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'For every “wish you were here” kind of feeling.',
              style: TextStyle(color: Palette.muted, fontSize: 14),
            ),
            const SizedBox(height: 25),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Find the perfect little gesture',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in [
                  'All little loves',
                  'Everyday',
                  'Cozy',
                  'Playful',
                  'Comfort',
                  'Surprises',
                ])
                  ChoiceChip(
                    label: Text(category, style: const TextStyle(fontSize: 12)),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                    showCheckmark: false,
                    selectedColor: Palette.blush,
                    backgroundColor: Palette.paper,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (types.isEmpty)
              const EmptyState(
                title: 'A little love is hiding.',
                message: 'Try a different search or category.',
                icon: Icons.search_rounded,
              )
            else
              LayoutBuilder(
                builder: (context, c) {
                  final columns = c.maxWidth > 850
                      ? 4
                      : c.maxWidth > 570
                      ? 3
                      : 2;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 16,
                    children: [
                      for (final type in types)
                        SizedBox(
                          width: (c.maxWidth - 14 * (columns - 1)) / columns,
                          child: Material(
                            color: Palette.paper,
                            borderRadius: BorderRadius.circular(22),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.push(
                                '${widget.studio ? '/studio/preview' : '/affection/preview'}?type=${type.name}',
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1.4,
                                    child: BearScene(
                                      action: type,
                                      reducedMotion: true,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          type.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          type.message,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Palette.muted,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Text(
                                              type.category.toLowerCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Palette.rose,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 16,
                                              color: Palette.muted,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 28),
            const Center(
              child: Text(
                'Every gesture is a little way of saying “you”. ♡',
                style: TextStyle(fontSize: 12, color: Palette.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key, this.studio = false, this.typeName});
  final bool studio;
  final String? typeName;
  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _message = TextEditingController();
  AffectionVariant _variant = AffectionVariant.gentle;
  late AffectionType _type;
  String? _requestId;
  bool _busy = false, _sent = false, _lockedDraft = false;
  Object? _error;
  String get _draftKey =>
      'draft:${widget.studio ? 'studio' : ref.read(authProvider).value?.uid}:${_type.name}';
  @override
  void initState() {
    super.initState();
    _type = AffectionType.values.firstWhere(
      (t) => t.name == widget.typeName,
      orElse: () => AffectionType.warmHug,
    );
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw != null && mounted) {
      try {
        final d = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _message.text = (d['message'] as String? ?? '').substring(
            0,
            (d['message'] as String? ?? '').length.clamp(0, 500),
          );
          _requestId = d['id'] as String?;
          _lockedDraft = d['locked'] == true;
          _variant = AffectionVariant.values.firstWhere(
            (v) => v.name == d['variant'],
            orElse: () => AffectionVariant.gentle,
          );
        });
      } catch (_) {
        await prefs.remove(_draftKey);
      }
    }
  }

  Future<void> _saveDraft() async =>
      (await SharedPreferences.getInstance()).setString(
        _draftKey,
        jsonEncode({
          'message': _message.text,
          'variant': _variant.name,
          'id': _requestId,
          'locked': _lockedDraft,
        }),
      );
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final repo = ref.read(affectionRepositoryProvider);
    if (repo == null) return;
    _requestId ??= repo.newId();
    setState(() {
      _busy = true;
      _error = null;
      _lockedDraft = true;
    });
    await _saveDraft();
    try {
      await repo.sendAffection(
        requestId: _requestId!,
        type: _type,
        variant: _variant.name,
        message: _message.text.trim(),
      );
      await (await SharedPreferences.getInstance()).remove(_draftKey);
      if (mounted) {
        setState(() => _sent = true);
        notify(context, 'A little love has been sent. ♡');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final partner = widget.studio ? null : ref.watch(partnerProvider).value;
    final pair = widget.studio ? null : ref.watch(pairProvider).value;
    final user = widget.studio ? null : ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sent ? 'On its way, with love' : _type.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: BearScene(
                  action: _type,
                  intensity: settings.animationIntensity,
                  variant: _variant.name,
                  reducedMotion:
                      settings.reducedMotion ||
                      MediaQuery.disableAnimationsOf(context),
                  sender: pair != null && user != null
                      ? pair.bearFor(user.uid)
                      : BearCharacter.brown,
                ),
              ),
              const SizedBox(height: 24),
              Eyebrow(
                _sent
                    ? 'A little love, delivered to the inbox'
                    : 'A little moment for ${partner?.displayName ?? 'your person'}',
              ),
              const SizedBox(height: 12),
              Text(
                _sent ? 'Sealed with a little love.' : _type.message,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _sent
                    ? 'Your bear’s inbox can now find this surprise. They’ll open it when they’re ready.'
                    : 'It will arrive as a sealed surprise. Only they get to open it.',
                style: const TextStyle(color: Palette.muted, height: 1.7),
              ),
              const SizedBox(height: 24),
              if (_sent) ...[
                PrimaryButton(
                  label: 'Back to our world',
                  icon: Icons.cottage_outlined,
                  onPressed: () => context.go('/home'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/inbox'),
                    child: const Text('View our history'),
                  ),
                ),
              ] else ...[
                if (widget.studio) ...[
                  const PaperCard(
                    color: Palette.lavender,
                    child: Text(
                      'You’re exploring a local preview. No surprise will be sent to another person.',
                      style: TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                const Text(
                  'Make it your kind of love',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final variant in AffectionVariant.values)
                      ChoiceChip(
                        label: Text(variant.name),
                        selected: _variant == variant,
                        onSelected: _lockedDraft
                            ? null
                            : (_) {
                                setState(() => _variant = variant);
                                _saveDraft();
                              },
                        selectedColor: Palette.blush,
                        showCheckmark: false,
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _message,
                  maxLength: 500,
                  maxLines: 4,
                  enabled: !_lockedDraft,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'A little note (optional)',
                    alignLabelWithHint: true,
                    hintText: 'What’s on your heart?',
                  ),
                  onChanged: (_) => _saveDraft(),
                ),
                const SizedBox(height: 8),
                if (_error != null) ...[
                  ErrorNotice(_error!),
                  const SizedBox(height: 12),
                ],
                if (_lockedDraft && !_busy && !_sent)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'This draft is locked to one request so retrying can’t send it twice. Check Sent history if the connection dropped.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Palette.muted,
                        height: 1.6,
                      ),
                    ),
                  ),
                if (widget.studio)
                  PrimaryButton(
                    label: 'Try this little moment',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () =>
                        context.push('/studio/play?type=${_type.name}'),
                  )
                else
                  PrimaryButton(
                    label: _lockedDraft
                        ? 'Check & retry this surprise'
                        : 'Send a little love',
                    icon: Icons.favorite_border_rounded,
                    busy: _busy,
                    onPressed: _send,
                  ),
                const SizedBox(height: 12),
                if (!widget.studio)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          context.push('/studio/play?type=${_type.name}'),
                      child: const Text('Try the gesture locally'),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    widget.studio
                        ? 'Connect Firebase from the welcome screen to send.'
                        : 'Your note stays a secret until they open the envelope.',
                    style: const TextStyle(fontSize: 11, color: Palette.muted),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_lockedDraft && !_busy)
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await (await SharedPreferences.getInstance()).remove(
                          _draftKey,
                        );
                        if (mounted) {
                          setState(() {
                            _requestId = null;
                            _lockedDraft = false;
                            _error = null;
                          });
                        }
                      },
                      child: const Text('Start a new draft'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
