// ============================================================
// moderation_page.dart — Interface de moderation
// FP4 (workflow validation) + RG-COM-01 (commentaires signales)
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _storage = StorageService();

  late final TabController _tab;
  List<MockResource> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _storage.addListener(_onChange);
    _loadPending();
  }

  @override
  void dispose() {
    _tab.dispose();
    _storage.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPending() async {
    setState(() => _loading = true);
    final result = await _api.fetchPendingResources();
    if (!mounted) return;
    setState(() {
      _pending = result;
      _loading = false;
    });
  }

  Future<void> _validate(MockResource r) async {
    final id = int.tryParse(r.id);
    if (id == null) return;
    final ok = await _api.validateResource(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Ressource publiee' : 'Validation impossible'),
        backgroundColor: ok ? AppColors.success : const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) _loadPending();
  }

  Future<void> _suspend(MockResource r) async {
    final id = int.tryParse(r.id);
    if (id == null) return;
    final ok = await _api.suspendResource(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Ressource suspendue' : 'Suspension impossible'),
        backgroundColor: ok ? AppColors.warning : const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) _loadPending();
  }

  @override
  Widget build(BuildContext context) {
    final flagged = _storage.flaggedComments();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Moderation'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white,
          tabs: [
            Tab(text: 'Ressources (${_pending.length})'),
            Tab(text: 'Signalements (${flagged.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildPendingTab(),
          _buildFlaggedTab(flagged),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pending.isEmpty) {
      return _emptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Aucune ressource en attente',
        subtitle: 'Toutes les contributions ont ete traitees.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPending,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildPendingCard(_pending[i]),
      ),
    );
  }

  Widget _buildPendingCard(MockResource r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'En attente',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${r.id}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            r.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _suspend(r),
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB71C1C),
                    side: const BorderSide(color: Color(0xFFB71C1C)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _validate(r),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Publier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlaggedTab(List<Comment> flagged) {
    if (flagged.isEmpty) {
      return _emptyState(
        icon: Icons.flag_outlined,
        title: 'Aucun commentaire signale',
        subtitle:
            'Les commentaires signales ${StorageService.reportThreshold}+ fois apparaitront ici.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: flagged.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildFlaggedCard(flagged[i]),
    );
  }

  Widget _buildFlaggedCard(Comment c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
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
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFB71C1C),
                child: Text(
                  c.author.isNotEmpty ? c.author[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.author,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${c.reportCount} signalement${c.reportCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            c.text,
            style: const TextStyle(
                color: AppColors.textDark, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _storage.deleteComment(c.id),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB71C1C),
                    side: const BorderSide(color: Color(0xFFB71C1C)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
