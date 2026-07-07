// ============================================================
// help_page.dart — Aide, tutoriels et FAQ
// FS4 : Aide integree et tutoriels
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const List<_Faq> _faqs = [
    _Faq(
      question: 'Qu\'est-ce que (RE)Sources Relationnelles ?',
      answer:
          'Une plateforme publique qui met a disposition de tous les citoyens un catalogue '
          'de ressources (articles, videos, podcasts, activites, jeux) pour renforcer '
          'les liens sociaux au sein du cercle familial, amical ou professionnel.',
    ),
    _Faq(
      question: 'Comment creer un compte ?',
      answer:
          "Rendez-vous sur l'ecran Connexion puis \"S'inscrire\". Un email valide et unique est "
          'requis. Votre compte est active directement pour tester le prototype.',
    ),
    _Faq(
      question: 'Comment publier une ressource ?',
      answer:
          'Depuis la page d\'accueil, appuyez sur le bouton "+" pour creer une nouvelle ressource. '
          'Si vous choisissez la visibilite "Publique", votre contribution sera soumise a un '
          'moderateur avant publication (workflow RG-RES-01).',
    ),
    _Faq(
      question: 'Que signifient les etats "A voir", "Consulte", "Exploite" ?',
      answer:
          'Ce sont les trois etats du suivi personnel. "A voir" : vous avez mis la ressource de cote. '
          '"Consulte" : vous l\'avez consultee. "Exploite" : vous l\'avez mise en pratique (RG-SUIVI-01).',
    ),
    _Faq(
      question: 'Comment signaler un commentaire ?',
      answer:
          'Sur la page de detail, appuyez sur "Signaler" sous le commentaire. A partir de 3 signalements, '
          'le commentaire est automatiquement masque et transmis aux moderateurs (RG-COM-01).',
    ),
    _Faq(
      question: 'Quels niveaux de visibilite pour une ressource ?',
      answer:
          'Trois niveaux (RG-PRIV-01) : Privee (visible uniquement par vous), Partagee '
          '(visible par un groupe restreint sur invitation), Publique (soumise a moderation).',
    ),
    _Faq(
      question: 'Mes donnees sont-elles protegees ?',
      answer:
          'Oui. La plateforme est conforme au RGPD : vos donnees personnelles sont chiffrees, '
          'vous pouvez demander leur suppression a tout moment (droit a l\'oubli) et aucune '
          'statistique ne permet de vous identifier (RG-STAT-01).',
    ),
    _Faq(
      question: 'L\'application est-elle accessible ?',
      answer:
          'La plateforme respecte le Referentiel General d\'Amelioration de l\'Accessibilite (RGAA) : '
          'contrastes renforces, navigation clavier, compatibilite lecteurs d\'ecran, alternatives textuelles.',
    ),
  ];

  static const List<_Tutorial> _tutorials = [
    _Tutorial(
      icon: Icons.search_rounded,
      title: 'Explorer le catalogue',
      description:
          'Filtrez les ressources par categorie ou type de contenu depuis la page Catalogue.',
    ),
    _Tutorial(
      icon: Icons.bookmark_rounded,
      title: 'Suivre sa progression',
      description:
          'Sur une ressource, choisissez "A voir", "Consulte" ou "Exploite" pour suivre votre parcours.',
    ),
    _Tutorial(
      icon: Icons.edit_note_rounded,
      title: 'Partager une ressource',
      description:
          'Appuyez sur le bouton "+" de l\'accueil pour publier votre propre contenu.',
    ),
    _Tutorial(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Echanger avec la communaute',
      description:
          'Commentez les ressources publiques pour enrichir les echanges autour du sujet.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aide & Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildIntro(),
          const SizedBox(height: 24),
          _buildSectionTitle('Tutoriels rapides'),
          const SizedBox(height: 12),
          ..._tutorials.map((t) => _buildTutorialTile(t)),
          const SizedBox(height: 28),
          _buildSectionTitle('Questions frequentes'),
          const SizedBox(height: 12),
          ..._faqs.map((f) => _FaqTile(faq: f)),
          const SizedBox(height: 28),
          _buildContactCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF163A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: AppColors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Besoin d\'aide ?',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Retrouvez ici les tutoriels pour prendre en main l\'application '
            'et les reponses aux questions les plus frequentes.',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialTile(_Tutorial t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(t.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.description,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signaler un defaut d\'accessibilite',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vous rencontrez un obstacle a l\'utilisation de la plateforme ? '
            'Contactez-nous a accessibilite@resources.fr pour que nous puissions corriger le probleme.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq({required this.question, required this.answer});
}

class _Tutorial {
  final IconData icon;
  final String title;
  final String description;
  const _Tutorial({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const Border(),
            title: Text(
              widget.faq.question,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onExpansionChanged: (e) => setState(() => _expanded = e),
            trailing: Icon(
              _expanded
                  ? Icons.remove_circle_outline_rounded
                  : Icons.add_circle_outline_rounded,
              color: AppColors.primary,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  widget.faq.answer,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
