// ============================================================
// statistics_page.dart — Tableau de bord statistiques
// FS3 + RG-STAT-01 (anonymat, agregation)
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _api = ApiService();
  final _storage = StorageService();

  List<MockResource> _resources = [];
  List<MockCategory> _categories = [];
  String _periodFilter = 'Toutes';
  String _categoryFilter = 'Toutes';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.fetchResources(),
      _api.fetchCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _resources = results[0] as List<MockResource>;
      _categories = results[1] as List<MockCategory>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _storage.progressionStats();
    final totalResources = _resources.length;

    // Repartition par categorie
    final Map<String, int> perCategory = {};
    for (final r in _resources) {
      perCategory[r.category] = (perCategory[r.category] ?? 0) + 1;
    }

    final Map<String, int> perType = {};
    for (final r in _resources) {
      perType[r.type] = (perType[r.type] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Exporter CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _showExport('CSV'),
          ),
          IconButton(
            tooltip: 'Exporter PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _showExport('PDF'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildFilters(),
                const SizedBox(height: 20),
                _buildKpiRow(totalResources, stats),
                const SizedBox(height: 20),
                _buildSection(
                  'Ressources par categorie',
                  _buildBarList(perCategory, AppColors.primary),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'Ressources par type',
                  _buildBarList(perType, AppColors.accent),
                ),
                const SizedBox(height: 20),
                _buildAnonymityNotice(),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildFilters() {
    final periods = ['Toutes', '7 jours', '30 jours', '90 jours'];
    final cats = ['Toutes', ..._categories.map((c) => c.label)];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _filterChip(
          label: 'Periode : $_periodFilter',
          onTap: () => _pickFilter(
            title: 'Periode',
            values: periods,
            current: _periodFilter,
            onSelected: (v) => setState(() => _periodFilter = v),
          ),
        ),
        _filterChip(
          label: 'Categorie : $_categoryFilter',
          onTap: () => _pickFilter(
            title: 'Categorie',
            values: cats,
            current: _categoryFilter,
            onSelected: (v) => setState(() => _categoryFilter = v),
          ),
        ),
      ],
    );
  }

  Widget _filterChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDE2EA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFilter({
    required String title,
    required List<String> values,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
            ...values.map(
              (v) => ListTile(
                title: Text(v),
                trailing: v == current
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelected(v);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildKpiRow(int totalResources, Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            icon: Icons.library_books_rounded,
            label: 'Ressources',
            value: totalResources.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            icon: Icons.remove_red_eye_rounded,
            label: 'Consultees',
            value: (stats['vues'] ?? 0).toString(),
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            icon: Icons.check_circle_rounded,
            label: 'Exploitees',
            value: (stats['exploitees'] ?? 0).toString(),
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  Widget _buildSection(String title, Widget content) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _buildBarList(Map<String, int> data, Color color) {
    if (data.isEmpty) {
      return const Text(
        'Aucune donnee disponible',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      );
    }
    final total = data.values.reduce((a, b) => a + b).clamp(1, 1 << 31);
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: sorted.map((e) {
        final ratio = e.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${e.value}',
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnonymityNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'RG-STAT-01 : toutes les donnees affichees sont agregees et anonymisees. '
              'Aucune consultation ne peut etre reliee a un utilisateur identifie.',
              style: TextStyle(
                color: AppColors.info,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export $format prepare (prototype)'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
