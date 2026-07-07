// ============================================================
// main.dart — Point d'entree de l'application
// (RE)Sources Relationnelles
// ============================================================

import 'package:flutter/material.dart';
import 'screens/dashboard_page.dart';
import 'screens/home_page.dart';
import 'screens/resource_list_page.dart';
import 'screens/profile_page.dart';
import 'screens/login_page.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().restore();
  await StorageService().load();
  runApp(const RessourcesRelationnellesApp());
}

// ------------------------------------------------------------------
// Charte graphique — constantes de couleurs
// (couleurs officielles du cahier des charges)
// ------------------------------------------------------------------
class AppColors {
  static const Color primary = Color(0xFF1F4E79);     // Bleu principal
  static const Color accent = Color(0xFFF2B73F);      // Jaune / Or
  static const Color white = Color(0xFFFFFFFF);       // Blanc
  static const Color background = Color(0xFFF0F2F5);  // Fond clair
  static const Color textDark = Color(0xFF1A2B3C);    // Texte sombre
  static const Color textMuted = Color(0xFF7A8FA6);   // Texte secondaire
  static const Color cardShadow = Color(0x14000000);  // Ombre legere
  static const Color success = Color(0xFF2E7D32);     // Vert (Exploite)
  static const Color warning = Color(0xFFE65100);     // Orange (Consulte)
  static const Color info = Color(0xFF1565C0);        // Bleu clair (A voir)
}

// ------------------------------------------------------------------
// Application principale
// ------------------------------------------------------------------
class RessourcesRelationnellesApp extends StatelessWidget {
  const RessourcesRelationnellesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '(RE)Sources Relationnelles',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // Si un utilisateur est deja connecte on saute l'ecran de login.
      home: AuthService().isLoggedIn
          ? const MainScaffold()
          : const LoginPage(),
    );
  }

  /// Theme Material 3 aligne sur la charte graphique
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: Color(0xFFDDE2EA)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textDark,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.textDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

// ------------------------------------------------------------------
// Scaffold principal avec BottomNavigationBar
// ------------------------------------------------------------------
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final _auth = AuthService();

  /// Les quatre ecrans principaux de l'application
  final List<Widget> _screens = const [
    HomePage(),
    ResourceListPage(),
    DashboardPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChange);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books_rounded),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Mon espace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
