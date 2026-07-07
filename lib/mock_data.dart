// ============================================================
// mock_data.dart — Modeles et donnees de repli
// (RE)Sources Relationnelles
// ============================================================

import 'package:flutter/material.dart';

/// Modele d'une ressource relationnelle.
/// Le constructeur principal accepte les champs "brut" de l'API, et expose
/// des getters pour les libelles d'affichage (equivalents des anciens champs).
class MockResource {
  final String id;
  final String title;
  final String category;
  final String type; // Article, Video, Podcast, Exercice, Jeu (display)
  final String visibility; // Public, Partage, Prive (display)
  final String progressStatus; // A voir, Consulte, Exploite (local)
  final String description;
  final String author;
  final String content; // contenu complet
  final String status; // brouillon, en attente, publie, suspendu
  final String? link;     // URL externe (lien)
  final String? mediaUrl; // Fichier uploadé (media résolu en URL complète)

  const MockResource({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.visibility,
    required this.progressStatus,
    required this.description,
    required this.author,
    this.content = '',
    this.status = 'publie',
    this.link,
    this.mediaUrl,
  });

  /// URL à utiliser pour l'action principale (mediaUrl prioritaire sur link).
  String? get actionUrl => (mediaUrl?.isNotEmpty == true) ? mediaUrl : link;

  /// Retourne le label et l'icône selon le type de ressource.
  /// 'pdf'|'video'|'podcast'|'url'|null
  String? get mediaKind {
    final t = type.toLowerCase();
    if (t == 'pdf' && mediaUrl != null) return 'pdf';
    if (t == 'video') return 'video';
    if (t == 'podcast') return 'podcast';
    if (link != null && link!.isNotEmpty) return 'url';
    if (mediaUrl != null && mediaUrl!.isNotEmpty) return 'url';
    return null;
  }

  MockResource copyWith({
    String? progressStatus,
    String? link,
    String? mediaUrl,
  }) {
    return MockResource(
      id: id,
      title: title,
      category: category,
      type: type,
      visibility: visibility,
      progressStatus: progressStatus ?? this.progressStatus,
      description: description,
      author: author,
      content: content,
      status: status,
      link: link ?? this.link,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}

/// Modele d'une categorie
class MockCategory {
  final int id;
  final String label;
  final IconData icon;

  const MockCategory({
    this.id = 0,
    required this.label,
    this.icon = Icons.folder_outlined,
  });
}

/// Modele d'une progression (section "Continuer ma progression")
class MockProgress {
  final String resourceTitle;
  final String category;
  final double progress;
  final String type;

  const MockProgress({
    required this.resourceTitle,
    required this.category,
    required this.progress,
    required this.type,
  });
}

/// Modele d'un commentaire
class Comment {
  final String id;
  final String resourceId;
  final String author;
  final String text;
  final DateTime createdAt;
  final int reportCount;
  final int rating; // Note de 1 à 5 étoiles (0 = pas de note)

  const Comment({
    required this.id,
    required this.resourceId,
    required this.author,
    required this.text,
    required this.createdAt,
    this.reportCount = 0,
    this.rating = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'resourceId': resourceId,
        'author': author,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'reportCount': reportCount,
        'rating': rating,
      };

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: j['id'] ?? '',
        resourceId: j['resourceId'] ?? '',
        author: j['author'] ?? '',
        text: j['text'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        reportCount: j['reportCount'] ?? 0,
        rating: (j['rating'] as num?)?.toInt() ?? 0,
      );
}

/// Modele d'une notification
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String kind; // 'comment', 'validation', 'publication'

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.kind = 'publication',
  });
}

// ------------------------------------------------------------------
// Donnees de repli (si l'API est injoignable au demarrage)
// ------------------------------------------------------------------

/// Categories par defaut
const List<MockCategory> mockCategories = [
  MockCategory(label: 'Famille',     icon: Icons.family_restroom_rounded),
  MockCategory(label: 'Couple',      icon: Icons.favorite_rounded),
  MockCategory(label: 'Travail',     icon: Icons.work_outline_rounded),
  MockCategory(label: 'Amis',        icon: Icons.group_outlined),
  MockCategory(label: 'Bien-etre',   icon: Icons.self_improvement_rounded),
  MockCategory(label: 'Parentalite', icon: Icons.child_care_rounded),
];

/// Ressources a la une (fallback)
const List<MockResource> mockFeaturedResources = [
  MockResource(
    id: 'f1',
    title: 'Mieux communiquer en famille',
    category: 'Famille',
    type: 'Article',
    visibility: 'Public',
    progressStatus: 'Consulte',
    description: "Decouvrez les cles d'une communication bienveillante pour renforcer les liens familiaux.",
    author: 'Dr. Marie Leblanc',
    content: "Cet article explore les fondamentaux de la communication non-violente au sein du cercle familial...",
  ),
  MockResource(
    id: 'f2',
    title: 'Gerer les conflits au travail',
    category: 'Travail',
    type: 'Video',
    visibility: 'Public',
    progressStatus: 'A voir',
    description: "Apprendre a desamorcer les tensions professionnelles avec elegance.",
    author: 'Thomas Girard',
    content: "Cette video propose trois techniques eprouvees pour resoudre des conflits en milieu professionnel...",
  ),
  MockResource(
    id: 'f3',
    title: 'La meditation de pleine conscience',
    category: 'Bien-etre',
    type: 'Exercice',
    visibility: 'Public',
    progressStatus: 'Exploite',
    description: "Un exercice guide de 10 minutes pour retrouver calme et equilibre interieur.",
    author: 'Sophie Martin',
    content: "Installez-vous confortablement. Fermez les yeux. Prenez conscience de votre respiration...",
  ),
  MockResource(
    id: 'f4',
    title: 'Reconstruire la confiance dans le couple',
    category: 'Couple',
    type: 'Article',
    visibility: 'Prive',
    progressStatus: 'A voir',
    description: "Conseils d'experts pour traverser ensemble les moments difficiles et renforcer votre lien.",
    author: 'Pr. Jean Dupont',
    content: "La confiance est un pilier essentiel de toute relation de couple...",
  ),
  MockResource(
    id: 'f5',
    title: "Creer des amities durables a l'age adulte",
    category: 'Amis',
    type: 'Video',
    visibility: 'Public',
    progressStatus: 'Consulte',
    description: "Comment tisser et entretenir des liens d'amitie authentiques quand la vie s'accelere.",
    author: 'Lucie Bernard',
    content: "Trois approches concretes pour cultiver des amities profondes a l'age adulte...",
  ),
];

/// Catalogue complet (fallback)
const List<MockResource> mockAllResources = [
  ...mockFeaturedResources,
  MockResource(
    id: 'f6',
    title: 'Rituels du soir en famille',
    category: 'Famille',
    type: 'Exercice',
    visibility: 'Public',
    progressStatus: 'Exploite',
    description: "Des rituels simples pour renforcer la cohesion familiale chaque soir.",
    author: 'Camille Roux',
    content: "Voici cinq rituels du soir a mettre en place avec vos enfants pour creer des moments privilegies...",
  ),
  MockResource(
    id: 'f7',
    title: 'Mieux gerer le stress parental',
    category: 'Parentalite',
    type: 'Article',
    visibility: 'Prive',
    progressStatus: 'A voir',
    description: "Strategies concretes pour les parents debordes qui veulent rester sereins.",
    author: 'Dr. Helene Morin',
    content: "Le stress parental est un phenomene courant. Voici comment l'apprivoiser au quotidien...",
  ),
  MockResource(
    id: 'f8',
    title: "L'ecoute active : s'entrainer au quotidien",
    category: 'Bien-etre',
    type: 'Exercice',
    visibility: 'Public',
    progressStatus: 'Consulte',
    description: "Exercices pratiques pour developper une ecoute profonde et empathique.",
    author: 'Antoine Lefevre',
    content: "L'ecoute active repose sur quelques principes simples que nous allons explorer ensemble...",
  ),
];

/// Progressions en cours (fallback)
const List<MockProgress> mockProgressItems = [
  MockProgress(
    resourceTitle: 'Rituels du soir en famille',
    category: 'Famille',
    progress: 0.65,
    type: 'Exercice',
  ),
  MockProgress(
    resourceTitle: "L'ecoute active : s'entrainer",
    category: 'Bien-etre',
    progress: 0.30,
    type: 'Exercice',
  ),
];

const List<MockResource> mockFavoriteResources = [];

const Map<String, int> mockUserStats = {
  'vues': 12,
  'en_cours': 3,
  'exploitees': 7,
};
