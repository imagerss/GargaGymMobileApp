import 'package:flutter/material.dart';

import '../../core/app_logo.dart';
import '../../core/app_theme.dart';
import '../../services/api_client.dart';
import 'auth_controller.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  AuthMode _mode = AuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _error;

  bool get _isRegister => _mode == AuthMode.register;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _error = null);
    try {
      if (_isRegister) {
        await widget.controller.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
        );
      } else {
        await widget.controller.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } on ApiException catch (exception) {
      setState(() => _error = exception.message);
    } catch (_) {
      setState(() {
        _error = _isRegister
            ? 'Nie udalo sie utworzyc konta. Sprawdz dane.'
            : 'Nieprawidlowe dane logowania lub brak polaczenia.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.slate200),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x160f172a),
                      blurRadius: 28,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const AppLogo(size: 46, borderRadius: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isRegister
                                      ? 'Utworz konto'
                                      : 'Witaj ponownie',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: AppColors.slate950,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  _isRegister
                                      ? 'Zarejestruj nowe konto w GargaGym'
                                      : 'Zaloguj sie do GargaGym',
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SegmentedButton<AuthMode>(
                        segments: const [
                          ButtonSegment(
                            value: AuthMode.login,
                            label: Text('Logowanie'),
                            icon: Icon(Icons.login),
                          ),
                          ButtonSegment(
                            value: AuthMode.register,
                            label: Text('Utworz konto'),
                            icon: Icon(Icons.person_add_alt),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _mode = selection.first;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      if (_isRegister) ...[
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Imie i nazwisko',
                            hintText: 'Jan Kowalski',
                          ),
                          validator: (value) =>
                              _isRegister &&
                                  (value == null || value.trim().isEmpty)
                              ? 'Imie i nazwisko jest wymagane.'
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
                          hintText: 'jan@example.com',
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) {
                            return 'Email jest wymagany.';
                          }
                          if (!email.contains('@')) {
                            return 'Podaj poprawny email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: _isRegister
                            ? TextInputAction.next
                            : TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Haslo',
                          hintText: 'Twoje haslo',
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Pokaz haslo'
                                : 'Ukryj haslo',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Haslo jest wymagane.';
                          }
                          if (_isRegister && value!.length < 8) {
                            return 'Haslo musi miec minimum 8 znakow.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (!_isRegister) {
                            _submit();
                          }
                        },
                      ),
                      if (_isRegister) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordConfirmationController,
                          obscureText: _obscureConfirmation,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Powtorz haslo',
                            hintText: 'Powtorz haslo',
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmation
                                  ? 'Pokaz haslo'
                                  : 'Ukryj haslo',
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (!_isRegister) {
                              return null;
                            }
                            if (value != _passwordController.text) {
                              return 'Hasla musza byc takie same.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: controller.loading ? null : _submit,
                        child: Text(
                          controller.loading
                              ? (_isRegister
                                    ? 'Tworzenie konta...'
                                    : 'Logowanie...')
                              : (_isRegister ? 'Utworz konto' : 'Zaloguj'),
                        ),
                      ),
                      if (_error != null || controller.error != null) ...[
                        const SizedBox(height: 14),
                        _ErrorMessage(message: _error ?? controller.error!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffff1f2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffffcdd2)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xff9f1239),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
