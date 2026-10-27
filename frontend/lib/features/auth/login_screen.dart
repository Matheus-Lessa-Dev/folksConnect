import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/folks_theme.dart';
import '../../shared/widgets/folks_logo.dart';
import 'authentication_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authentication = const UnavailableAuthenticationService(),
    this.onAuthenticated,
    this.onForgotPassword,
  });

  final AuthenticationService authentication;
  final VoidCallback? onAuthenticated;
  final VoidCallback? onForgotPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await widget.authentication.signIn(
        username: _username.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      _password.clear();
      widget.onAuthenticated?.call();
    } on InvalidCredentials {
      if (!mounted) return;
      setState(() => _error = 'E-mail ou senha incorretos.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível entrar. Tente novamente mais tarde.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _forgotPassword() {
    if (widget.onForgotPassword != null) {
      widget.onForgotPassword!();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: const Text(
          'Recuperação de senha indisponível no momento. '
          'Entre em contato com o administrador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: FolksColors.authBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: FolksColors.authBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Reference: 402 x 874. Small windows and keyboard scroll rather
              // than scaling down text or clipping the form.
              final height = math.max(constraints.maxHeight, 740.0);
              final logoTop = height * 108 / 874;
              final formTop = math.max(
                height * 400 / 874,
                logoTop + FolksLogo.height + 48,
              );
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: height),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 402),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SizedBox(height: logoTop),
                            const FolksLogo(),
                            SizedBox(
                              height: formTop - logoTop - FolksLogo.height,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 11),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 265,
                                ),
                                child: _buildForm(),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AutofillGroup(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LoginField(
              label: 'Usuário:',
              icon: Icons.person,
              controller: _username,
              focusNode: _usernameFocus,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              enabled: !_submitting,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe seu usuário.'
                  : null,
            ),
            const SizedBox(height: 54),
            _LoginField(
              label: 'Senha:',
              icon: Icons.lock,
              controller: _password,
              focusNode: _passwordFocus,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              enabled: !_submitting,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Informe sua senha.' : null,
            ),
            const SizedBox(height: 63),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: SizedBox(
                  width: 176,
                  child: Semantics(
                    button: true,
                    enabled: !_submitting,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submitting ? null : _submit,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: FolksColors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5.4,
                              ),
                              child: Text(
                                _submitting ? 'Entrando…' : 'Entrar',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: FolksColors.white,
                                  fontSize: 16,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _submitting ? null : _forgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: FolksColors.white,
                  minimumSize: const Size(112, 48),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 11, height: 1.2),
                ),
                child: const Text(
                  'Esqueceu a Senha?',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: FolksColors.orange,
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: FolksColors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.focusNode,
    required this.autofillHints,
    required this.textInputAction,
    required this.onSubmitted,
    required this.validator,
    required this.enabled,
    this.obscureText = false,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSubmitted;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    const border = UnderlineInputBorder(
      borderSide: BorderSide(color: FolksColors.orange, width: 0.5),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? focusNode.requestFocus : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                Icon(icon, size: 14, color: FolksColors.white),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: FolksColors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: label,
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              obscureText: obscureText,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: autofillHints,
              textInputAction: textInputAction,
              onFieldSubmitted: onSubmitted,
              validator: validator,
              style: const TextStyle(color: FolksColors.white, fontSize: 16),
              cursorColor: FolksColors.orange,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 7),
                enabledBorder: border,
                disabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: const BorderSide(
                    color: FolksColors.orange,
                    width: 1.5,
                  ),
                ),
                errorMaxLines: 2,
                errorStyle: const TextStyle(
                  color: FolksColors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
