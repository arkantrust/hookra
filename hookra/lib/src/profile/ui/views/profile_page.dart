import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/profile/domain/entities/user.dart';
import 'package:hookra/src/settings/settings.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static GoRoute route() =>
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage());

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final palette = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: palette.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: palette.surface,
        leading: Icon(Icons.menu, color: palette.onSurface),
        titleSpacing: 0,
        title: Text(
          'PERFIL',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 16,
            color: palette.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AvatarChip(user: user, palette: palette, radius: 18),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileCard(user: user, palette: palette),
            const SizedBox(height: 12),
            _AiInsightsCard(palette: palette),
            const SizedBox(height: 20),
            _SectionLabel('CONTEXTO PROFESIONAL'),
            const SizedBox(height: 8),
            _OrganizationCard(palette: palette),
            const SizedBox(height: 8),
            _ProjectCard(
              tag: 'ESTRATEGIA',
              tagColor: palette.primary,
              title: 'Estrategia en Redes Sociales',
              description:
                  'Orquestando flujos narrativos multicanal con análisis avanzado de sentimientos.',
              members: const ['JD', 'ML'],
              extraCount: 4,
              palette: palette,
            ),
            const SizedBox(height: 8),
            _ProjectCard(
              tag: 'IA & DEV',
              tagColor: Colors.indigo,
              title: 'Equipo IA de Contenido',
              description:
                  'Integrando modelos generativos en flujos de producción a escala y precisión.',
              members: const ['AS', 'KB'],
              extraCount: 2,
              palette: palette,
            ),
            const SizedBox(height: 20),
            _SectionLabel('PERFORMANCE & IMPACTO'),
            const SizedBox(height: 8),
            _CampaignScoreCard(palette: palette),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.history_rounded,
                    value: '14',
                    label: 'BORRADORES\nACTIVOS',
                    palette: palette,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    value: '1.2k',
                    label: 'ALCANCE\nTOTAL',
                    palette: palette,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _AvatarChip extends StatelessWidget {
  final User user;
  final ColorScheme palette;
  final double radius;

  const _AvatarChip({
    required this.user,
    required this.palette,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: palette.primaryContainer,
      child: user.avatarUrl != null
          ? ClipOval(
              child: AvifImage.network(
                user.avatarUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  size: radius,
                  color: palette.onPrimaryContainer,
                ),
              ),
            )
          : Icon(Icons.person, size: radius, color: palette.onPrimaryContainer),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final User user;
  final ColorScheme palette;

  const _ProfileCard({required this.user, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: palette.surfaceContainerHighest,
                  child: ClipOval(
                    child: user.avatarUrl != null
                        ? AvifImage.network(
                            user.avatarUrl!,
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 56,
                              color: palette.onSurfaceVariant,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 56,
                            color: palette.onSurfaceVariant,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surface, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 14,
                      color: palette.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${user.firstName} ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: palette.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: user.lastName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'DIRECTOR DE MARKETING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: palette.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(EditProfilePage.route().path),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar Perfil'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiInsightsCard extends StatelessWidget {
  final ColorScheme palette;
  const _AiInsightsCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: palette.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 15, color: palette.primary),
              const SizedBox(width: 6),
              Text(
                'IA INSIGHTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: palette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tu engagement de contenido aumentó un 24% desde que te uniste al Equipo IA de Contenido. Considera actualizar tu portafolio.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: palette.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  final ColorScheme palette;
  const _OrganizationCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: palette.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              'A',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
            ),
          ),
        ),
        title: Text(
          'Agencia Creativa Aura',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: palette.onSurface,
          ),
        ),
        subtitle: Text(
          'Branding Premium & Estrategia de Contenido IA',
          style: TextStyle(fontSize: 12, color: palette.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right, color: palette.onSurfaceVariant),
        onTap: () {},
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final String title;
  final String description;
  final List<String> members;
  final int extraCount;
  final ColorScheme palette;

  const _ProjectCard({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.description,
    required this.members,
    required this.extraCount,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: tagColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.more_horiz,
                  color: palette.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: palette.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ...members.map(
                  (m) => Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: palette.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surface, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        m,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: palette.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.surface, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '+$extraCount',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignScoreCard extends StatelessWidget {
  final ColorScheme palette;
  const _CampaignScoreCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.trending_up_rounded, color: palette.onPrimary, size: 24),
          const SizedBox(height: 8),
          Text(
            '92%',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: palette.onPrimary,
            ),
          ),
          Text(
            'PUNTAJE DE CAMPAÑA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              color: palette.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ColorScheme palette;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: palette.onSurfaceVariant, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: palette.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: palette.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
