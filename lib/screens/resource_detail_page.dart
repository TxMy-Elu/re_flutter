// ============================================================
// resource_detail_page.dart — Detail complet d'une ressource
// FP1 : Afficher le contenu complet + FS1 commentaires + FS2 progression/favoris
// ============================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../mock_data.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class ResourceDetailPage extends StatefulWidget {
  final MockResource resource;

  const ResourceDetailPage({super.key, required this.resource});

  @override
  State<ResourceDetailPage> createState() => _ResourceDetailPageState();
}

class _ResourceDetailPageState extends State<ResourceDetailPage> {
  final _api = ApiService();
  final _storage = StorageService();
  final _auth = AuthService();
  final _commentController = TextEditingController();

  MockResource? _resource;
  bool _loadingContent = false;

  // Commentaires chargés depuis l'API
  List<Comment> _apiComments = [];
  bool _commentsLoading = false;

  // Note sélectionnée pour le prochain commentaire (1-5 étoiles)
  int _commentRating = 5;

  // Favori : état local optimiste synchro avec l'API
  bool? _isFavorite; // null = non encore chargé (utilise local en attendant)

  @override
  void initState() {
    super.initState();
    _resource = widget.resource;
    _storage.addListener(_onChange);
    _auth.addListener(_onChange);
    _maybeFetchDetail();
    _loadComments();
  }

  @override
  void dispose() {
    _storage.removeListener(_onChange);
    _auth.removeListener(_onChange);
    _commentController.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  /// Tente de recuperer le contenu complet via l'API si l'id est numerique.
  Future<void> _maybeFetchDetail() async {
    final intId = int.tryParse(widget.resource.id);
    if (intId == null || widget.resource.content.isNotEmpty) return;

    setState(() => _loadingContent = true);
    final fetched = await _api.fetchResource(intId);
    if (!mounted) return;
    setState(() {
      _loadingContent = false;
      if (fetched != null) _resource = fetched;
    });
  }

  /// Charge les commentaires depuis l'API.
  Future<void> _loadComments() async {
    final intId = int.tryParse(widget.resource.id);
    if (intId == null) return;
    setState(() => _commentsLoading = true);
    final comments = await _api.fetchComments(intId);
    if (!mounted) return;
    setState(() {
      _apiComments = comments;
      _commentsLoading = false;
    });
  }

  /// Toggle favori : met à jour localement (UI immédiate) + appel API.
  Future<void> _toggleFavorite() async {
    final intId = int.tryParse(_resource!.id);
    // Mise à jour optimiste locale
    final wasLocal = _storage.isFavorite(_resource!.id);
    await _storage.toggleFavorite(_resource!.id);
    setState(() => _isFavorite = !wasLocal);
    // Appel API si connecté et id numérique
    if (_auth.isLoggedIn && intId != null) {
      await _api.toggleSave(intId);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!wasLocal ? 'Ajouté aux favoris' : 'Retiré des favoris'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _resource!;
    // Favori : état API si chargé, sinon état local
    final isFavorite = _isFavorite ?? _storage.isFavorite(r.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(r, isFavorite),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMeta(r),
                  const SizedBox(height: 20),
                  _buildDescription(r),
                  const SizedBox(height: 24),
                  _buildContent(r),
                  const SizedBox(height: 24),
                  _buildResourceLink(r),
                  const SizedBox(height: 24),
                  _buildCommentsSection(r),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  SliverAppBar _buildAppBar(MockResource r, bool isFavorite) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: AppColors.white),
      actions: [
        if (_auth.isLoggedIn)
          IconButton(
            tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.accent : AppColors.white,
            ),
            onPressed: _toggleFavorite,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF163A5F)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 16, 56, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.type.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildMeta(MockResource r) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(r.category, Icons.folder_outlined, AppColors.primary),
        _chip(r.visibility, _visibilityIcon(r.visibility), AppColors.info),
        _chip('Par ${r.author}', Icons.person_outline_rounded,
            AppColors.textMuted),
      ],
    );
  }

  IconData _visibilityIcon(String v) {
    switch (v) {
      case 'Public':
        return Icons.public_rounded;
      case 'Partage':
      case 'Partagé':
        return Icons.group_outlined;
      default:
        return Icons.lock_outline_rounded;
    }
  }

  Widget _chip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            text,
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

  // ------------------------------------------------------------------
  Widget _buildDescription(MockResource r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
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
          const _SectionLabel(title: 'Description'),
          const SizedBox(height: 8),
          Text(
            r.description,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MockResource r) {
    if (_loadingContent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final content = r.content.isNotEmpty
        ? r.content
        : 'Le contenu complet de cette ressource sera disponible prochainement.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
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
          const _SectionLabel(title: 'Contenu'),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Bouton média contextuel — toujours affiché, calqué sur MediaButton web
  Widget _buildResourceLink(MockResource r) {
    final kind = r.mediaKind;   // 'pdf'|'video'|'podcast'|'url'|null
    final url  = r.actionUrl ?? '';
    final hasMedia = url.isNotEmpty;

    // Paramètres visuels selon le type
    IconData icon;
    String label;
    String sectionTitle;
    Color color;

    if (!hasMedia) {
      // Aucun fichier ni lien — état désactivé
      icon = Icons.link_off_rounded;
      label = 'Aucun lien disponible';
      sectionTitle = 'Accès à la ressource';
      color = AppColors.textMuted;
    } else {
      switch (kind) {
        case 'pdf':
          icon = Icons.download_rounded;
          label = 'Télécharger le PDF';
          sectionTitle = 'Fichier PDF';
          color = const Color(0xFFB71C1C);
        case 'video':
          icon = Icons.play_circle_filled_rounded;
          label = 'Regarder la vidéo';
          sectionTitle = 'Vidéo';
          color = AppColors.primary;
        case 'podcast':
          icon = Icons.headphones_rounded;
          label = 'Écouter le podcast';
          sectionTitle = 'Podcast audio';
          color = const Color(0xFF7B1FA2);
        default:
          icon = Icons.open_in_new_rounded;
          label = 'Consulter la ressource';
          sectionTitle = 'Lien externe';
          color = AppColors.primary;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
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
          _SectionLabel(title: sectionTitle),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasMedia ? () => _openLink(url) : null,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.background,
                disabledForegroundColor: AppColors.textMuted,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (hasMedia) ...[
            const SizedBox(height: 8),
            Text(
              url,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Le contenu de cette ressource n\'est pas encore disponible en téléchargement.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir ce lien.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ------------------------------------------------------------------
  // Commentaires — chargés depuis l'API
  Widget _buildCommentsSection(MockResource r) {
    final comments = _apiComments;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
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
          _SectionLabel(
            title: 'Commentaires (${comments.length})',
          ),
          const SizedBox(height: 12),
          if (r.visibility != 'Public')
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Les commentaires ne sont disponibles que sur les ressources publiques.',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ),
            ),
          if (r.visibility == 'Public' && _auth.isLoggedIn) ...[
            _buildCommentInput(r),
            const SizedBox(height: 14),
          ] else if (r.visibility == 'Public' && !_auth.isLoggedIn)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Connectez-vous pour participer à la discussion.',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ),
            ),
          if (_commentsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (comments.isEmpty)
            const Text(
              'Aucun commentaire pour le moment.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            )
          else
            ...comments
                .where((c) => !_storage.isHidden(c.id))
                .map((c) => _buildCommentTile(c)),
        ],
      ),
    );
  }

  Widget _buildCommentInput(MockResource r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélecteur d'étoiles
        Row(
          children: [
            const Text(
              'Note :',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            ...List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _commentRating = star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    star <= _commentRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 26,
                    color: star <= _commentRating
                        ? AppColors.accent
                        : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),
        // Champ texte + bouton envoyer
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Écrire un commentaire...',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _postComment(r),
              icon: const Icon(Icons.send_rounded),
              color: AppColors.primary,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _postComment(MockResource r) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final intId = int.tryParse(r.id);
    if (intId == null) return;

    _commentController.clear();

    final ok = await _api.addComment(intId, text, rating: _commentRating);
    if (!mounted) return;

    if (ok) {
      setState(() => _commentRating = 5); // réinitialise les étoiles
      await _loadComments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi du commentaire.'),
          backgroundColor: Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildCommentTile(Comment c) {
    final hidden = _storage.isHidden(c.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hidden
              ? const Color(0xFFFFF3E0)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: hidden
              ? Border.all(color: AppColors.warning, width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.author,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (c.rating > 0)
                        Row(
                          children: List.generate(5, (i) => Icon(
                            i < c.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 13,
                            color: i < c.rating
                                ? AppColors.accent
                                : AppColors.textMuted,
                          )),
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(c.createdAt),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hidden)
              const Text(
                'Contenu masque suite a plusieurs signalements.',
                style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              )
            else
              Text(
                c.text,
                style: const TextStyle(
                    color: AppColors.textDark, fontSize: 13, height: 1.45),
              ),
            if (_auth.isLoggedIn && !hidden) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _storage.isReported(c.id)
                      ? null
                      : () {
                          _storage.reportComment(c.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Commentaire signalé'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                  icon: Icon(
                    _storage.isReported(c.id)
                        ? Icons.flag_rounded
                        : Icons.flag_outlined,
                    size: 14,
                  ),
                  label: Text(
                      _storage.isReported(c.id) ? 'Signalé' : 'Signaler'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB71C1C),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    textStyle: const TextStyle(fontSize: 11),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return "a l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ------------------------------------------------------------------
// Sous-widgets
// ------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

