import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';

/// A business-form step used by the shared guided form shell.
class GuidedFormStep {
  final String title;
  final IconData icon;

  const GuidedFormStep({
    required this.title,
    required this.icon,
  });
}

/// Shared responsive shell for multi-step Parcoto forms.
///
/// The shell owns presentation and navigation controls only. Domain validation,
/// draft persistence and submission remain in the feature form.
class GuidedFormShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<GuidedFormStep> steps;
  final int currentStep;
  final Widget child;
  final Widget? sidePanel;
  final ScrollController? scrollController;
  final bool readOnly;
  final bool saving;
  final bool canGoBack;
  final bool canContinue;
  final String continueLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onPrevious;
  final VoidCallback? onContinue;
  final ValueChanged<int>? onSelectStep;

  const GuidedFormShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.currentStep,
    required this.child,
    this.sidePanel,
    this.scrollController,
    this.readOnly = false,
    this.saving = false,
    this.canGoBack = false,
    this.canContinue = true,
    this.continueLabel = 'Continuer',
    this.onCancel,
    this.onSaveDraft,
    this.onPrevious,
    this.onContinue,
    this.onSelectStep,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final safeStep = currentStep.clamp(0, steps.length - 1).toInt();
    final progress = (safeStep + 1) / steps.length;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Container(
        color: appTheme.backGroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final showSidePanel =
                sidePanel != null && constraints.maxWidth >= 1120;
            return Column(
              children: [
                _buildHeader(
                  context,
                  appTheme,
                  safeStep,
                  progress,
                  compact,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      compact ? 12 : 24,
                      compact ? 12 : 18,
                      compact ? 12 : 24,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1500),
                        child: showSidePanel
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildMainCard(
                                      context,
                                      appTheme,
                                      child,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  SizedBox(
                                    width: 340,
                                    child: sidePanel,
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildMainCard(
                                    context,
                                    appTheme,
                                    child,
                                  ),
                                  if (sidePanel != null) ...[
                                    const SizedBox(height: 14),
                                    sidePanel!,
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomBar: readOnly
          ? null
          : _buildFooter(context, appTheme),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppTheme appTheme,
    int safeStep,
    double progress,
    bool compact,
  ) {
    final accent = appTheme.color;
    final completedCount = safeStep;
    final current = steps[safeStep];
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 24,
        compact ? 14 : 20,
        compact ? 14 : 24,
        compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        border: Border(bottom: BorderSide(color: appTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 42 : 50,
                height: compact ? 42 : 50,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  FluentIcons.car,
                  color: accent,
                  size: compact ? 21 : 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: appTheme.textColor,
                        fontSize: compact ? 19 : 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: appTheme.mutedTextColor,
                        fontSize: compact ? 11 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 18),
                SizedBox(
                  width: 190,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Étape ${safeStep + 1} sur ${steps.length}',
                        style: TextStyle(
                          color: appTheme.mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GuidedFormProgressTrack(progress: progress, color: accent),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (compact) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Étape ${safeStep + 1} sur ${steps.length} · ${current.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: appTheme.mutedTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 92,
                  child: GuidedFormProgressTrack(progress: progress, color: accent),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: compact ? 52 : 58,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < steps.length; index++) ...[
                    _StepIndicator(
                      step: steps[index],
                      index: index,
                      isCurrent: index == safeStep,
                      isComplete: index < completedCount,
                      accent: accent,
                      compact: compact,
                      onTap: onSelectStep == null || index >= safeStep
                          ? null
                          : () => onSelectStep!(index),
                    ),
                    if (index != steps.length - 1)
                      Container(
                        width: compact ? 22 : 34,
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        color: appTheme.borderColor,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(
    BuildContext context,
    AppTheme appTheme,
    Widget content,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 640 ? 14 : 20,
      ),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        border: Border.all(color: appTheme.borderColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: appTheme.mode == ThemeMode.dark ? .12 : .035,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildFooter(BuildContext context, AppTheme appTheme) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        border: Border(top: BorderSide(color: appTheme.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onSaveDraft != null)
                    Button(
                      onPressed: saving ? null : onSaveDraft,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.save, size: 14),
                          SizedBox(width: 8),
                          Text('Enregistrer en brouillon'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (canGoBack)
                        Expanded(
                          child: Button(
                            onPressed: saving ? null : onPrevious,
                            child: const Text('Précédent'),
                          ),
                        ),
                      if (canGoBack) const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: saving || !canContinue ? null : onContinue,
                          child: saving
                              ? const ProgressRing(strokeWidth: 2)
                              : Text(continueLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  if (onCancel != null)
                    Button(
                      onPressed: saving ? null : onCancel,
                      child: const Text('Annuler'),
                    ),
                  if (onSaveDraft != null) ...[
                    if (onCancel != null) const SizedBox(width: 8),
                    Button(
                      onPressed: saving ? null : onSaveDraft,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.save, size: 14),
                          SizedBox(width: 8),
                          Text('Enregistrer en brouillon'),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (canGoBack) ...[
                    Button(
                      onPressed: saving ? null : onPrevious,
                      child: const Text('Précédent'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: saving || !canContinue ? null : onContinue,
                    child: saving
                        ? const ProgressRing(strokeWidth: 2)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(continueLabel),
                              const SizedBox(width: 8),
                              Icon(
                                continueLabel == 'Enregistrer le véhicule'
                                    ? FluentIcons.save
                                    : FluentIcons.chevron_right,
                                size: 14,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class GuidedFormProgressTrack extends StatelessWidget {
  final double progress;
  final Color color;

  const GuidedFormProgressTrack({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: appTheme.fillColor),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                child: ColoredBox(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final GuidedFormStep step;
  final int index;
  final bool isCurrent;
  final bool isComplete;
  final bool compact;
  final Color accent;
  final VoidCallback? onTap;

  const _StepIndicator({
    required this.step,
    required this.index,
    required this.isCurrent,
    required this.isComplete,
    required this.accent,
    required this.compact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final foreground = isCurrent || isComplete
        ? accent
        : appTheme.mutedTextColor;
    final surface = isCurrent
        ? accent.withValues(alpha: .10)
        : Colors.transparent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 31 : 36,
              height: compact ? 31 : 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent || isComplete
                    ? accent
                    : appTheme.fillColor,
                border: Border.all(
                  color: isCurrent || isComplete
                      ? accent
                      : appTheme.borderColor,
                ),
              ),
              alignment: Alignment.center,
              child: isComplete
                  ? const Icon(
                      FluentIcons.check_mark,
                      size: 14,
                      color: Colors.white,
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white
                            : appTheme.mutedTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Text(
              step.title,
              style: TextStyle(
                color: foreground,
                fontSize: compact ? 10 : 12,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
