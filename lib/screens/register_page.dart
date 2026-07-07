// ============================================================
// register_page.dart — Écran d'inscription
// (RE)Sources Relationnelles
// Identique à l'app web : prénom/nom, rôle, mdp x2 + RGPD
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'login_page.dart' show inputDecoration;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _confirmController   = TextEditingController();

  String _selectedRole = 'parent';
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _isLoading       = false;
  bool _acceptTerms     = false;
  bool _acceptRGPD      = false;
  bool _submitted       = false;

  static const List<Map<String, String>> _roles = [
    {'value': 'parent',         'label': 'Parent'},
    {'value': 'educateur',      'label': 'Éducateur'},
    {'value': 'professionnel',  'label': 'Professionnel'},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Valide le mot de passe : min 8 car., 1 majuscule, 1 chiffre
  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Veuillez entrer un mot de passe';
    if (v.length < 8) return 'Minimum 8 caractères';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Au moins 1 lettre majuscule';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Au moins 1 chiffre';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms || !_acceptRGPD) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Vous devez accepter les conditions et la politique RGPD."),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();
      await AuthService().register(
        name: fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String message = e.toString().replaceFirst('Exception: ', '');
      if (message.toLowerCase().contains('password')) {
        message =
            'Le mot de passe ne respecte pas les critères (min. 8 caractères, 1 majuscule, 1 chiffre).';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _submitted ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildSuccess() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.success),
          SizedBox(height: 20),
          Text(
            'Inscription réussie !',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Votre compte a été créé.\nRedirection en cours…',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // ---- Bouton retour ----
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textDark, size: 20),
          ),
        ),
        const SizedBox(height: 28),

        // ---- Titre ----
        const Text(
          'Créer un compte',
          style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Rejoignez la communauté (RE)Sources Relationnelles.',
          style:
              TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),

        // ---- Formulaire ----
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Prénom + Nom côte à côte
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: inputDecoration(
                        label: 'Prénom *',
                        hint: 'Jean',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requis'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: inputDecoration(
                        label: 'Nom *',
                        hint: 'Dupont',
                        icon: Icons.badge_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requis'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: inputDecoration(
                  label: 'Adresse e-mail *',
                  hint: 'jean@example.com',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (!v.contains('@')) return 'E-mail invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rôle
              _buildRoleDropdown(),
              const SizedBox(height: 16),

              // Mot de passe
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: inputDecoration(
                  label: 'Mot de passe *',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  helperText: 'Min. 8 caractères, 1 majuscule, 1 chiffre',
                  helperStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),

              // Confirmation mot de passe
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleRegister(),
                decoration: inputDecoration(
                  label: 'Confirmer le mot de passe *',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Veuillez confirmer votre mot de passe';
                  if (v != _passwordController.text)
                    return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ---- Checkboxes CGU + RGPD ----
        _buildCheckbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v),
          label: "J'accepte les conditions d'utilisation",
        ),
        const SizedBox(height: 10),
        _buildCheckbox(
          value: _acceptRGPD,
          onChanged: (v) => setState(() => _acceptRGPD = v),
          label:
              "J'accepte la politique de confidentialité et le traitement de mes données (RGPD)",
        ),
        const SizedBox(height: 32),

        // ---- Bouton S'inscrire ----
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2.5),
                  )
                : const Text("S'inscrire",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 24),

        // ---- Lien connexion ----
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Déjà un compte ? ',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Text(
                'Se connecter',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ------------------------------------------------------------------
  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Rôle',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE2EA)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted),
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              onChanged: (v) => setState(() => _selectedRole = v!),
              items: _roles
                  .map((r) => DropdownMenuItem(
                        value: r['value'],
                        child: Text(r['label']!),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String label,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.primary : const Color(0xFFDDE2EA),
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded,
                    color: AppColors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
