import 'package:flutter/material.dart';

import '../services/session_controller.dart';
import '../services/trip_repository.dart';
import '../theme/atlas_theme.dart';
import 'my_trips_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    required this.sessionController,
    required this.tripRepository,
    super.key,
  });

  final SessionController sessionController;
  final PersonalTripRepository tripRepository;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _registering = false;
  bool _hidePassword = true;
  String? _error;

  bool get _romanian => Localizations.localeOf(context).languageCode == 'ro';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      if (_registering) {
        await widget.sessionController.register(
          email: _emailController.text,
          displayName: _nameController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmationController.text,
        );
      } else {
        await widget.sessionController.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      _passwordController.clear();
      _confirmationController.clear();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.sessionController,
      builder: (context, _) => Scaffold(
        backgroundColor: AtlasColors.ivory,
        appBar: AppBar(
          backgroundColor: AtlasColors.paper,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'WeatherWise',
            style:
                TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
          ),
        ),
        body: widget.sessionController.restoring
            ? _restoringView()
            : widget.sessionController.authenticated
                ? _signedInView()
                : _authenticationView(),
      ),
    );
  }

  Widget _authenticationView() => ListView(
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          _accountHero(
            title: _registering
                ? (_romanian
                    ? 'Păstrează-ți călătoriile.'
                    : 'Keep your journeys.')
                : (_romanian ? 'Bine ai revenit.' : 'Welcome back.'),
            message: _romanian
                ? 'Planurile create după autentificare rămân în biblioteca ta, pe orice dispozitiv.'
                : 'Plans created after sign-in stay in your library across devices.',
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AtlasColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x175E6D65),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 48,
                            child: SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(
                                  value: false,
                                  icon: const Icon(Icons.login_rounded),
                                  label: Text(
                                      _romanian ? 'Intră în cont' : 'Sign in'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  icon: const Icon(
                                      Icons.person_add_alt_1_rounded),
                                  label: Text(_romanian
                                      ? 'Cont nou'
                                      : 'Create account'),
                                ),
                              ],
                              selected: {_registering},
                              onSelectionChanged: widget.sessionController.busy
                                  ? null
                                  : (value) => setState(() {
                                        _registering = value.first;
                                        _error = null;
                                      }),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_registering) ...[
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: InputDecoration(
                                labelText:
                                    _romanian ? 'Numele tău' : 'Your name',
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                              validator: (value) =>
                                  value != null && value.length > 80
                                      ? (_romanian
                                          ? 'Maximum 80 de caractere.'
                                          : 'Maximum 80 characters.')
                                      : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (!email.contains('@') ||
                                  !email.contains('.')) {
                                return _romanian
                                    ? 'Introdu o adresă de email validă.'
                                    : 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _hidePassword,
                            textInputAction: _registering
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: [
                              _registering
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) {
                              if (!_registering) _submit();
                            },
                            decoration: InputDecoration(
                              labelText: _romanian ? 'Parolă' : 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip: _romanian
                                    ? (_hidePassword
                                        ? 'Arată parola'
                                        : 'Ascunde parola')
                                    : (_hidePassword
                                        ? 'Show password'
                                        : 'Hide password'),
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => (value?.length ?? 0) < 8
                                ? (_romanian
                                    ? 'Parola trebuie să aibă minimum 8 caractere.'
                                    : 'Password must contain at least 8 characters.')
                                : null,
                          ),
                          if (_registering) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmationController,
                              obscureText: _hidePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: _romanian
                                    ? 'Confirmă parola'
                                    : 'Confirm password',
                                prefixIcon:
                                    const Icon(Icons.lock_reset_rounded),
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                      ? (_romanian
                                          ? 'Parolele nu coincid.'
                                          : 'Passwords do not match.')
                                      : null,
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            _InlineError(message: _error!),
                          ],
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed:
                                widget.sessionController.busy ? null : _submit,
                            icon: widget.sessionController.busy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(_registering
                                    ? Icons.person_add_alt_1_rounded
                                    : Icons.login_rounded),
                            label: Text(_registering
                                ? (_romanian
                                    ? 'Creează contul'
                                    : 'Create account')
                                : (_romanian ? 'Intră în cont' : 'Sign in')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _signedInView() {
    final user = widget.sessionController.user!;
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        _accountHero(
          title: _romanian
              ? 'Bun venit, ${user.greetingName}.'
              : 'Welcome, ${user.greetingName}.',
          message: _romanian
              ? 'Planurile noi sunt salvate automat în contul tău.'
              : 'New plans are saved automatically to your account.',
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    tileColor: AtlasColors.paper,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AtlasColors.line),
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: AtlasColors.paleGold,
                      foregroundColor: AtlasColors.ink,
                      child: Icon(Icons.person_outline_rounded),
                    ),
                    title: Text(user.greetingName),
                    subtitle: Text(user.email),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MyTripsScreen(
                          repository: widget.tripRepository,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.luggage_outlined),
                    label: Text(
                      _romanian ? 'Călătoriile mele' : 'My trips',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.sessionController.busy
                        ? null
                        : widget.sessionController.logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(_romanian ? 'Ieși din cont' : 'Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _restoringView() => ListView(
        children: [
          _accountHero(
            title:
                _romanian ? 'Pregătim contul tău.' : 'Preparing your account.',
            message: _romanian
                ? 'Verificăm în siguranță sesiunea salvată pe acest dispozitiv.'
                : 'Securely checking the session saved on this device.',
          ),
          const Padding(
            padding: EdgeInsets.only(top: 72),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );

  String _friendlyAuthError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('incorrect') || message.contains('credentials')) {
      return _romanian
          ? 'Emailul sau parola nu sunt corecte. Verifică datele și încearcă din nou.'
          : 'The email or password is incorrect. Check your details and try again.';
    }
    if (message.contains('already been taken') ||
        message.contains('already used')) {
      return _romanian
          ? 'Există deja un cont cu acest email. Intră în cont sau folosește altă adresă.'
          : 'An account already uses this email. Sign in or use another address.';
    }
    return _romanian
        ? 'Contul nu a putut fi accesat acum. Verifică internetul și încearcă din nou.'
        : 'Your account could not be reached. Check your connection and try again.';
  }

  Widget _accountHero({required String title, required String message}) =>
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AtlasColors.paleGold, AtlasColors.sky],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 46),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AtlasColors.mutedInk,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        ),
      );
}
