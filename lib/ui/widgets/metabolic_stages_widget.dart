import 'package:flutter/material.dart';
import '../../providers/fasting_provider.dart';
import '../../core/theme/app_theme.dart';

enum _StageStatus { past, current, upcoming }

class MetabolicStagesWidget extends StatelessWidget {
  final FastingState fastingState;

  const MetabolicStagesWidget({
    super.key,
    required this.fastingState,
  });

  void _showAllStagesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MetabolicStagesModal(fastingState: fastingState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final current = fastingState.currentMetabolicStage;

    if (!fastingState.isFasting) {
      return Card(
        child: InkWell(
          onTap: () => _showAllStagesModal(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 18,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Start a fast to see your metabolic stage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: InkWell(
        onTap: () => _showAllStagesModal(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: current.color.withAlpha(isDark ? 36 : 20),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          current.icon,
                          color: current.color,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Current Body State',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '· ${current.subtitle}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: current.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            current.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                current.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // Mini milestone progress bar
              Row(
                children: MetabolicStage.stages.map((stage) {
                  final elapsedHours =
                      fastingState.elapsedTime.inMinutes / 60.0;
                  final isReached =
                      fastingState.isFasting && elapsedHours >= stage.startHour;
                  final isCurrent =
                      fastingState.isFasting && current.title == stage.title;

                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? stage.color
                            : isReached
                                ? stage.color.withAlpha(120)
                                : AppTheme.border(isDark),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: stage.color.withAlpha(100),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetabolicStagesModal extends StatelessWidget {
  final FastingState fastingState;

  const _MetabolicStagesModal({required this.fastingState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elapsedHours = fastingState.elapsedTime.inMinutes / 60.0;
    final current = fastingState.currentMetabolicStage;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: current.color.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(current.icon, color: current.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Fasting Timeline',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fastingState.isFasting
                                ? '${_formatDuration(fastingState.elapsedTime)} elapsed · ${current.title}'
                                : 'Start a fast to track your progress through each stage',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: fastingState.isFasting
                                  ? current.color
                                  : AppTheme.textSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  itemCount: MetabolicStage.stages.length,
                  itemBuilder: (context, index) {
                    final stage = MetabolicStage.stages[index];
                    final isLast = index == MetabolicStage.stages.length - 1;

                    final status = !fastingState.isFasting
                        ? _StageStatus.upcoming
                        : elapsedHours >= stage.endHour
                            ? _StageStatus.past
                            : elapsedHours >= stage.startHour
                                ? _StageStatus.current
                                : _StageStatus.upcoming;

                    return _TimelineRow(
                      stage: stage,
                      status: status,
                      isDark: isDark,
                      isLast: isLast,
                      elapsedHours: elapsedHours,
                      nextStageTitle: isLast
                          ? null
                          : MetabolicStage.stages[index + 1].title,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final MetabolicStage stage;
  final _StageStatus status;
  final bool isDark;
  final bool isLast;
  final double elapsedHours;
  final String? nextStageTitle;

  const _TimelineRow({
    required this.stage,
    required this.status,
    required this.isDark,
    required this.isLast,
    required this.elapsedHours,
    required this.nextStageTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = status == _StageStatus.current;
    final isPast = status == _StageStatus.past;
    final nodeColor = isPast || isCurrent
        ? stage.color
        : AppTheme.border(isDark);
    final lineColor = isPast
        ? stage.color
        : AppTheme.border(isDark);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 30 : 24,
                  height: isCurrent ? 30 : 24,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: stage.color.withAlpha(110),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isPast ? Icons.check_rounded : stage.icon,
                    color: (isPast || isCurrent)
                        ? Colors.white
                        : AppTheme.textSecondary(isDark),
                    size: isCurrent ? 16 : 13,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: _StageCard(
                stage: stage,
                status: status,
                isDark: isDark,
                elapsedHours: elapsedHours,
                nextStageTitle: nextStageTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final MetabolicStage stage;
  final _StageStatus status;
  final bool isDark;
  final double elapsedHours;
  final String? nextStageTitle;

  const _StageCard({
    required this.stage,
    required this.status,
    required this.isDark,
    required this.elapsedHours,
    required this.nextStageTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = status == _StageStatus.current;
    final isPast = status == _StageStatus.past;
    final titleColor = isPast
        ? AppTheme.textSecondary(isDark)
        : AppTheme.textPrimary(isDark);

    return Opacity(
      opacity: isPast ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrent
              ? stage.color.withAlpha(isDark ? 28 : 16)
              : AppTheme.subtleSurface(isDark),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: isCurrent
              ? Border.all(color: stage.color.withAlpha(90), width: 1.4)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stage.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stage.color,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: const Text(
                      'NOW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  )
                else
                  Text(
                    stage.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(isDark),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              stage.description,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.textSecondary(isDark),
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(height: 12),
              _buildProgress(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    if (stage.endHour >= 900) {
      return Text(
        'Your body stays in this stage until you break the fast.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: stage.color,
        ),
      );
    }

    final fraction = ((elapsedHours - stage.startHour) /
            (stage.endHour - stage.startHour))
        .clamp(0.0, 1.0);
    final remainingHours = (stage.endHour - elapsedHours).clamp(0.0, 999.0);
    final remaining = Duration(seconds: (remainingHours * 3600).round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            backgroundColor: stage.color.withAlpha(40),
            valueColor: AlwaysStoppedAnimation(stage.color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_formatDuration(remaining)} until ${nextStageTitle ?? 'next stage'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: stage.color,
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours <= 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}
