// ============================================================
// resource_card.dart — Widget réutilisable : carte ressource
// (RE)Sources Relationnelles
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';

/// Carte ressource complète — utilisée dans le catalogue
class ResourceCard extends StatelessWidget {
  final MockResource resource;
  final bool compact; // Version compacte pour les favoris / à la une
  final VoidCallback? onTap;

  const ResourceCard({
    super.key,
    required this.resource,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: compact ? _buildCompact(context) : _buildFull(context),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Version complète (Catalogue)
  // ------------------------------------------------------------------
  Widget _buildFull(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne : catégorie + visibilité
          Row(
            children: [
              _CategoryBadge(category: resource.category),
              const SizedBox(width: 8),
              _VisibilityBadge(visibility: resource.visibility),
            ],
          ),
          const SizedBox(height: 10),

          // Titre
          Text(
            resource.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            resource.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Pied : type + auteur + bouton Voir
          Row(
            children: [
              _TypeChip(type: resource.type),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resource.author,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _SeeButton(),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Version compacte (À la une / Favoris)
  // ------------------------------------------------------------------
  Widget _buildCompact(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône de type
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                _typeIcon(resource.type),
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryBadge(category: resource.category, small: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  resource.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  resource.author,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Video':
      case 'Vidéo':
        return Icons.play_circle_outline_rounded;
      case 'Exercice':
      case 'Activite':
      case 'Activité':
        return Icons.fitness_center_rounded;
      case 'Podcast':
        return Icons.podcasts_rounded;
      case 'Jeu':
        return Icons.sports_esports_rounded;
      default:
        return Icons.article_outlined;
    }
  }
}

// ------------------------------------------------------------------
// Sous-widgets internes
// ------------------------------------------------------------------

/// Badge de catégorie coloré
class _CategoryBadge extends StatelessWidget {
  final String category;
  final bool small;

  const _CategoryBadge({required this.category, this.small = false});

  Color _color() {
    switch (category) {
      case 'Famille':
        return const Color(0xFF7B1FA2);
      case 'Couple':
        return const Color(0xFFC62828);
      case 'Travail':
        return const Color(0xFF1565C0);
      case 'Amis':
      case 'Amitie':
      case 'Amitié':
        return const Color(0xFF2E7D32);
      case 'Bien-etre':
      case 'Bien-être':
        return const Color(0xFF00695C);
      case 'Parentalite':
      case 'Parentalité':
        return const Color(0xFFE65100);
      case 'Developpement personnel':
      case 'Développement personnel':
        return const Color(0xFF5E35B1);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 9,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _color().withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: _color(),
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Badge de visibilité (Public / Privé / Partagé)
class _VisibilityBadge extends StatelessWidget {
  final String visibility;

  const _VisibilityBadge({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final isPublic = visibility == 'Public';
    final isShared = visibility == 'Partage' || visibility == 'Partagé';
    final icon = isPublic
        ? Icons.public_rounded
        : (isShared ? Icons.group_outlined : Icons.lock_outline_rounded);
    final color = isPublic
        ? const Color(0xFF1565C0)
        : (isShared ? const Color(0xFF00695C) : const Color(0xFF455A64));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            visibility,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de progression (À voir / Consulté / Exploité)
class _ProgressBadge extends StatelessWidget {
  final String status;
  final bool small;

  const _ProgressBadge({required this.status, this.small = false});

  Color _color() {
    switch (status) {
      case 'Exploite':
      case 'Exploité':
        return AppColors.success;
      case 'Consulte':
      case 'Consulté':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  IconData _icon() {
    switch (status) {
      case 'Exploite':
      case 'Exploité':
        return Icons.check_circle_rounded;
      case 'Consulte':
      case 'Consulté':
        return Icons.remove_red_eye_rounded;
      default:
        return Icons.bookmark_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: small ? 10 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de type de ressource (Article / Vidéo / Exercice)
class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  IconData _icon() {
    switch (type) {
      case 'Video':
      case 'Vidéo':
        return Icons.play_circle_outline_rounded;
      case 'Exercice':
      case 'Activite':
      case 'Activité':
        return Icons.fitness_center_rounded;
      case 'Podcast':
        return Icons.podcasts_rounded;
      case 'Jeu':
        return Icons.sports_esports_rounded;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            type,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton "Voir" non fonctionnel
class _SeeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: null, // Non fonctionnel — visuel uniquement
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: AppColors.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        // Activer l'apparence même si onPressed est null
        disabledForegroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primary.withOpacity(0.08),
      ),
      child: const Text(
        'Voir',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
