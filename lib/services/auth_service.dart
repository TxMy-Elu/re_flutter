import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

enum UserRole { citoyenNonConnecte, citoyenConnecte, moderateur, administrateur }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.citoyenNonConnecte:
        return 'Citoyen non connecte';
      case UserRole.citoyenConnecte:
        return 'Citoyen connecte';
      case UserRole.moderateur:
        return 'Moderateur';
      case UserRole.administrateur:
        return 'Administrateur';
    }
  }

  String get short {
    switch (this) {
      case UserRole.citoyenNonConnecte:
        return 'Visiteur';
      case UserRole.citoyenConnecte:
        return 'Citoyen';
      case UserRole.moderateur:
        return 'Moderateur';
      case UserRole.administrateur:
        return 'Administrateur';
    }
  }

  bool get canContribute => this != UserRole.citoyenNonConnecte;
  bool get canModerate =>
      this == UserRole.moderateur || this == UserRole.administrateur;
  bool get canAdmin => this == UserRole.administrateur;
}

class AuthUser {
  final String name;
  final String email;
  final UserRole role;
  final int? id;

  const AuthUser({
    required this.name,
    required this.email,
    required this.role,
    this.id,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const _kName = 'auth_name';
  static const _kEmail = 'auth_email';
  static const _kRole = 'auth_role';
  static const _kLoggedIn = 'auth_logged_in';
  static const _kToken = 'auth_token';
  static const _kUserId = 'auth_user_id';

  AuthUser? _user;
  AuthUser? get user => _user;

  UserRole get role => _user?.role ?? UserRole.citoyenNonConnecte;
  bool get isLoggedIn =>
      _user != null && _user!.role != UserRole.citoyenNonConnecte;

  /// Charge les données persistées et vérifie le token auprès de l'API.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kLoggedIn) != true) {
      _user = null;
      return;
    }

    final token = prefs.getString(_kToken);
    if (token != null) {
      ApiService().setToken(token);
      final me = await ApiService().fetchMe();
      if (me != null) {
        final user = _userFromApiMe(me);
        _user = user;
        await _persist(user, token);
        notifyListeners();
        return;
      }
      // Token expiré — on efface
      ApiService().setToken(null);
    }

    // Fallback sur les données locales (token absent ou expiré)
    final name = prefs.getString(_kName) ?? '';
    final email = prefs.getString(_kEmail) ?? '';
    if (name.isEmpty && email.isEmpty) {
      _user = null;
      return;
    }
    final roleStr = prefs.getString(_kRole) ?? UserRole.citoyenConnecte.name;
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.citoyenConnecte,
    );
    _user = AuthUser(name: name, email: email, role: role);
    notifyListeners();
  }

  /// Connexion via l'API. Lance une Exception avec le message d'erreur en cas d'échec.
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final token = await ApiService().login(email: email, password: password);
    final me = await ApiService().fetchMe();
    if (me == null) throw Exception('Impossible de récupérer le profil');

    final user = _userFromApiMe(me);
    await _persist(user, token);
    _user = user;
    notifyListeners();
    return user;
  }

  /// Inscription via l'API. Lance une Exception avec le message d'erreur en cas d'échec.
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String role = 'parent',
  }) async {
    final token = await ApiService().register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    final me = await ApiService().fetchMe();

    final AuthUser user;
    if (me != null) {
      user = _userFromApiMe(me);
    } else {
      // Le compte a bien été créé — on construit l'utilisateur depuis les données saisies
      user = AuthUser(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: UserRole.citoyenConnecte,
      );
    }

    await _persist(user, token);
    _user = user;
    notifyListeners();
    return user;
  }

  /// Déconnexion : efface le token et les données persistées.
  Future<void> logout() async {
    await ApiService().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.setBool(_kLoggedIn, false);
    _user = null;
    notifyListeners();
  }

  /// Change de rôle (pour la démo du prototype).
  Future<void> setRole(UserRole role) async {
    final current = _user;
    if (current == null) return;
    final updated = AuthUser(
      name: current.name,
      email: current.email,
      role: role,
      id: current.id,
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    await _persist(updated, token);
    _user = updated;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  AuthUser _userFromApiMe(Map<String, dynamic> me) {
    final roles = (me['roles'] as List<dynamic>?) ?? [];
    final firstName = (me['firstname'] as String?) ?? '';
    final lastName = (me['lastname'] as String?) ?? '';
    final name = '$firstName $lastName'.trim().isNotEmpty
        ? '$firstName $lastName'.trim()
        : (me['email'] as String? ?? 'Utilisateur');

    return AuthUser(
      name: name,
      email: (me['email'] as String?) ?? '',
      role: _roleFromApiRoles(roles),
      id: (me['id'] as num?)?.toInt(),
    );
  }

  UserRole _roleFromApiRoles(List<dynamic> roles) {
    final strs = roles.map((r) => r.toString().toUpperCase()).toList();
    if (strs.contains('ROLE_SUPER_ADMIN')) return UserRole.administrateur;
    if (strs.contains('ROLE_ADMIN')) return UserRole.administrateur;
    if (strs.contains('ROLE_MODERATOR')) return UserRole.moderateur;
    // ROLE_CONNECTED et ROLE_USER sont tous deux des citoyens connectés
    return UserRole.citoyenConnecte;
  }

  Future<void> _persist(AuthUser user, String? token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, user.name);
    await prefs.setString(_kEmail, user.email);
    await prefs.setString(_kRole, user.role.name);
    await prefs.setBool(_kLoggedIn, true);
    if (token != null) await prefs.setString(_kToken, token);
    if (user.id != null) await prefs.setInt(_kUserId, user.id!);
  }
}
