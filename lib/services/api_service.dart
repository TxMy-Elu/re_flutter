import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../mock_data.dart';

class ApiService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String? _token;
  bool _lastCallSucceeded = true;

  bool get isReachable => _lastCallSucceeded;
  String? get token => _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
  };

  // ------------------------------------------------------------------
  // Auth
  // ------------------------------------------------------------------

  /// POST /api/auth/login → { token } on success, throws on error.
  Future<String> login({required String email, required String password}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/login'),
            headers: _jsonHeaders,
            body: json.encode({'email': email, 'password': password}),
          )
          ;

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body.containsKey('token')) {
        _token = body['token'] as String;
        _lastCallSucceeded = true;
        return _token!;
      }
      throw Exception(body['error'] ?? 'Identifiants incorrects');
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.login error: $e');
      throw Exception('Impossible de joindre le serveur');
    }
  }

  /// POST /api/auth/register → { token } on success, throws on error.
  Future<String> register({
    required String name,
    required String email,
    required String password,
    String role = 'parent',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/register'),
            headers: _jsonHeaders,
            body: json.encode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
            }),
          )
          ;

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && body.containsKey('token')) {
        _token = body['token'] as String;
        _lastCallSucceeded = true;
        return _token!;
      }
      throw Exception(body['error'] ?? 'Inscription échouée');
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.register error: $e');
      throw Exception('Impossible de joindre le serveur');
    }
  }

  /// GET /api/me → user profile map, null if unauthenticated/error.
  Future<Map<String, dynamic>?> fetchMe() async {
    if (_token == null) return null;
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/me'), headers: _authHeaders)
          ;

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.fetchMe error: $e');
    }
    return null;
  }

  /// POST /api/logout — best-effort, ignores failures.
  Future<void> logout() async {
    try {
      if (_token != null) {
        await http
            .post(Uri.parse('$_baseUrl/api/logout'), headers: _authHeaders)
            ;
      }
    } catch (_) {}
    _token = null;
  }

  // ------------------------------------------------------------------
  // Resources
  // ------------------------------------------------------------------

  Future<List<MockResource>> fetchResources() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/resources'));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> items;
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          items = decoded[0] as List<dynamic>;
        } else if (decoded is List) {
          items = decoded;
        } else {
          _lastCallSucceeded = true;
          return [];
        }
        _lastCallSucceeded = true;
        return items
            .map((item) => _resourceFromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchResources error: $e');
    }
    _lastCallSucceeded = false;
    return [];
  }

  Future<MockResource?> fetchResource(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/resources/$id'), headers: _authHeaders);

      if (response.statusCode == 200) {
        return _resourceFromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('ApiService.fetchResource error: $e');
    }
    return null;
  }

  /// POST /api/resources — requires JWT. Returns the new resource id, or throws.
  Future<int> createResource({
    required String titre,
    required String description,
    required String contenu,
    required String type,
    required String visibilite,
    required int categoryId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/resources'),
            headers: _authHeaders,
            body: json.encode({
              'titre': titre,
              'description': description,
              'contenu': contenu,
              'type': type,
              'visibilite': visibilite,
              'categoryId': categoryId,
            }),
          )
          ;

      if (response.statusCode == 201) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return (body['id'] as num?)?.toInt() ?? 0;
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Erreur lors de la création');
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.createResource error: $e');
      throw Exception('Impossible de joindre le serveur');
    }
  }

  // ------------------------------------------------------------------
  // Comments
  // ------------------------------------------------------------------

  Future<List<Comment>> fetchComments(int resourceId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/resources/$resourceId/comments'),
            headers: _authHeaders,
          )
          ;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // L'API retourne { "data": [...], "pagination": {...} }
        final List<dynamic> items = decoded is Map ? (decoded['data'] ?? []) : decoded;
        return items
            .map((item) => _commentFromJson(
                  item as Map<String, dynamic>,
                  resourceId.toString(),
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchComments error: $e');
    }
    return [];
  }

  Future<bool> addComment(int resourceId, String text, {int rating = 5}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/resources/$resourceId/comments'),
        headers: _authHeaders,
        body: json.encode({'content': text, 'rating': rating}),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.addComment error: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Favorites (save)
  // ------------------------------------------------------------------

  Future<bool> toggleSave(int resourceId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/resources/$resourceId/save'),
            headers: _authHeaders,
          )
          ;
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.toggleSave error: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Categories
  // ------------------------------------------------------------------

  Future<List<MockCategory>> fetchCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/categories'))
          ;

      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body);
        return items
            .map((item) => _categoryFromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchCategories error: $e');
    }
    return [];
  }

  Future<bool> createCategory({required String nom, String? description}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/categories'),
            headers: _authHeaders,
            body: json.encode({'name': nom, 'description': description ?? ''}),
          )
          ;
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.createCategory error: $e');
      return false;
    }
  }

  Future<bool> updateCategory(int id, {required String nom, String? description}) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/categories/$id'),
            headers: _authHeaders,
            body: json.encode({'name': nom, if (description != null) 'description': description}),
          )
          ;
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.updateCategory error: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/api/categories/$id'),
            headers: _authHeaders,
          )
          ;
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteCategory error: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // My resources & favorites
  // ------------------------------------------------------------------

  /// GET /api/resources/mine — ressources créées par l'utilisateur connecté.
  Future<List<MockResource>> fetchMyResources() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/resources/mine'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> items;
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          items = decoded[0] as List<dynamic>;
        } else if (decoded is List) {
          items = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          items = decoded['data'] as List<dynamic>;
        } else {
          return [];
        }
        return items
            .map((item) => _resourceFromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchMyResources error: $e');
    }
    return [];
  }

  /// GET /api/resources/favorites — favoris de l'utilisateur connecté.
  Future<List<MockResource>> fetchFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/resources/favorites'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> items;
        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          items = decoded[0] as List<dynamic>;
        } else if (decoded is List) {
          items = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          items = decoded['data'] as List<dynamic>;
        } else {
          return [];
        }
        return items
            .map((item) => _resourceFromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchFavorites error: $e');
    }
    return [];
  }

  /// PUT /api/resources/{id} — met à jour une ressource existante.
  Future<void> updateResource({
    required int id,
    required String titre,
    required String description,
    required String contenu,
    required String type,
    required String visibilite,
    required int categoryId,
    String? lien,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/resources/$id'),
        headers: _authHeaders,
        body: json.encode({
          'titre': titre,
          'description': description,
          'contenu': contenu,
          'type': type,
          'visibilite': visibilite,
          'categoryId': categoryId,
          if (lien != null && lien.isNotEmpty) 'lien': lien,
        }),
      );
      if (response.statusCode != 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(body['error'] ?? 'Erreur lors de la mise à jour');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.updateResource error: $e');
      throw Exception('Impossible de joindre le serveur');
    }
  }

  /// POST /api/auth/forgot-password — envoie un email de réinitialisation.
  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: _jsonHeaders,
        body: json.encode({'email': email}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(body['error'] ?? body['message'] ?? 'Erreur lors de l\'envoi');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.forgotPassword error: $e');
      throw Exception('Impossible de joindre le serveur');
    }
  }

  /// PUT /api/me — met à jour le profil de l'utilisateur connecté.
  Future<void> updateProfile({
    required String firstname,
    required String lastname,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/me'),
        headers: _authHeaders,
        body: json.encode({
          'firstname': firstname,
          'lastname': lastname,
        }),
      );
      if (response.statusCode != 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(body['error'] ?? 'Erreur lors de la mise à jour');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.updateProfile error: $e');
      throw Exception('Impossible de joindre le serveur');
    }
  }

  // ------------------------------------------------------------------
  // Moderation
  // ------------------------------------------------------------------

  Future<List<MockResource>> fetchPendingResources() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/moderation/pending'),
            headers: _authHeaders,
          )
          ;

      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body);
        return items
            .map((item) => _pendingFromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchPendingResources error: $e');
    }
    return [];
  }

  Future<bool> validateResource(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/moderation/validate/$id'),
            headers: _authHeaders,
          )
          ;
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.validateResource error: $e');
      return false;
    }
  }

  Future<bool> suspendResource(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/moderation/suspend/$id'),
            headers: _authHeaders,
          )
          ;
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.suspendResource error: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // JSON converters
  // ------------------------------------------------------------------

  MockResource _resourceFromJson(Map<String, dynamic> j) {
    final rawMedia = j['media'] as String?;
    final resolvedMedia = _resolveMediaUrl(rawMedia);
    return MockResource(
      id: j['id']?.toString() ?? '0',
      title: j['titre'] ?? '',
      category: j['category'] ?? 'Autre',
      type: _mapType(j['type_ressource'] ?? j['type']),
      visibility: _mapVisibility(j['visibilite']),
      progressStatus: 'A voir',
      description: j['description'] ?? '',
      author: j['createur'] ?? 'Anonyme',
      content: j['contenu'] ?? '',
      status: j['statut'] ?? 'publie',
      link: (j['lien'] as String?)?.isNotEmpty == true ? j['lien'] as String : null,
      mediaUrl: resolvedMedia.isNotEmpty ? resolvedMedia : null,
    );
  }

  /// Résout un chemin media relatif en URL complète (identique à getMediaUrl() web).
  String _resolveMediaUrl(String? media) {
    if (media == null || media.isEmpty) return '';
    if (media.startsWith('http://') || media.startsWith('https://')) return media;
    return '$_baseUrl/api/resources/download/$media';
  }

  MockResource _pendingFromJson(Map<String, dynamic> j) {
    return MockResource(
      id: j['id']?.toString() ?? '0',
      title: j['titre'] ?? '',
      category: 'Autre',
      type: 'Article',
      visibility: 'Public',
      progressStatus: 'A voir',
      description: 'Soumis par ${j['createur'] ?? 'inconnu'}',
      author: j['createur'] ?? 'Anonyme',
      content: '',
      status: 'en attente',
    );
  }

  MockCategory _categoryFromJson(Map<String, dynamic> j) {
    final name = j['nom'] ?? j['name'] ?? '';
    return MockCategory(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      label: name,
      icon: _categoryIcon(name),
    );
  }

  Comment _commentFromJson(Map<String, dynamic> j, String resourceId) {
    return Comment(
      id: j['id']?.toString() ?? '0',
      resourceId: resourceId,
      author: j['author'] ?? j['auteur'] ?? 'Anonyme',
      text: j['content'] ?? j['contenu'] ?? '',
      createdAt: DateTime.tryParse(
            (j['createdAt'] ?? j['created_at'] ?? '').toString(),
          ) ?? DateTime.now(),
      reportCount: (j['report_count'] as num?)?.toInt() ?? 0,
      rating: (j['note'] ?? j['rating'] as num?)?.toInt() ?? 0,
    );
  }

  String _mapType(String? type) {
    switch (type?.toLowerCase()) {
      case 'article':
        return 'Article';
      case 'video':
        return 'Video';
      case 'podcast':
        return 'Podcast';
      case 'activite':
        return 'Exercice';
      case 'jeu':
        return 'Jeu';
      default:
        return type ?? 'Article';
    }
  }

  String _mapVisibility(String? vis) {
    switch (vis?.toLowerCase()) {
      case 'prive':
      case 'private':
        return 'Prive';
      case 'partage':
        return 'Partage';
      case 'public':
      case 'publie':
        return 'Public';
      default:
        return vis ?? 'Public';
    }
  }

  IconData _categoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'famille':
        return Icons.family_restroom_rounded;
      case 'couple':
        return Icons.favorite_rounded;
      case 'travail':
        return Icons.work_outline_rounded;
      case 'amis':
      case 'amitie':
      case 'amitié':
        return Icons.group_outlined;
      case 'bien-etre':
      case 'bien-être':
        return Icons.self_improvement_rounded;
      case 'parentalite':
      case 'parentalité':
        return Icons.child_care_rounded;
      case 'developpement personnel':
      case 'développement personnel':
        return Icons.psychology_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}
