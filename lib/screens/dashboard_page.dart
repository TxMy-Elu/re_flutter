// ============================================================
// dashboard_page.dart — Tableau de bord personnel
// Mes ressources (créées) + Mes favoris depuis l'API
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'resource_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _auth = AuthService();

  late final TabController _tabController;

  List<MockResource> _myResources = [];
  List<MockResource> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _auth.addListener(_onAuthChange);
    if (_auth.isLoggedIn) _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _auth.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) {
      setState(() {});
      if (_auth.isLoggedIn) _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.fetchMyResources(),
      _api.fetchFavorites(),
    ]);
    if (!mounted) return;
    setState(() {
      _myResources = results[0];
      _favorites = results[1];
      _loading = false;
    });
  }

  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (!_auth.isLoggedIn) {
      return _buildNotLoggedIn(context);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(context),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildMyResources(),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildFavorites(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  SliverAppBar _buildAppBar(BuildContext context) {
    final published = _myResources.where((r) => r.status == 'publie').length;
    final pending = _myResources.where((r) => r.status == 'en attente').length;

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accent,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: [
          Tab(text: 'Mes ressources (${_myResources.length})'),
          Tab(text: 'Mes favoris (${_favorites.length})'),
        ],
      ),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tableau de bord',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_loading)
                    Row(
                      children: [
                        _StatBadge(
                          count: _myResources.length,
                          label: 'Créées',
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 10),
                        _StatBadge(
                          count: published,
                          label: 'Publiées',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        _StatBadge(
                          count: pending,
                          label: 'En attente',
                          color: AppColors.accent,
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

  // ------------------------------------------------------------------
  Widget _buildMyResources() {
    if (_myResources.isEmpty) {
      return _buildEmpty(
        icon: Icons.library_books_outlined,
        message: 'Vous n\'avez pas encore créé de ressource.',
        sub: 'Les ressources que vous publiez apparaîtront ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myResources.length,
        itemBuilder: (_, i) {
          final r = _myResources[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ResourceRow(
              resource: r,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ResourceDetailPage(resource: r)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildFavorites() {
    if (_favorites.isEmpty) {
      return _buildEmpty(
        icon: Icons.favorite_border_rounded,
        message: 'Aucun favori pour l\'instant.',
        sub: 'Appuyez sur le cœur dans une ressource pour l\'enregistrer ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (_, i) {
          final r = _favorites[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ResourceRow(
              resource: r,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ResourceDetailPage(resource: r)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildEmpty({
    required IconData icon,
    required String message,
    required String sub,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildNotLoggedIn(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dashboard_outlined,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Connexion requise',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Connectez-vous pour accéder à vos ressources et favoris.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Sous-widgets
// ------------------------------------------------------------------

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final MockResource resource;
  final VoidCallback onTap;

  const _ResourceRow({required this.resource, required this.onTap});

  Color get _statusColor {
    switch (resource.status) {
      case 'publie':
        return AppColors.success;
      case 'en attente':
        return AppColors.accent;
      case 'suspendu':
        return const Color(0xFFB71C1C);
      default:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (resource.status) {
      case 'publie':
        return 'Publié';
      case 'en attente':
        return 'En attente';
      case 'suspendu':
        return 'Suspendu';
      case 'brouillon':
        return 'Brouillon';
      default:
        return resource.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Icone type
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(resource.type),
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            // Titre + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${resource.category} · ${resource.type}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Statut badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'podcast':
        return Icons.podcasts_rounded;
      case 'exercice':
      case 'activite':
        return Icons.fitness_center_rounded;
      case 'jeu':
        return Icons.sports_esports_rounded;
      default:
        return Icons.article_outlined;
    }
  }
}
