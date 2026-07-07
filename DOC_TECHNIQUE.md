# Document Technique — (RE)Sources Relationnelles (Flutter)

> Version : 1.0 — Mai 2026  
> Application mobile compagnon du back-end Symfony `(RE)Sources Relationnelles`

---

## Table des matières

1. [Vue d'ensemble](#1-vue-densemble)
2. [Modèles de données](#2-modèles-de-données)
3. [Services](#3-services)
4. [Écrans](#4-écrans)
5. [Widgets réutilisables](#5-widgets-réutilisables)
6. [Navigation](#6-navigation)
7. [Persistance locale](#7-persistance-locale)
8. [Gestion des rôles](#8-gestion-des-rôles)
9. [Gestion des médias](#9-gestion-des-médias)
10. [Commentaires et notation](#10-commentaires-et-notation)
11. [Favoris](#11-favoris)
12. [Conformité RGPD](#12-conformité-rgpd)
13. [Données de repli (fallback)](#13-données-de-repli-fallback)
14. [Charte graphique](#14-charte-graphique)

---

## 1. Vue d'ensemble

L'application Flutter est une **interface mobile** connectée au même back-end REST que l'application web. Elle est organisée en trois couches :

```
┌─────────────────────────────────────────────┐
│               Couche Présentation            │
│  screens/ + widgets/                        │
│  StatefulWidget, ChangeNotifier listeners   │
└────────────────────┬────────────────────────┘
                     │ addListener / setState
┌────────────────────▼────────────────────────┐
│               Couche Services               │
│  AuthService  StorageService  ApiService    │
│  (singletons, ChangeNotifier)               │
└────────────────────┬────────────────────────┘
                     │ HTTP / SharedPreferences
┌────────────────────▼────────────────────────┐
│              Couche Infrastructure          │
│  Back-end Symfony REST  |  SharedPrefs       │
└─────────────────────────────────────────────┘
```

### Principe singleton

Tous les services sont des singletons via le pattern factory :

```dart
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();
}
```

Cela garantit qu'une seule instance est partagée par toute l'application.

---

## 2. Modèles de données

Définis dans `lib/mock_data.dart`.

### 2.1 MockResource

Représente une ressource relationnelle.

```dart
class MockResource {
  final String id;           // identifiant (numérique sous forme String pour l'API)
  final String title;
  final String category;     // label catégorie (ex. "Famille")
  final String type;         // "Article" | "Video" | "Podcast" | "Exercice" | "Jeu"
  final String visibility;   // "Public" | "Partage" | "Prive"
  final String progressStatus; // "A voir" | "Consulte" | "Exploite" (local)
  final String description;
  final String author;
  final String content;      // contenu complet (chargé en différé si vide)
  final String status;       // "brouillon" | "en attente" | "publie" | "suspendu"
  final String? link;        // URL externe (champ `lien` de l'API)
  final String? mediaUrl;    // Fichier uploadé résolu en URL complète
}
```

**Getters calculés :**

| Getter | Type | Description |
|--------|------|-------------|
| `actionUrl` | `String?` | `mediaUrl` en priorité, sinon `link` |
| `mediaKind` | `String?` | `'pdf'` \| `'video'` \| `'podcast'` \| `'url'` \| `null` |

**Logique de `mediaKind` :**
```dart
String? get mediaKind {
  final t = type.toLowerCase();
  if (t == 'pdf' && mediaUrl != null) return 'pdf';
  if (t == 'video') return 'video';
  if (t == 'podcast') return 'podcast';
  if (link != null && link!.isNotEmpty) return 'url';
  if (mediaUrl != null && mediaUrl!.isNotEmpty) return 'url';
  return null;
}
```

### 2.2 MockCategory

```dart
class MockCategory {
  final int id;
  final String label;
  final IconData icon;   // icône Material Design (remplace l'ancien champ emoji)
}
```

Catégories par défaut (fallback) :

| Label | Icône Material |
|-------|---------------|
| Famille | `Icons.family_restroom_rounded` |
| Couple | `Icons.favorite_rounded` |
| Travail | `Icons.work_outline_rounded` |
| Amis | `Icons.group_outlined` |
| Bien-etre | `Icons.self_improvement_rounded` |
| Parentalite | `Icons.child_care_rounded` |

### 2.3 Comment

```dart
class Comment {
  final String id;
  final String resourceId;
  final String author;
  final String text;
  final DateTime createdAt;
  final int reportCount;   // nombre de signalements
  final int rating;        // note de 1 à 5 étoiles (0 = non noté)
}
```

Mapping API : champ `note` ou `rating` → `rating`.

### 2.4 AppNotification

```dart
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String kind; // 'comment' | 'validation' | 'publication'
}
```

### 2.5 AuthUser

Défini dans `auth_service.dart` :

```dart
class AuthUser {
  final String name;   // "Prénom Nom"
  final String email;
  final UserRole role;
  final int? id;       // id utilisateur API
  String get initials; // ex. "JD" pour Jean Dupont
}
```

---

## 3. Services

### 3.1 ApiService (`lib/services/api_service.dart`)

Client HTTP singleton vers le back-end REST. Toutes les requêtes incluent le header `Authorization: Bearer <token>` si un token JWT est disponible.

#### URL de base

```dart
static const String _baseUrl = 'http://<votre-serveur>';
```

#### Méthodes principales

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `login(email, password)` | `POST /api/login_check` | Retourne le token JWT |
| `register(name, email, password, role)` | `POST /api/register` | Inscription |
| `fetchMe()` | `GET /api/me` | Profil utilisateur connecté |
| `logout()` | — | Efface le token local |
| `fetchResources()` | `GET /api/resources` | Liste toutes les ressources |
| `fetchResource(id)` | `GET /api/resources/{id}` | Détail d'une ressource |
| `fetchMyResources()` | `GET /api/resources/mine` | Ressources créées par l'utilisateur |
| `fetchFavorites()` | `GET /api/resources/favorites` | Favoris de l'utilisateur |
| `toggleSave(id)` | `POST /api/resources/{id}/save` | Ajouter/retirer des favoris |
| `fetchCategories()` | `GET /api/categories` | Liste des catégories |
| `fetchComments(id)` | `GET /api/resources/{id}/comments` | Commentaires d'une ressource |
| `addComment(id, text, rating)` | `POST /api/resources/{id}/comments` | Publier un commentaire |

#### Résolution des URLs de médias

```dart
String _resolveMediaUrl(String? media) {
  if (media == null || media.isEmpty) return '';
  if (media.startsWith('http://') || media.startsWith('https://')) return media;
  return '$_baseUrl/api/resources/download/$media';
}
```

Les noms de fichiers relatifs retournés par l'API (champ `media`) sont convertis en URL complète vers l'endpoint de téléchargement.

#### Mapping JSON → MockResource

| Champ API | Champ modèle | Transformation |
|-----------|-------------|----------------|
| `id` | `id` | `toString()` |
| `title` | `title` | — |
| `category.name` | `category` | — |
| `type` | `type` | — |
| `isPublic` | `visibility` | `true` → `'Public'`, sinon `'Prive'` |
| `status` | `status` | — |
| `description` | `description` | — |
| `author.firstname + lastname` | `author` | concaténation |
| `content` | `content` | — |
| `lien` | `link` | — |
| `media` | `mediaUrl` | `_resolveMediaUrl()` |

#### Mapping JSON → MockCategory

La méthode `_categoryIcon(name)` retourne une `IconData` Material selon le nom de catégorie (correspondance insensible à la casse, avec fallback `Icons.folder_outlined`).

### 3.2 AuthService (`lib/services/auth_service.dart`)

Singleton `ChangeNotifier` qui gère le cycle de vie de la session.

#### Cycle de vie

```
main() → AuthService().restore()
           ↓
    SharedPreferences → token JWT stocké ?
           ↓ oui
    ApiService().fetchMe() → token valide ?
           ↓ oui            ↓ non
    session restaurée     token effacé + fallback local
```

#### Persistance

| Clé SharedPreferences | Contenu |
|----------------------|---------|
| `auth_name` | Nom complet |
| `auth_email` | E-mail |
| `auth_role` | Nom de l'enum `UserRole` |
| `auth_logged_in` | `bool` |
| `auth_token` | Token JWT |
| `auth_user_id` | `int` identifiant API |

#### Mapping rôles API → `UserRole`

| Rôle API | `UserRole` Flutter |
|----------|-------------------|
| `ROLE_SUPER_ADMIN` | `administrateur` |
| `ROLE_ADMIN` | `administrateur` |
| `ROLE_MODERATOR` | `moderateur` |
| `ROLE_CONNECTED`, `ROLE_USER` | `citoyenConnecte` |
| (non connecté) | `citoyenNonConnecte` |

### 3.3 StorageService (`lib/services/storage_service.dart`)

Singleton `ChangeNotifier` pour les données **locales** non couvertes par l'API.

#### Données persistées

| Clé | Type | Contenu |
|-----|------|---------|
| `favorites_ids` | `List<String>` | IDs des ressources favorites |
| `progression_map` | `String` (JSON) | `{resourceId: progressionName}` |
| `comments_list` | `String` (JSON) | Commentaires locaux |
| `reported_comment_ids` | `List<String>` | IDs de commentaires signalés |
| `notifications_read_ids` | `List<String>` | IDs de notifications lues |

#### Seuil de masquage des commentaires

```dart
static const int reportThreshold = 3;
```

Un commentaire ayant reçu ≥ 3 signalements est masqué (contenu remplacé par un avertissement).

---

## 4. Écrans

### 4.1 LoginPage (`screens/login_page.dart`)

- Formulaire e-mail + mot de passe
- Appel `AuthService().login()` → redirection vers `MainScaffold`
- Lien vers `RegisterPage` et `ForgotPasswordPage`
- Expose la fonction utilitaire `inputDecoration({label, hint, icon})` réutilisée dans `RegisterPage`

### 4.2 RegisterPage (`screens/register_page.dart`)

Formulaire d'inscription aligné sur l'application web :

| Champ | Validation |
|-------|-----------|
| Prénom | Non vide |
| Nom | Non vide |
| E-mail | Non vide + contient `@` |
| Rôle | Dropdown : `parent` / `educateur` / `professionnel` |
| Mot de passe | Min. 8 car. + 1 majuscule + 1 chiffre |
| Confirmation | Identique au mot de passe |
| CGU | Case obligatoire |
| RGPD | Case obligatoire |

Après inscription réussie : écran de confirmation 2 secondes, puis redirection vers `MainScaffold`.

### 4.3 HomePage (`screens/home_page.dart`)

- `SliverAppBar` avec gradient, salutation personnalisée, badge rôle
- Barre de recherche décorative (non fonctionnelle, renvoie vers le Catalogue)
- Section catégories : `CategoryChipsRow` (filtre local sur `_filteredFeatured`)
- Section "Ressources à la une" : liste des ressources **publiées** filtrées

**Filtre appliqué :**
```dart
List<MockResource> get _filteredFeatured {
  final published = _resources.where((r) => r.status == 'publie').toList();
  if (_selectedCategoryIndex < 0) return published;
  final cat = _categories[_selectedCategoryIndex].label;
  return published.where((r) => r.category == cat).toList();
}
```

### 4.4 ResourceListPage (`screens/resource_list_page.dart`)

Catalogue complet avec :
- Recherche full-text (titre, description, catégorie, auteur)
- Filtre catégorie (chips dans l'AppBar)
- Filtre type (chips secondaires : Article / Vidéo / Podcast / Exercice / Jeu)
- Seules les ressources **publiées** sont affichées
- Visibilité : les ressources non publiques ne sont visibles qu'aux connectés

```dart
List<MockResource> get _filteredResources {
  if (r.status != 'publie') return false;
  final categoryMatch = selectedCat.id == -1 || r.category == selectedCat.label;
  final typeMatch = _selectedType == null || r.type == _selectedType;
  final visibilityMatch = canSeePrivate || r.visibility == 'Public';
  final searchMatch = ...;
  return categoryMatch && typeMatch && visibilityMatch && searchMatch;
}
```

### 4.5 ResourceDetailPage (`screens/resource_detail_page.dart`)

Sections affichées dans l'ordre :
1. **AppBar** : titre, type, bouton favori (si connecté)
2. **Méta** : catégorie, visibilité, auteur (chips)
3. **Description** : texte de présentation
4. **Contenu** : texte complet (chargé via API si manquant)
5. **Bouton média** : contextuel selon `mediaKind`
6. **Commentaires** : liste API + formulaire avec étoiles (si connecté et ressource publique)

**Chargement différé du contenu :**
```dart
Future<void> _maybeFetchDetail() async {
  final intId = int.tryParse(widget.resource.id);
  if (intId == null || widget.resource.content.isNotEmpty) return;
  // fetch uniquement si id numérique et contenu vide
}
```

### 4.6 DashboardPage (`screens/dashboard_page.dart`)

Accessible uniquement aux utilisateurs connectés. Deux onglets (`TabController`) :

| Onglet | Source des données | Contenu |
|--------|-------------------|---------|
| Mes ressources | `ApiService.fetchMyResources()` | Toutes les ressources créées, tous statuts |
| Mes favoris | `ApiService.fetchFavorites()` | Ressources sauvegardées via l'API |

Badges de statistiques dans le header : nombre total / publiées / en attente.

### 4.7 ProfilePage (`screens/profile_page.dart`)

- Avatar avec initiales (fond `primary`)
- Infos compte : nom, e-mail, rôle — **lecture seule**
- Section favoris : filtre `_allResources` par `StorageService.favoriteIds`
- Section préférences :
  - Confidentialité → dialogue RGPD complet (5 sections)
  - Déconnexion → `AuthService().logout()` + retour vers `LoginPage`

**Dialogue RGPD** (`_showPrivacyDialog`) :
1. Données collectées
2. Sécurité des données
3. Partage des données
4. Vos droits (accès, rectification, suppression, portabilité)
5. Cookies et stockage local

---

## 5. Widgets réutilisables

### 5.1 ResourceCard (`widgets/resource_card.dart`)

Carte ressource disponible en deux modes :
- `compact: true` → carte compacte pour l'accueil
- `compact: false` → carte pleine pour le catalogue

### 5.2 CategoryChipWidget / CategoryChipsRow (`widgets/category_chip.dart`)

```dart
class CategoryChipWidget extends StatelessWidget {
  final MockCategory category;
  final bool isSelected;
  // → AnimatedContainer avec icône Material
}

class CategoryChipsRow extends StatelessWidget {
  final List<MockCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  // → ListView horizontal de CategoryChipWidget
}
```

### 5.3 ProgressCard (`widgets/progress_card.dart`)

Widget utilitaire pour l'affichage de progressions (non affiché dans les écrans principaux actuellement).

---

## 6. Navigation

Navigation principale : `BottomNavigationBar` dans `MainScaffold` avec `IndexedStack` (les 4 écrans principaux restent en mémoire).

```
MainScaffold (IndexedStack)
├── [0] HomePage
├── [1] ResourceListPage
├── [2] DashboardPage
└── [3] ProfilePage
```

Navigation secondaire via `Navigator.of(context).push(MaterialPageRoute(...))` :
- `ResourceDetailPage` depuis HomePage, ResourceListPage, DashboardPage
- `LoginPage` depuis DashboardPage (non connecté) et ProfilePage
- `RegisterPage` depuis LoginPage
- `HelpPage` depuis HomePage
- `ForgotPasswordPage` depuis LoginPage

---

## 7. Persistance locale

### SharedPreferences — clés utilisées

| Service | Clé | Type | Description |
|---------|-----|------|-------------|
| AuthService | `auth_name` | String | Nom complet |
| AuthService | `auth_email` | String | E-mail |
| AuthService | `auth_role` | String | Nom de l'enum `UserRole` |
| AuthService | `auth_logged_in` | bool | Session active |
| AuthService | `auth_token` | String | JWT |
| AuthService | `auth_user_id` | int | ID utilisateur |
| StorageService | `favorites_ids` | List\<String\> | IDs favoris |
| StorageService | `progression_map` | String (JSON) | Carte progression |
| StorageService | `comments_list` | String (JSON) | Commentaires locaux |
| StorageService | `reported_comment_ids` | List\<String\> | IDs signalés |
| StorageService | `notifications_read_ids` | List\<String\> | IDs notifications lues |

---

## 8. Gestion des rôles

### Enum UserRole

```dart
enum UserRole {
  citoyenNonConnecte,  // visiteur
  citoyenConnecte,     // utilisateur authentifié
  moderateur,          // peut modérer les commentaires et ressources
  administrateur,      // accès complet
}
```

### Permissions

| Fonctionnalité | Non connecté | Connecté | Modérateur | Admin |
|----------------|-------------|---------|-----------|-------|
| Voir ressources publiques | ✓ | ✓ | ✓ | ✓ |
| Voir ressources privées | ✗ | ✓ | ✓ | ✓ |
| Commenter | ✗ | ✓ | ✓ | ✓ |
| Mettre en favori | ✗ | ✓ | ✓ | ✓ |
| Créer une ressource | ✗ | ✓ | ✓ | ✓ |
| Modérer | ✗ | ✗ | ✓ | ✓ |
| Administration | ✗ | ✗ | ✗ | ✓ |

### Extension UserRoleX

```dart
extension UserRoleX on UserRole {
  String get label;     // libellé complet
  String get short;     // libellé court (affiché dans le badge de l'accueil)
  bool get canContribute; // != citoyenNonConnecte
  bool get canModerate;   // moderateur || administrateur
  bool get canAdmin;      // administrateur uniquement
}
```

---

## 9. Gestion des médias

### Pipeline de résolution

```
API JSON field "media" (filename)
        ↓ _resolveMediaUrl()
URL complète : http://<serveur>/api/resources/download/<filename>
        ↓ stocké dans MockResource.mediaUrl
        ↓ combiné avec MockResource.link
        ↓ actionUrl (mediaUrl prioritaire)
        ↓ mediaKind (type MIME logique)
        ↓
Bouton contextuel dans ResourceDetailPage._buildResourceLink()
        ↓
url_launcher.launchUrl(uri, mode: LaunchMode.externalApplication)
```

### Correspondance type → affichage

| `mediaKind` | Couleur | Icône | Label bouton |
|-------------|---------|-------|-------------|
| `'pdf'` | Rouge `#B71C1C` | `download_rounded` | Télécharger le PDF |
| `'video'` | `primary` | `play_circle_filled_rounded` | Regarder la vidéo |
| `'podcast'` | Violet `#7B1FA2` | `headphones_rounded` | Écouter le podcast |
| `'url'` | `primary` | `open_in_new_rounded` | Consulter la ressource |
| `null` | `textMuted` | `link_off_rounded` | Aucun lien disponible (désactivé) |

---

## 10. Commentaires et notation

### Flux de publication

```
Utilisateur sélectionne une note (1-5 étoiles, _commentRating)
        ↓
Utilisateur saisit le texte
        ↓
_postComment() → ApiService.addComment(id, text, rating: _commentRating)
        ↓
POST /api/resources/{id}/comments
  body: { "content": text, "note": rating }
        ↓
Rechargement des commentaires depuis l'API (_loadComments)
        ↓
Réinitialisation _commentRating = 5
```

### Affichage des étoiles

Chaque commentaire affiche une rangée de 5 étoiles basée sur `c.rating` :
- `Icons.star_rounded` (jaune `accent`) pour les étoiles actives
- `Icons.star_outline_rounded` (gris `textMuted`) pour les étoiles vides
- Non affiché si `c.rating == 0`

### Signalement

- `StorageService.reportComment(id)` incrémente localement `reportCount`
- Au-delà de `reportThreshold = 3` signalements : le texte est remplacé par un avertissement
- Un commentaire déjà signalé par l'utilisateur courant affiche un bouton désactivé

---

## 11. Favoris

### Double source de données

| Contexte | Source | Mécanisme |
|---------|--------|-----------|
| Page Profil | `StorageService.favoriteIds` | Filtre local sur `_allResources` |
| Dashboard "Mes favoris" | `ApiService.fetchFavorites()` | `GET /api/resources/favorites` |
| Icône cœur (détail) | `StorageService.isFavorite(id)` | État local avec update optimiste |

### Toggle favori (détail)

```dart
Future<void> _toggleFavorite() async {
  // 1. Mise à jour locale immédiate (optimistic update)
  final wasLocal = _storage.isFavorite(_resource!.id);
  await _storage.toggleFavorite(_resource!.id);
  setState(() => _isFavorite = !wasLocal);
  
  // 2. Appel API en arrière-plan (si connecté)
  if (_auth.isLoggedIn && intId != null) {
    await _api.toggleSave(intId);
  }
  
  // 3. SnackBar de confirmation
}
```

---

## 12. Conformité RGPD

### Inscription

Deux cases à cocher obligatoires, vérifiées avant soumission :
- `_acceptTerms` : Conditions d'utilisation
- `_acceptRGPD` : Politique de confidentialité et traitement des données

### Dialogue d'information RGPD (profil)

Accessible via **Profil → Confidentialité**. Couvre 5 sections :

1. **Données collectées** : nom, e-mail, rôle, favoris, commentaires, progression
2. **Sécurité** : chiffrement en transit (HTTPS), token JWT, stockage local chiffré
3. **Partage** : aucune vente de données, partage limité aux opérateurs internes
4. **Vos droits** : accès, rectification, suppression, portabilité (contact DPO)
5. **Cookies et stockage local** : `shared_preferences` pour la session et les préférences, pas de cookies tiers

### Stockage local

Seules les données strictement nécessaires sont stockées localement :
- Token JWT (session)
- Informations de profil (nom, e-mail, rôle)
- IDs des favoris et progressions
- Commentaires locaux et signalements

---

## 13. Données de repli (fallback)

En cas d'indisponibilité de l'API, les écrans utilisent les listes définies dans `mock_data.dart` :

| Constante | Usage |
|-----------|-------|
| `mockCategories` | 6 catégories avec icônes Material |
| `mockFeaturedResources` | 5 ressources à la une |
| `mockAllResources` | 8 ressources pour le catalogue |
| `mockProgressItems` | 2 progressions en cours |
| `mockFavoriteResources` | Liste vide (favoris locaux uniquement) |
| `mockUserStats` | Statistiques par défaut |

---

## 14. Charte graphique

Définie dans `AppColors` (`lib/main.dart`).

### Palette

| Constante | Hex | Usage |
|-----------|-----|-------|
| `primary` | `#1F4E79` | Bleu principal — AppBar, boutons, icônes actives |
| `accent` | `#F2B73F` | Jaune/Or — highlights, indicateur onglet, étoiles |
| `white` | `#FFFFFF` | Fonds de cartes, textes sur fond sombre |
| `background` | `#F0F2F5` | Fond général de l'application |
| `textDark` | `#1A2B3C` | Texte principal |
| `textMuted` | `#7A8FA6` | Texte secondaire, hints |
| `cardShadow` | `#14000000` | Ombre légère des cartes |
| `success` | `#2E7D32` | Vert — statut "Publié" |
| `warning` | `#E65100` | Orange — statut "En attente" / commentaires signalés |
| `info` | `#1565C0` | Bleu clair — badges de visibilité |

### Thème Material 3

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  // Rayons de bordure : 12-14 px pour les cartes, 20-24 px pour les chips
  // Police : système (Roboto sur Android, SF Pro sur iOS)
  // Ombres : légères (blurRadius 8-10, offset (0,3))
)
```

### Gradient AppBar

Toutes les AppBar utilisent un gradient horizontal :
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primary, Color(0xFF163A5F)],
)
```
