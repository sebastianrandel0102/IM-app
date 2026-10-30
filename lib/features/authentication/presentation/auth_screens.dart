import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/configuration/bootstrap.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../animation/presentation/bear_scene.dart';
import '../../settings/data/settings_repository.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapProvider);
    final reduced =
        ref.watch(settingsProvider).reducedMotion ||
        MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 800;
            final art = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Eyebrow('A little world, just for us'),
                const SizedBox(height: 20),
                AspectRatio(
                  aspectRatio: 1.17,
                  child: BearScene(reducedMotion: reduced),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A little closer, even from far away.',
                  style: TextStyle(fontSize: 12, color: Palette.muted),
                ),
              ],
            );
            final form = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 28,
                  color: Palette.pink,
                ),
                const SizedBox(height: 18),
                const Text(
                  'bear with me',
                  style: TextStyle(
                    fontSize: 46,
                    height: 1.12,
                    letterSpacing: -2.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'For the hugs you can’t give\nin person. Yet.',
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Send a little love. Open a little surprise.\nMake a memory that’s just yours.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.8,
                    color: Palette.muted,
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Start our story',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.go('/register'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('I already have an account'),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/studio'),
                    child: const Text(
                      'Take a little look around ›',
                      style: TextStyle(fontSize: 13, color: Palette.muted),
                    ),
                  ),
                ),
                if (!bootstrap.ready) ...[
                  const SizedBox(height: 16),
                  ErrorNotice(
                    bootstrap.error ?? 'Firebase isn’t connected yet. You can explore the local preview. Account and delivery features need your Firebase project configuration.',
                  ),
                ],
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: Palette.muted,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'A private place for your favorite person.',
                      style: TextStyle(fontSize: 11, color: Palette.muted),
                    ),
                  ],
                ),
              ],
            );
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(wide ? 60 : 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(child: art),
                            const SizedBox(width: 80),
                            Expanded(child: form),
                          ],
                        )
                      : Column(
                          children: [
                            SizedBox(width: 350, child: art),
                            const SizedBox(height: 36),
                            form,
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 280, child: BearScene()),
            SizedBox(height: 20),
            Text(
              'Finding our little world…',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    ),
  );
}

enum AuthMode { login, register, reset }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode});
  final AuthMode mode;
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _obscure = true, _busy = false, _terms = false, _resetSent = false;
  Object? _error;
  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (widget.mode == AuthMode.register && !_terms) {
      setState(
        () => _error =
            'Please acknowledge how this private world stores your data.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      switch (widget.mode) {
        case AuthMode.login:
          await repo.login(_email.text, _password.text);
        case AuthMode.register:
          await repo.register(_name.text, _email.text, _password.text);
        case AuthMode.reset:
          await repo.reset(_email.text);
          if (mounted) setState(() => _resetSent = true);
      }
      if (mounted) TextInput.finishAutofillContext();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final register = widget.mode == AuthMode.register,
        reset = widget.mode == AuthMode.reset;
    final ready = ref.watch(bootstrapProvider).ready;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 40),
          child: AutofillGroup(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 160, child: BearScene()),
                  const SizedBox(height: 24),
                  Eyebrow(
                    reset
                        ? 'A fresh little start'
                        : register
                        ? 'Chapter one'
                        : 'Your happy place is waiting',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reset
                        ? 'Forgot your password?'
                        : register
                        ? 'Let’s begin your story.'
                        : 'Welcome home, bear.',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.9,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reset
                        ? 'We’ll send a link to help you find your way back.'
                        : register
                        ? 'One account for you. One for your favorite person.'
                        : 'A little love is waiting on the other side.',
                    style: const TextStyle(color: Palette.muted, height: 1.6),
                  ),
                  const SizedBox(height: 26),
                  if (!ready)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ErrorNotice(
                        'Connect your Firebase project to create an account or sign in. See docs/setup/firebase.md.',
                      ),
                    ),
                  if (_error != null) ...[
                    ErrorNotice(_error!),
                    const SizedBox(height: 16),
                  ],
                  if (_resetSent)
                    const PaperCard(
                      color: Palette.sage,
                      child: Text(
                        'If there’s an account with this email, a reset link is on its way. Check your inbox and spam folder.',
                      ),
                    )
                  else ...[
                    if (register) ...[
                      TextFormField(
                        controller: _name,
                        autofillHints: const [AutofillHints.nickname],
                        textCapitalization: TextCapitalization.words,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          labelText: 'What should your bear call you?',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Your name, please.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (v) =>
                          v == null ||
                              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(v.trim())
                          ? 'Enter a valid email address.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (!reset) ...[
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: [
                          register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.length < (register ? 8 : 1)
                            ? (register
                                  ? 'Use at least 8 characters.'
                                  : 'Enter your password.')
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (register) ...[
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: const InputDecoration(
                          labelText: 'One more time',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator: (v) => v != _password.text
                            ? 'Your passwords don’t match.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _terms,
                        onChanged: (v) => setState(() => _terms = v!),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'I understand notes are stored privately in Firebase, accessible to the pair and project administrators. This app is not end-to-end encrypted.',
                          style: TextStyle(fontSize: 11, height: 1.5),
                        ),
                      ),
                    ],
                    if (!register && !reset)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: const Text('Forgot your password?'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: reset
                          ? 'Send a reset link'
                          : register
                          ? 'Create my little world'
                          : 'Come on in',
                      onPressed: ready ? _submit : null,
                      busy: _busy,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(
                        register || reset ? '/login' : '/register',
                      ),
                      child: Text(
                        register || reset
                            ? 'Already a bear? Sign in'
                            : 'New here? Start your story',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
