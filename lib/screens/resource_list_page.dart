// ============================================================
// resource_list_page.dart — Écran Catalogue des ressources
// (RE)Sources Relationnelles
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/resource_card.dart';
import 'resource_detail_page.dart';

class ResourceListPage extends StatefulWidget {
  final bool openSearch;
  const ResourceListPage({super.key, this.openSearch = false});

  @override
  State<ResourceListPage> createState() => _ResourceListPageState();
}

class _ResourceListPageState extends State<ResourceListPage> {
  int _selectedCategoryIndex = 0;
  String? _selectedType;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showSearch = false;

  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  List<MockResource> _allResources = [];
  // Catégories avec icône (index 0 = "Toutes")
  List<MockCategory> _filterCategories = [
    const MockCategory(id: -1, label: 'Toutes', icon: Icons.apps_rounded),
  ];
  bool _isLoading = true;

  static const List<Map<String, dynamic>> _typeFilters = [
    {'label': 'Article', 'icon': Icons.article_outlined},
    {'label': 'Video', 'icon': Icons.play_circle_outline_rounded},
    {'label': 'Podcast', 'icon': Icons.podcasts_rounded},
    {'label': 'Exercice', 'icon': Icons.fitness_center_rounded},
    {'label': 'Jeu', 'icon': Icons.sports_esports_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChange);
    _loadData();
    if (widget.openSearch) {
      _showSearch = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _auth.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _api.fetchResources(),
      _api.fetchCategories(),
    ]);

    final resources = results[0] as List<MockResource>;
    final categories = results[1] as List<MockCategory>;

    setState(() {
      _allResources = resources;
      _filterCategories = [
        const MockCategory(id: -1, label: 'Toutes', icon: Icons.apps_rounded),
        ...categories,
      ];
      _isLoading = false;
    });
  }

  /// Ressources filtrees selon la recherche, la categorie, le type et le role.
  List<MockResource> get _filteredResources {
    final canSeePrivate = _auth.isLoggedIn;
    final query = _searchQuery.toLowerCase().trim();
    final selectedCat = _filterCategories[_selectedCategoryIndex];
    return _allResources.where((r) {
      if (r.status != 'publie') return false; // catalogue = publiées seulement
      final categoryMatch = selectedCat.id == -1 || r.category == selectedCat.label;
      final typeMatch = _selectedType == null || r.type == _selectedType;
      final visibilityMatch = canSeePrivate || r.visibility == 'Public';
      final searchMatch = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query) ||
          r.category.toLowerCase().contains(query) ||
          r.author.toLowerCase().contains(query);
      return categoryMatch && typeMatch && visibilityMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredResources;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(filtered.length),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : filtered.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) => ResourceCard(
                  resource: filtered[index],
                  compact: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ResourceDetailPage(
                        resource: filtered[index],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // App Bar : titre fixe + filtres dans bottom
  // ------------------------------------------------------------------
  SliverAppBar _buildSliverAppBar(int count) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: AppColors.primary,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(_showSearch ? 152 : 116),
        child: _buildFiltersArea(count),
      ),
      title: _showSearch
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppColors.white),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.6)),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : const Text(
              'Catalogue',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
      actions: [
        IconButton(
          tooltip: _showSearch ? 'Fermer' : 'Rechercher',
          icon: Icon(
            _showSearch ? Icons.close_rounded : Icons.search_rounded,
            color: AppColors.white,
          ),
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) {
              _searchQuery = '';
              _searchController.clear();
            }
          }),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF163A5F)],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Filtres : sous-titre + chips catégories + chips types
  // ------------------------------------------------------------------
  Widget _buildFiltersArea(int count) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sous-titre avec badge résultats
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              '$count ressource${count > 1 ? 's' : ''} disponible${count > 1 ? 's' : ''}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Ligne 1 : chips de catégories avec emoji
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filterCategories.length,
              itemBuilder: (context, index) {
                final cat = _filterCategories[index];
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategoryIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.white.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: AppColors.white.withValues(alpha:0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 13,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat.label,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Ligne 2 : filtres de type (toggle)
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _typeFilters.length,
              itemBuilder: (context, index) {
                final type = _typeFilters[index];
                final isSelected = _selectedType == type['label'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedType =
                          isSelected ? null : type['label'] as String;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.white.withValues(alpha:0.22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha:0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            size: 12,
                            color: AppColors.white.withValues(alpha:
                              isSelected ? 1.0 : 0.65,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha:
                                isSelected ? 1.0 : 0.65,
                              ),
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // État vide : aucun résultat
  // ------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text(
            'Aucune ressource\npour ces filtres',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _selectedCategoryIndex = 0;
              _selectedType = null;
            }),
            child: const Text('Réinitialiser les filtres'),
          ),
        ],
      ),
    );
  }
}
