import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mock_data.dart';

/// Progression RG-SUIVI-01 : "A voir", "Consulte", "Exploite".
enum Progression { aVoir, consulte, exploite }

extension ProgressionX on Progression {
  String get label {
    switch (this) {
      case Progression.aVoir:
        return 'A voir';
      case Progression.consulte:
        return 'Consulte';
      case Progression.exploite:
        return 'Exploite';
    }
  }
}

/// Persistence locale pour les fonctionnalites non couvertes par l'API :
/// favoris, progression, commentaires, signalements, notifications.
class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  static const _kFavorites = 'favorites_ids';
  static const _kProgression = 'progression_map'; // id -> label
  static const _kComments = 'comments_list';
  static const _kReports = 'reported_comment_ids';
  static const _kNotificationsRead = 'notifications_read_ids';

  Set<String> _favorites = {};
  Map<String, Progression> _progression = {};
  List<Comment> _comments = [];
  Set<String> _reports = {};
  Set<String> _notificationsRead = {};

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    _favorites = (prefs.getStringList(_kFavorites) ?? const []).toSet();

    final progJson = prefs.getString(_kProgression);
    if (progJson != null && progJson.isNotEmpty) {
      try {
        final map = json.decode(progJson) as Map<String, dynamic>;
        _progression = map.map(
          (k, v) => MapEntry(
            k,
            Progression.values.firstWhere(
              (p) => p.name == v,
              orElse: () => Progression.aVoir,
            ),
          ),
        );
      } catch (_) {
        _progression = {};
      }
    }

    final commentsJson = prefs.getString(_kComments);
    if (commentsJson != null && commentsJson.isNotEmpty) {
      try {
        final list = json.decode(commentsJson) as List<dynamic>;
        _comments =
            list.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _comments = [];
      }
    }

    _reports = (prefs.getStringList(_kReports) ?? const []).toSet();
    _notificationsRead =
        (prefs.getStringList(_kNotificationsRead) ?? const []).toSet();

    _loaded = true;
  }

  // ---------------- Favoris ----------------
  Set<String> get favoriteIds => Set.unmodifiable(_favorites);
  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> toggleFavorite(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavorites, _favorites.toList());
    notifyListeners();
  }

  // ---------------- Progression ----------------
  Progression? progressionFor(String id) => _progression[id];

  Future<void> setProgression(String id, Progression p) async {
    _progression[id] = p;
    final prefs = await SharedPreferences.getInstance();
    final map = _progression.map((k, v) => MapEntry(k, v.name));
    await prefs.setString(_kProgression, json.encode(map));
    notifyListeners();
  }

  Future<void> clearProgression(String id) async {
    _progression.remove(id);
    final prefs = await SharedPreferences.getInstance();
    final map = _progression.map((k, v) => MapEntry(k, v.name));
    await prefs.setString(_kProgression, json.encode(map));
    notifyListeners();
  }

  /// Stats agregees RG-STAT-01 (anonymes).
  Map<String, int> progressionStats() {
    int vues = 0, enCours = 0, exploitees = 0;
    for (final p in _progression.values) {
      switch (p) {
        case Progression.aVoir:
          enCours++;
          break;
        case Progression.consulte:
          vues++;
          break;
        case Progression.exploite:
          exploitees++;
          break;
      }
    }
    return {
      'vues': vues,
      'en_cours': enCours,
      'exploitees': exploitees,
    };
  }

  // ---------------- Commentaires ----------------
  List<Comment> commentsFor(String resourceId) =>
      _comments.where((c) => c.resourceId == resourceId).toList();

  Future<void> addComment(Comment c) async {
    _comments.add(c);
    await _persistComments();
    notifyListeners();
  }

  Future<void> deleteComment(String commentId) async {
    _comments.removeWhere((c) => c.id == commentId);
    _reports.remove(commentId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kReports, _reports.toList());
    await _persistComments();
    notifyListeners();
  }

  Future<void> _persistComments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kComments,
      json.encode(_comments.map((c) => c.toJson()).toList()),
    );
  }

  // ---------------- Signalements (RG-COM-01) ----------------
  static const int reportThreshold = 3;
  bool isReported(String commentId) => _reports.contains(commentId);

  /// Masque un commentaire signale plus de X fois.
  bool isHidden(String commentId) {
    final c = _comments.firstWhere(
      (x) => x.id == commentId,
      orElse: () => Comment(
        id: commentId,
        resourceId: '',
        author: '',
        text: '',
        createdAt: DateTime.now(),
      ),
    );
    return c.reportCount >= reportThreshold;
  }

  Future<void> reportComment(String commentId) async {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    final c = _comments[idx];
    _comments[idx] = Comment(
      id: c.id,
      resourceId: c.resourceId,
      author: c.author,
      text: c.text,
      createdAt: c.createdAt,
      reportCount: c.reportCount + 1,
    );
    _reports.add(commentId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kReports, _reports.toList());
    await _persistComments();
    notifyListeners();
  }

  List<Comment> flaggedComments() =>
      _comments.where((c) => c.reportCount >= reportThreshold).toList();

  // ---------------- Notifications ----------------
  bool isNotificationRead(String id) => _notificationsRead.contains(id);

  Future<void> markNotificationRead(String id) async {
    _notificationsRead.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kNotificationsRead, _notificationsRead.toList());
    notifyListeners();
  }
}
