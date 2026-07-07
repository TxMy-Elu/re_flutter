// ============================================================
// profile_page.dart — Ecran Profil utilisateur
// Favoris reels + acces role-based aux outils pro
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/resource_card.dart';
import 'forgot_password_page.dart';
import 'help_page.dart';
import 'login_page.dart';
import 'resource_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService();
  final _storage = StorageService();
  final _api = ApiService();

  List<MockResource> _allResources = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onChange);
    _storage.addListener(_onChange);
    _load();
  }

  @override
  void dispose() {
    _auth.removeListener(_onChange);
    _storage.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final res = await _api.fetchResources();
    if (!mounted) return;
    setState(() {
      _allResources = res;
      _loading = false;
    });
  }

  List<MockResource> get _favorites {
    final ids = _storage.favoriteIds;
    return _allResources.where((r) => ids.contains(r.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Favoris reels
                  _buildSectionTitle(context, 'Mes favoris'),
                  const SizedBox(height: 14),
                  _buildFavorites(),
                  const SizedBox(height: 28),

                  // Preferences
                  _buildSectionTitle(context, 'Parametres'),
                  const SizedBox(height: 14),
                  _buildPreferences(context),
                  const SizedBox(height: 28),

                  _buildLogoutButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildSliverHeader(BuildContext context) {
    final user = _auth.user;
    final name = user?.name ?? 'Visiteur';
    final email = user?.email ?? 'Non connecte';
    final initials = user?.initials ?? '?';
    final roleLabel = _auth.role.label;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF163A5F)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Mon Profil',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Aide',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const HelpPage()),
                        ),
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                roleLabel,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 18,
              ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  Future<void> _showPrivacyDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Confidentialité & RGPD',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: const Icon(Icons.close_rounded, color: AppColors.white, size: 20),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _privacySection(
                icon: Icons.storage_rounded,
                title: 'Données collectées',
                body:
                    'Nous collectons uniquement les données nécessaires au fonctionnement de l\'application : nom, adresse e-mail, ressources créées et commentaires.',
              ),
              const SizedBox(height: 16),
              _privacySection(
                icon: Icons.lock_rounded,
                title: 'Sécurité',
                body:
                    'Vos données sont chiffrées en transit (HTTPS) et au repos. Vos mots de passe ne sont jamais stockés en clair.',
              ),
              const SizedBox(height: 16),
              _privacySection(
                icon: Icons.share_rounded,
                title: 'Partage des données',
                body:
                    'Vos données ne sont jamais vendues ni partagées avec des tiers à des fins commerciales. Elles restent hébergées en France.',
              ),
              const SizedBox(height: 16),
              _privacySection(
                icon: Icons.manage_accounts_rounded,
                title: 'Vos droits (RGPD)',
                body:
                    '• Droit d\'accès à vos données personnelles\n'
                    '• Droit de rectification\n'
                    '• Droit à l\'effacement (droit à l\'oubli)\n'
                    '• Droit à la portabilité\n\n'
                    'Pour exercer vos droits, contactez : rgpd@ressources-relationnelles.fr',
              ),
              const SizedBox(height: 16),
              _privacySection(
                icon: Icons.cookie_outlined,
                title: 'Cookies',
                body:
                    'L\'application utilise uniquement des cookies fonctionnels nécessaires à votre session. Aucun cookie publicitaire ou de tracking tiers.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _privacySection({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  Widget _buildFavorites() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final favs = _favorites;
    if (favs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.favorite_border_rounded,
                  size: 36, color: AppColors.textMuted),
              SizedBox(height: 8),
              Text(
                'Aucun favori pour l\'instant',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Ajoutez des ressources avec le coeur pour les retrouver ici.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: favs.map((resource) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ResourceCard(
            resource: resource,
            compact: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResourceDetailPage(resource: resource),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildPreferences(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_auth.isLoggedIn)
            _PreferenceItem(
              icon: Icons.lock_reset_rounded,
              label: 'Mot de passe oublié',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
              ),
            ),
          if (_auth.isLoggedIn) _divider(),
          const _PreferenceItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            trailing: Switch(
              value: true,
              onChanged: null,
              activeColor: AppColors.primary,
            ),
          ),
          _divider(),
          const _PreferenceItem(
            icon: Icons.language_rounded,
            label: 'Langue',
            trailing: Text(
              'Francais',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          _divider(),
          _PreferenceItem(
            icon: Icons.lock_outline_rounded,
            label: 'Confidentialité & RGPD',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: () => _showPrivacyDialog(context),
          ),
          _divider(),
          _PreferenceItem(
            icon: Icons.help_outline_rounded,
            label: 'Aide & Support',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Color(0xFFF0F2F5),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildLogoutButton(BuildContext context) {
    final loggedIn = _auth.isLoggedIn;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          if (loggedIn) await _auth.logout();
          if (!mounted) return;
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        },
        icon: Icon(
          loggedIn ? Icons.logout_rounded : Icons.login_rounded,
          size: 18,
          color: loggedIn ? const Color(0xFFB71C1C) : AppColors.primary,
        ),
        label: Text(
          loggedIn ? 'Se deconnecter' : 'Se connecter',
          style: TextStyle(
            color: loggedIn ? const Color(0xFFB71C1C) : AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              loggedIn ? const Color(0xFFB71C1C) : AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: loggedIn ? const Color(0xFFB71C1C) : AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _PreferenceItem({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
