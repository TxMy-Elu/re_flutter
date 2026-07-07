// ============================================================
// home_page.dart — Ecran d'accueil
// (RE)Sources Relationnelles
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/resource_card.dart';
import '../widgets/category_chip.dart';
import 'help_page.dart';
import 'resource_detail_page.dart';
import 'resource_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedCategoryIndex = -1;

  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  List<MockResource> _resources = [];
  List<MockCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onChange);
    _loadData();
  }

  @override
  void dispose() {
    _auth.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _api.fetchResources(),
      _api.fetchCategories(),
    ]);

    final resources = results[0] as List<MockResource>;
    final categories = results[1] as List<MockCategory>;

    if (!mounted) return;
    setState(() {
      _resources = resources;
      _categories = categories;
      _isLoading = false;
    });
  }

  /// Ressources publiées, filtrées par catégorie sélectionnée.
  List<MockResource> get _filteredFeatured {
    final published = _resources.where((r) => r.status == 'publie').toList();
    if (_selectedCategoryIndex < 0) return published;
    final cat = _categories[_selectedCategoryIndex].label;
    return published.where((r) => r.category == cat).toList();
  }

  void _openDetail(MockResource r) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResourceDetailPage(resource: r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSearchBar(context),
                const SizedBox(height: 28),

                // ---- Section Categories ----
                _buildSectionHeader(context, 'Categories', null),
                const SizedBox(height: 14),
                CategoryChipsRow(
                  categories: _categories,
                  selectedIndex: _selectedCategoryIndex,
                  onSelected: (index) => setState(() {
                    _selectedCategoryIndex =
                        _selectedCategoryIndex == index ? -1 : index;
                  }),
                ),
                const SizedBox(height: 28),

                // ---- Ressources a la une ----
                _buildSectionHeader(
                    context, 'Ressources a la une', 'Tout voir'),
                const SizedBox(height: 14),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_filteredFeatured.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Center(
                      child: Text(
                        'Aucune ressource dans cette catégorie.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  _buildFeaturedList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildSliverAppBar(BuildContext context) {
    final user = _auth.user;
    final greeting = user != null ? 'Bonjour, ${user.name.split(' ').first}' : 'Bienvenue';
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          tooltip: 'Aide',
          icon: const Icon(Icons.help_outline_rounded, color: AppColors.white),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HelpPage()),
          ),
        ),
      ],
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'RE',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '(RE)Sources',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Relationnelles',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _auth.role.short,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ResourceListPage(openSearch: true),
          ),
        ),
        child: Container(
          height: 50,
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
              const SizedBox(width: 16),
              const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 22),
              const SizedBox(width: 12),
              Text(
                'Rechercher une ressource...',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 15),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: AppColors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String? linkLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
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
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 18),
          ),
          if (linkLabel != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ResourceListPage(),
                ),
              ),
              child: const Text(
                'Tout voir',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturedList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _filteredFeatured.map((resource) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ResourceCard(
              resource: resource,
              compact: true,
              onTap: () => _openDetail(resource),
            ),
          );
        }).toList(),
      ),
    );
  }

}
