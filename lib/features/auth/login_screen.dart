import 'package:flutter/material.dart';
import 'package:kichub_loca/core/services/auth_prefs_service.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';
import 'package:kichub_loca/core/services/stats_service.dart';
import 'package:kichub_loca/core/widgets/liquid_glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isCreateAccount = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreSavedCredentials();
  }

  Future<void> _restoreSavedCredentials() async {
    final saved = await AuthPrefsService.load();
    if (saved == null) return;
    if (!mounted) return;

    _emailController.text = saved.email;
    _passwordController.text = saved.password;
    setState(() => _rememberMe = true);

    if (SupabaseService.currentUser != null) return;

    try {
      await SupabaseService.signInWithPassword(
        email: saved.email,
        password: saved.password,
      );
    } catch (_) {
      // Session invalide : rester sur l'écran de connexion (champs préremplis).
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _passwordStrength(String value) {
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }

  (String label, Color color, double level) _strengthHint(String value) {
    final s = _passwordStrength(value);
    if (value.isEmpty) return ('', const Color(0x00000000), 0);
    if (s <= 2) return ('Faible', const Color(0xFFF87171), 0.2);
    if (s <= 4) return ('Moyen', const Color(0xFFFBBF24), 0.5);
    return ('Fort', const Color(0xFF34D399), 1.0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isCreateAccount) {
        if (_nomController.text.trim().isEmpty) {
          throw Exception('Le nom est requis.');
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception('Les mots de passe ne correspondent pas.');
        }
        if (_passwordStrength(_passwordController.text) <= 2) {
          throw Exception('Mot de passe trop faible.');
        }

        final emailExists = await StatsService.emailExists(
          _emailController.text,
        );
        if (emailExists) {
          throw Exception('Un compte existe déjà avec cet email.');
        }

        await SupabaseService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          nom: _nomController.text.trim(),
        );

        if (_rememberMe) {
          await AuthPrefsService.save(
            email: _emailController.text,
            password: _passwordController.text,
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Compte créé. Vérifie ton email pour confirmer l\'inscription.',
            ),
          ),
        );
        setState(() => _isCreateAccount = false);
      } else {
        await SupabaseService.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (_rememberMe) {
          await AuthPrefsService.save(
            email: _emailController.text,
            password: _passwordController.text,
          );
        } else {
          await AuthPrefsService.clear();
        }
      }
    } on Exception catch (error) {
      if (!mounted) return;
      final msg = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = _isCreateAccount
            ? 'Création impossible : $msg'
            : 'Connexion impossible : $msg';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Entre ton email pour réinitialiser.');
      return;
    }

    try {
      await SupabaseService.resetPassword(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de réinitialisation envoyé.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF1D4ED8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: LiquidGlassCard(
                  borderRadius: 28,
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            isCreateAccount: _isCreateAccount,
                            email: _emailController.text,
                          ),
                          const SizedBox(height: 26),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _isCreateAccount
                                ? Column(
                                    key: const ValueKey('create'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildField(
                                        controller: _nomController,
                                        label: 'Nom complet',
                                        icon: Icons.person_outline,
                                        hint: 'Ton nom et prénom',
                                        textCapitalization:
                                            TextCapitalization.words,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Nom requis';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildField(
                                        controller: _emailController,
                                        label: 'Email professionnel',
                                        icon: Icons.email_outlined,
                                        hint: 'nom@exemple.com',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: _validateEmail,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildPasswordField(
                                        controller: _passwordController,
                                        label: 'Mot de passe',
                                        icon: Icons.lock_outline,
                                        obscure: _obscurePassword,
                                        onToggle: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Mot de passe requis';
                                          }
                                          if (value.length < 6) {
                                            return 'Au moins 6 caractères';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      _PasswordStrengthBar(
                                        value: _passwordController.text,
                                        getHint: _strengthHint,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildPasswordField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirmer le mot de passe',
                                        icon: Icons.lock_reset_rounded,
                                        obscure: _obscureConfirm,
                                        onToggle: () => setState(
                                          () => _obscureConfirm =
                                              !_obscureConfirm,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Confirmation requise';
                                          }
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Les mots de passe ne correspondent pas';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey('login'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildField(
                                        controller: _emailController,
                                        label: 'Email',
                                        icon: Icons.email_outlined,
                                        hint: 'nom@exemple.com',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: _validateEmail,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildPasswordField(
                                        controller: _passwordController,
                                        label: 'Mot de passe',
                                        icon: Icons.lock_outline,
                                        obscure: _obscurePassword,
                                        onToggle: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Mot de passe requis';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 18),
                          if (_errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(
                                    () => _rememberMe = value ?? false,
                                  );
                                },
                                activeColor: Colors.white,
                                checkColor: const Color(0xFF0F172A),
                              ),
                              const Expanded(
                                child: Text(
                                  'Se souvenir de moi (connexion automatique)',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isCreateAccount
                                        ? Icons.person_add_alt_1_rounded
                                        : Icons.login_rounded,
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            label: Text(
                              _isLoading
                                  ? (_isCreateAccount
                                      ? 'Création...'
                                      : 'Connexion...')
                                  : (_isCreateAccount
                                      ? 'Créer le compte'
                                      : 'Se connecter'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  _isCreateAccount
                                      ? 'Déjà un compte ?'
                                      : 'Nouveau sur Kichub Loca ?',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isCreateAccount = !_isCreateAccount;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              _isCreateAccount
                                  ? 'Se connecter'
                                  : 'Créer un compte agent',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!_isCreateAccount)
                            TextButton(
                              onPressed: _forgotPassword,
                              child: const Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email requis';
    }
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!re.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? hint,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.white60,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isCreateAccount, required this.email});

  final bool isCreateAccount;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            size: 34,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey(isCreateAccount),
            children: [
              Text(
                isCreateAccount ? 'Créer un compte' : 'Kichub Loca',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                isCreateAccount
                    ? 'Rejoins l\'équipe de prospection terrain'
                    : 'Prospection terrain',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.value, required this.getHint});

  final String value;
  final (String, Color, double) Function(String) getHint;

  @override
  Widget build(BuildContext context) {
    final (label, color, level) = getHint(value);
    if (level <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: level,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Robustesse: $label',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}