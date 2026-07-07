// ============================================================
// notifications_page.dart — Centre de notifications
// FS4 : Notifications d'evenements (commentaire, validation, publication)
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';
import '../services/storage_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _storage = StorageService();

  List<AppNotification> get _notifications => [
        AppNotification(
          id: 'n1',
          kind: 'validation',
          title: 'Ressource publiee',
          message: 'Votre ressource "Rituels du soir en famille" a ete validee par un moderateur.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: 'n2',
          kind: 'comment',
          title: 'Nouveau commentaire',
          message: 'Camille a reagi a votre ressource "Mieux communiquer en famille".',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        AppNotification(
          id: 'n3',
          kind: 'publication',
          title: 'Nouvelle ressource dans Bien-etre',
          message: 'Decouvrez "La meditation de pleine conscience", ajoutee aujourd\'hui.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        AppNotification(
          id: 'n4',
          kind: 'publication',
          title: 'Bienvenue sur (RE)Sources Relationnelles',
          message: 'Explorez le catalogue, ajoutez des favoris et suivez votre progression.',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _storage.addListener(_onChange);
  }

  @override
  void dispose() {
    _storage.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = _notifications;
    final unreadCount =
        list.where((n) => !_storage.isNotificationRead(n.id)).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () async {
                for (final n in list) {
                  await _storage.markNotificationRead(n.id);
                }
              },
              child: const Text(
                'Tout lire',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildNotificationTile(list[i]),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification n) {
    final read = _storage.isNotificationRead(n.id);
    final color = _colorFor(n.kind);
    final icon = _iconFor(n.kind);
    return InkWell(
      onTap: () => _storage.markNotificationRead(n.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: read
              ? null
              : Border.all(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  width: 1.2,
                ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight:
                                read ? FontWeight.w600 : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(n.createdAt),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(String kind) {
    switch (kind) {
      case 'validation':
        return AppColors.success;
      case 'comment':
        return AppColors.info;
      default:
        return AppColors.accent;
    }
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'validation':
        return Icons.verified_rounded;
      case 'comment':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.campaign_outlined;
    }
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "a l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return '${d.day}/${d.month}/${d.year}';
  }
}
