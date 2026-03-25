import 'package:flutter/material.dart';

// shows a bottom sheet modal with app information.
Future<void> showInfoModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _InfoSheet(),
  );
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(160);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(51),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // logo
            ClipOval(
              child: Image.asset('locate.png', width: 64, height: 64,
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Text(
              'LocaTe',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: 4),
            Text(
              'Transportes Públicos do Porto',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 24),

            // about section
            _InfoSection(
              icon: Icons.info_outline_rounded,
              title: 'Sobre',
              body:
                  'Aplicação criada de utilizador de transportes públicos para utilizador de transportes públicos. '
                  'O objetivo é facilitar o dia a dia de quem depende dos transportes na área do Porto.',
            ),
            const SizedBox(height: 16),

            // stcp disclaimer
            _InfoSection(
              icon: Icons.directions_bus_rounded,
              title: 'Autocarros STCP',
              body:
                  'A app utiliza o acesso à localização dos autocarros para calcular os tempos de chegada. '
                  'Devido à natureza dos dados em tempo real, é esperada uma margem de erro de alguns minutos. '
                  'Agradecemos a tua paciência.',
            ),
            const SizedBox(height: 16),

            // metro disclaimer
            _InfoSection(
              icon: Icons.subway_rounded,
              title: 'Metro do Porto',
              body:
                  'Os horários do metro são obtidos a partir dos horários oficiais do Metro do Porto. '
                  'Podem estar desatualizados caso haja alterações recentes nos serviços.',
            ),
            const SizedBox(height: 16),

            // fun fact
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 20, color: Colors.amber[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fun Fact',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'O nome "LocaTe" não vem do inglês! Vem de "Locomover" e "Desloca-te". '
                          'A forma correta de ler é "Lóca-te". 😉',
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // last update
            Text(
              'Última atualização: março de 2026',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'v1.0.0',
              style: TextStyle(fontSize: 11, color: muted.withAlpha(100)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(160),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
