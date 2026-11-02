import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../courses/presentation/course_providers.dart';
import '../../courses/domain/golf_hole.dart';
import 'round_providers.dart';

/// Immersive hole imagery. No invented fairway or contour geometry is shown.
class HoleViewScreen extends ConsumerStatefulWidget {
  const HoleViewScreen({required this.roundId, super.key});
  final String roundId;
  @override
  ConsumerState<HoleViewScreen> createState() => _HoleViewState();
}

class _HoleViewState extends ConsumerState<HoleViewScreen> {
  int? _preview;
  final _transform = TransformationController();
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = ref.watch(roundProvider(widget.roundId));
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Hole view'),
        actions: [
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: () => _transform.value = Matrix4.identity(),
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      body: round.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Round unavailable')),
        data: (r) {
          if (r == null) return const Center(child: Text('Round unavailable'));
          return ref
              .watch(courseHolesProvider(r.courseId))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Hole data unavailable')),
                data: (holes) {
                  final hole = holes
                      .where((h) => h.number == (_preview ?? r.currentHole))
                      .firstOrNull;
                  if (hole == null)
                    return const Center(child: Text('Hole data unavailable'));
                  final image = hole.imageUrl;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      InteractiveViewer(
                        transformationController: _transform,
                        minScale: 1,
                        maxScale: 5,
                        child: SizedBox.expand(
                          child: image != null && image.isNotEmpty
                              ? Image.network(
                                  image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => _missing(hole),
                                )
                              : _missing(hole),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Card(
                          color: AppTheme.darkNavy.withValues(alpha: .94),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Text(r.courseName, style: AppTheme.display(18)),
                                Text(
                                  'Hole ${hole.number} · Par ${hole.par} · Stroke index ${hole.strokeIndex}',
                                ),
                                if (hole.number != r.currentHole)
                                  Text(
                                    'Preview only · your group is playing hole ${r.currentHole}',
                                    style: AppTheme.body(
                                      11,
                                      colour: AppTheme.gold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 12,
                        right: 12,
                        child: SafeArea(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        tooltip: 'Previous hole preview',
                                        onPressed:
                                            holes.any(
                                              (h) =>
                                                  h.number == hole.number - 1,
                                            )
                                            ? () => _show(hole.number - 1)
                                            : null,
                                        icon: const Icon(Icons.chevron_left),
                                      ),
                                      Text(
                                        'Hole ${hole.number}',
                                        style: AppTheme.display(20),
                                      ),
                                      IconButton(
                                        tooltip: 'Next hole preview',
                                        onPressed:
                                            holes.any(
                                              (h) =>
                                                  h.number == hole.number + 1,
                                            )
                                            ? () => _show(hole.number + 1)
                                            : null,
                                        icon: const Icon(Icons.chevron_right),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => context.push(
                                          '/rounds/${r.id}/scorecard',
                                        ),
                                        icon: const Icon(
                                          Icons.table_chart_outlined,
                                        ),
                                        label: const Text('Scorecard'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => context.push(
                                          '/rounds/${r.id}/leaderboard',
                                        ),
                                        icon: const Icon(
                                          Icons.leaderboard_outlined,
                                        ),
                                        label: const Text('Leaderboard'),
                                      ),
                                    ],
                                  ),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        context.go('/rounds/${r.id}/live'),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: Text(
                                      'Enter scores · Hole ${r.currentHole}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
        },
      ),
    );
  }

  void _show(int hole) {
    setState(() => _preview = hole);
    _transform.value = Matrix4.identity();
  }

  Widget _missing(GolfHole hole) => Container(
    color: AppTheme.pageBg,
    alignment: Alignment.center,
    padding: const EdgeInsets.fromLTRB(32, 105, 32, 170),
    child: SingleChildScrollView(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.map_outlined,
          size: 65,
          color: AppTheme.primaryGreenLight,
        ),
        const SizedBox(height: 18),
        Text(
          'Hole ${hole.number} imagery pending',
          style: AppTheme.display(22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'A verified hole image or licensed course map is needed to show the fairway, hazards and green accurately.',
          textAlign: TextAlign.center,
        ),
        if (hole.estimatedStraightLineMeters != null)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text(
              'Tee to green GPS line: approximately ${hole.estimatedStraightLineMeters} m\nNot a live player distance or official tee yardage.',
              textAlign: TextAlign.center,
              style: AppTheme.body(12, colour: AppTheme.textMuted),
            ),
          ),
      ],
    )),
  );
}
