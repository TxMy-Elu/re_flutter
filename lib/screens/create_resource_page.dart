// ============================================================
// create_resource_page.dart — Creation d'une ressource
// FP4 + RG-RES-01 (workflow de publication) + RG-PRIV-01 (3 niveaux)
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';
import '../services/api_service.dart';

class CreateResourcePage extends StatefulWidget {
  const CreateResourcePage({super.key});

  @override
  State<CreateResourcePage> createState() => _CreateResourcePageState();
}

class _CreateResourcePageState extends State<CreateResourcePage> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  static const _types = [
    {'value': 'article', 'label': 'Article', 'icon': Icons.article_outlined},
    {'value': 'video', 'label': 'Video', 'icon': Icons.play_circle_outline_rounded},
    {'value': 'podcast', 'label': 'Podcast', 'icon': Icons.podcasts_rounded},
    {'value': 'activite', 'label': 'Activite', 'icon': Icons.fitness_center_rounded},
    {'value': 'jeu', 'label': 'Jeu', 'icon': Icons.sports_esports_rounded},
  ];

  static const _visibilities = [
    {'value': 'prive', 'label': 'Privee', 'icon': Icons.lock_outline_rounded, 'description': 'Visible uniquement par vous'},
    {'value': 'partage', 'label': 'Partagee', 'icon': Icons.group_outlined, 'description': 'Visible par un groupe restreint'},
    {'value': 'public', 'label': 'Publique', 'icon': Icons.public_rounded, 'description': 'Soumis a moderation avant publication'},
  ];

  String _type = 'article';
  String _visibility = 'public';
  MockCategory? _category;
  List<MockCategory> _categories = [];
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    final cats = await _api.fetchCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _category = cats.isNotEmpty ? cats.first : null;
      _loading = false;
    });
  }

  Future<void> _handleSubmit() async {
    // RG-RES-02 : categorie obligatoire (implicitement validee via dropdown)
    if (!_formKey.currentState!.validate() || _category == null) return;

    setState(() => _saving = true);

    try {
      await _api.createResource(
        titre: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        contenu: _contentController.text.trim(),
        type: _type,
        visibilite: _visibility,
        categoryId: _category!.id,
      );

      if (!mounted) return;
      setState(() => _saving = false);

      // RG-RES-01 : les ressources publiques passent en "en attente"
      final message = _visibility == 'public'
          ? 'Ressource envoyée ! En attente de validation par un modérateur.'
          : 'Ressource enregistrée avec succès.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle ressource'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildLabel('Titre'),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'Donnez un titre clair et precis',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Le titre est requis'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Description'),
                  _buildTextField(
                    controller: _descriptionController,
                    hint: 'Resumez la ressource en quelques phrases',
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'La description est requise'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Contenu complet'),
                  _buildTextField(
                    controller: _contentController,
                    hint: 'Texte de l\'article, lien, consigne...',
                    maxLines: 8,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Le contenu est requis'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  _buildLabel('Type de ressource'),
                  _buildTypeSelector(),
                  const SizedBox(height: 22),
                  _buildLabel('Categorie'),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 22),
                  _buildLabel('Visibilite'),
                  _buildVisibilitySelector(),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ------------------------------------------------------------------
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines > 1 ? 2 : 1,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE2EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _types.map((t) {
        final selected = _type == t['value'];
        return GestureDetector(
          onTap: () => setState(() => _type = t['value'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    selected ? AppColors.primary : const Color(0xFFDDE2EA),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  t['icon'] as IconData,
                  size: 16,
                  color: selected ? AppColors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  t['label'] as String,
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE2EA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MockCategory>(
          isExpanded: true,
          value: _category,
          items: _categories
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(c.label),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (c) => setState(() => _category = c),
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return Column(
      children: _visibilities.map((v) {
        final selected = _visibility == v['value'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _visibility = v['value'] as String),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFDDE2EA),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      v['icon'] as IconData,
                      color:
                          selected ? AppColors.white : AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v['label'] as String,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          v['description'] as String,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Publier la ressource',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
