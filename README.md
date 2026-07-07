# (RE)Sources Relationnelles — Application mobile Flutter

Application mobile compagnon du projet **(RE)Sources Relationnelles**, plateforme citoyenne de renforcement des liens sociaux. Elle expose le même back-end REST que l'application web et partage la même logique métier (rôles, ressources publiées, commentaires étoilés, favoris, RGPD).

---

## Sommaire

- [Présentation](#présentation)
- [Pré-requis](#pré-requis)
- [Installation](#installation)
- [Structure du projet](#structure-du-projet)
- [Fonctionnalités](#fonctionnalités)
- [Charte graphique](#charte-graphique)
- [Architecture](#architecture)
- [API & environnement](#api--environnement)

---

## Présentation

| Écran | Description |
|-------|-------------|
| **Accueil** | Ressources publiées à la une, filtres par catégorie, salutation personnalisée |
| **Catalogue** | Recherche full-text, filtres catégorie + type, affichage ressources publiées uniquement |
| **Mon espace** | Tableau de bord : mes ressources créées + mes favoris |
| **Profil** | Informations du compte, préférences, confidentialité RGPD, déconnexion |
| **Détail ressource** | Contenu complet, bouton média contextuel (PDF/vidéo/podcast/URL), commentaires avec étoiles |
| **Connexion / Inscription** | Auth JWT, formulaire d'inscription aligné sur le web (prénom/nom, rôle, double mot de passe) |

---

## Pré-requis

- Flutter SDK ≥ 3.0
- Dart SDK ≥ 3.0
- Android SDK / Xcode (selon la cible)
- Back-end `(RE)Sources Relationnelles` accessible (voir `api_service.dart` pour l'URL de base)

---

## Installation

```bash
# Cloner le dépôt
git clone https://github.com/<org>/re_flutter.git
cd re_flutter

# Récupérer les dépendances
flutter pub get

# Lancer (émulateur ou appareil connecté)
flutter run
```

### Dépendances principales

| Package | Version | Usage |
|---------|---------|-------|
| `http` | ^1.2.0 | Appels REST vers l'API |
| `shared_preferences` | ^2.2.2 | Persistance locale (favoris, progression, token JWT) |
| `url_launcher` | ^6.2.0 | Ouverture PDF / liens externes |

---

## Structure du projet

```
lib/
├── main.dart                   # Point d'entrée, thème Material 3, navigation principale
├── mock_data.dart              # Modèles de données + données de repli (fallback API)
│
├── screens/
│   ├── home_page.dart          # Accueil : ressources à la une + catégories
│   ├── resource_list_page.dart # Catalogue avec recherche et filtres
│   ├── resource_detail_page.dart # Détail : contenu, média, commentaires, favoris
│   ├── dashboard_page.dart     # Mon espace : mes ressources + mes favoris
│   ├── profile_page.dart       # Profil utilisateur + préférences + RGPD
│   ├── login_page.dart         # Connexion JWT
│   ├── register_page.dart      # Inscription (prénom/nom/rôle/mot de passe)
│   ├── forgot_password_page.dart
│   ├── notifications_page.dart
│   ├── help_page.dart
│   ├── create_resource_page.dart
│   ├── moderation_page.dart    # Modérateur/Admin uniquement
│   ├── admin_categories_page.dart
│   └── statistics_page.dart
│
├── services/
│   ├── api_service.dart        # Client HTTP REST (singleton)
│   ├── auth_service.dart       # Gestion session JWT + rôles (ChangeNotifier)
│   └── storage_service.dart   # Persistance locale : favoris, progression, signalements
│
└── widgets/
    ├── resource_card.dart      # Carte ressource (compact/plein)
    ├── category_chip.dart      # Chip catégorie + ligne scrollable
    └── progress_card.dart      # Carte de progression (widget utilitaire)
```

---

## Fonctionnalités

### Authentification
- Connexion JWT via `POST /api/login_check`
- Inscription avec prénom, nom, e-mail, rôle (parent / éducateur / professionnel), mot de passe validé (min. 8 car., 1 majuscule, 1 chiffre), confirmation de mot de passe
- Acceptation des CGU et de la politique RGPD (deux cases distinctes)
- Restauration automatique de session au démarrage (`AuthService.restore()`)
- Déconnexion avec nettoyage des préférences locales

### Ressources
- Chargement depuis l'API avec fallback sur les données locales
- Affichage exclusif des ressources **publiées** (`status == 'publie'`)
- Filtres combinés : catégorie (icône Material) + type + recherche full-text
- Visibilité : Public visible par tous, Partagé/Privé pour les connectés uniquement

### Détail d'une ressource
- Bouton média contextuel calqué sur l'app web :
  - **PDF** → bouton rouge "Télécharger le PDF"
  - **Vidéo** → bouton bleu "Regarder la vidéo"
  - **Podcast** → bouton violet "Écouter le podcast"
  - **URL** → bouton bleu "Consulter la ressource"
  - **Aucun** → bouton désactivé + texte explicatif
- Ouverture via `url_launcher` dans l'application externe

### Commentaires
- Chargement depuis l'API (`GET /api/resources/{id}/comments`)
- Sélecteur d'étoiles 1-5 avant publication
- Affichage des étoiles sur chaque commentaire existant
- Signalement de commentaire (masquage local au-delà de 3 signalements)

### Favoris
- Toggle favori depuis la page détail (cœur dans l'AppBar)
- Persistance locale via `StorageService` + appel API `toggleSave()`
- Affichage dans la page Profil (source : `StorageService.favoriteIds`)
- Affichage dans "Mon espace" (source : `ApiService.fetchFavorites()`)

### Tableau de bord (Mon espace)
- Onglet **Mes ressources** : ressources créées par l'utilisateur (tous statuts)
- Onglet **Mes favoris** : ressources sauvegardées via l'API
- Badges de statistiques : Créées / Publiées / En attente

### Profil
- Avatar avec initiales générées automatiquement
- Informations du compte (nom, e-mail, rôle) en lecture seule
- Dialogue RGPD complet : données collectées, sécurité, partage, droits, cookies
- Déconnexion

---

## Charte graphique

Définie dans `AppColors` (`main.dart`) :

| Constante | Couleur | Usage |
|-----------|---------|-------|
| `primary` | `#1F4E79` | Bleu principal |
| `accent` | `#F2B73F` | Jaune/Or (highlights, étoiles) |
| `background` | `#F0F2F5` | Fond de l'app |
| `textDark` | `#1A2B3C` | Texte principal |
| `textMuted` | `#7A8FA6` | Texte secondaire |
| `success` | `#2E7D32` | Vert (statut Publié) |
| `warning` | `#E65100` | Orange (statut En attente) |
| `info` | `#1565C0` | Bleu clair (visibilité) |

Thème Material 3 (`useMaterial3: true`) — police système, coins arrondis (12-14 px), ombres légères.

---

## Architecture

```
Couche UI (screens / widgets)
        │
        ▼
AuthService (ChangeNotifier)   StorageService (ChangeNotifier)
        │                              │
        └──────────┬───────────────────┘
                   │
               ApiService (singleton)
                   │
              HTTP / REST
                   │
         Back-end Symfony
```

- **Singletons** : `AuthService`, `StorageService`, `ApiService` utilisent le pattern factory singleton.
- **Réactivité** : les écrans s'abonnent à `AuthService` et `StorageService` via `addListener` / `removeListener` pour se reconstruire lors des changements de session ou de favoris.
- **Optimistic update** : le toggle favori met à jour l'état local immédiatement, puis envoie l'appel API en arrière-plan.

---

## API & environnement

L'URL de base est définie dans `lib/services/api_service.dart` :

```dart
static const String _baseUrl = 'http://<votre-serveur>';
```

### Endpoints utilisés

| Méthode | Endpoint | Usage |
|---------|----------|-------|
| `POST` | `/api/login_check` | Connexion (retourne JWT) |
| `POST` | `/api/register` | Inscription |
| `GET` | `/api/me` | Profil utilisateur connecté |
| `GET` | `/api/resources` | Liste des ressources |
| `GET` | `/api/resources/{id}` | Détail d'une ressource |
| `GET` | `/api/resources/favorites` | Favoris de l'utilisateur |
| `POST` | `/api/resources/{id}/save` | Toggle favori |
| `GET` | `/api/resources/{id}/comments` | Commentaires d'une ressource |
| `POST` | `/api/resources/{id}/comments` | Publier un commentaire |
| `GET` | `/api/categories` | Liste des catégories |
| `GET` | `/api/resources/download/{filename}` | Téléchargement de fichier média |
