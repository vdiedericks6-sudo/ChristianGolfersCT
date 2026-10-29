import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared building blocks for Christian Golfers Cape Town interface.

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------

/// Standard raised charcoal card with a subtle border and generous radius.
class ChristianGolfersCard extends StatelessWidget {
  const ChristianGolfersCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.colour,
    this.border,
    this.radius = AppTheme.radiusCard,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? colour;
  final Color? border;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: AppTheme.cardDecoration(
        colour: colour,
        border: border,
        radius: radius,
      ),
      child: onTap == null
          ? body
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: body,
              ),
            ),
    );
  }
}

/// A section heading: small uppercase label with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.action, this.padding, super.key});

  final String title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTheme.label(11, colour: AppTheme.textMuted),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

/// Primary call to action: full width lime button with a dark label.
class GoldButton extends StatelessWidget {
  const GoldButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.height = 50,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: enabled ? AppTheme.primaryGreen : AppTheme.cardSecondary,
            borderRadius: BorderRadius.circular(25),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: Color(0x3300B074),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: enabled ? onPressed : null,
              child: Center(
                child: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: const Color(0xFF19201D),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              size: 19,
                              color: enabled
                                  ? const Color(0xFF19201D)
                                  : AppTheme.textFaint,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: AppTheme.body(
                              14,
                              weight: FontWeight.w700,
                              colour: enabled
                                  ? const Color(0xFF19201D)
                                  : AppTheme.textFaint,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick Action Tile matching Screen 2 (Home): white card with light green icon circle.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? caption;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTheme.card;
    final ic = iconColor ?? AppTheme.primaryGreen;
    final tc = textColor ?? AppTheme.textPrimary;

    return ChristianGolfersCard(
      colour: bg,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ic, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body(13.5, weight: FontWeight.w700, colour: tc),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(10.5, colour: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular icon button.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: backgroundColor ?? AppTheme.cardSecondary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            icon,
            size: size * 0.5,
            color: iconColor ?? AppTheme.textPrimary,
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

// ---------------------------------------------------------------------------
// Data display
// ---------------------------------------------------------------------------

/// A single figure tile.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.caption,
    this.highlight = false,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTheme.numeric(
              22,
              colour: highlight ? AppTheme.primaryGreen : AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.body(
            11,
            colour: AppTheme.textMuted,
            weight: FontWeight.w600,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: AppTheme.body(10, colour: AppTheme.textFaint),
          ),
        ],
      ],
    );
  }
}

/// Small rounded label/pill badge.
class MetaPill extends StatelessWidget {
  const MetaPill(
    this.text, {
    this.icon,
    this.colour,
    this.background,
    super.key,
  });

  final String text;
  final IconData? icon;
  final Color? colour;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final foreground = colour ?? AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? AppTheme.primaryGreenBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTheme.body(
              11,
              colour: foreground,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular initials/photo avatar with green border ring when highlighted.
class GolferAvatar extends StatelessWidget {
  const GolferAvatar({
    required this.name,
    this.photoUrl,
    this.size = 40,
    this.highlight = true,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final bool highlight;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryGreenBg,
        border: Border.all(
          color: highlight ? AppTheme.primaryGreen : AppTheme.line,
          width: highlight ? 2.0 : 1,
        ),
        image: photoUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              ),
      ),
      alignment: Alignment.center,
      child: photoUrl != null
          ? null
          : Text(
              initialsOf(name),
              style: AppTheme.body(
                size * 0.38,
                weight: FontWeight.w800,
                colour: AppTheme.primaryGreen,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scoring
// ---------------------------------------------------------------------------

enum ScoreMark { eagle, birdie, par, bogey, doublePlus }

ScoreMark markFor(int strokes, int par) {
  final diff = strokes - par;
  if (diff <= -2) return ScoreMark.eagle;
  if (diff == -1) return ScoreMark.birdie;
  if (diff == 0) return ScoreMark.par;
  if (diff == 1) return ScoreMark.bogey;
  return ScoreMark.doublePlus;
}

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    required this.strokes,
    required this.par,
    this.size = 34,
    super.key,
  });

  final int strokes;
  final int par;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mark = markFor(strokes, par);

    final (
      Color border,
      Color text,
      BoxShape shape,
      double width,
    ) = switch (mark) {
      ScoreMark.eagle => (
        AppTheme.primaryGreen,
        AppTheme.primaryGreen,
        BoxShape.circle,
        2.4,
      ),
      ScoreMark.birdie => (
        AppTheme.primaryGreen,
        AppTheme.primaryGreen,
        BoxShape.circle,
        1.5,
      ),
      ScoreMark.par => (
        Colors.transparent,
        AppTheme.textPrimary,
        BoxShape.rectangle,
        0.0,
      ),
      ScoreMark.bogey => (
        AppTheme.textMuted,
        AppTheme.textPrimary,
        BoxShape.rectangle,
        1.5,
      ),
      ScoreMark.doublePlus => (
        AppTheme.doubleBogey,
        AppTheme.doubleBogey,
        BoxShape.rectangle,
        2.4,
      ),
    };

    return Semantics(
      label: '$strokes strokes, par $par',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(6)
              : null,
          border: width == 0 ? null : Border.all(color: border, width: width),
        ),
        child: Text(
          '$strokes',
          style: AppTheme.numeric(size * 0.44, colour: text),
        ),
      ),
    );
  }
}

class ScoreStepper extends StatelessWidget {
  const ScoreStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.quickValues = const [1, 2, 3, 4, 5, 6, 7],
    this.lastQuickIsPlus = true,
    super.key,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final List<int> quickValues;
  final bool lastQuickIsPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label.toUpperCase(), style: AppTheme.label(11)),
            ),
            _StepButton(
              icon: Icons.remove_rounded,
              onTap: value > min ? () => onChanged(value - 1) : null,
              semantic: 'Decrease $label',
            ),
            SizedBox(
              width: 74,
              child: Center(
                child: Text(
                  '$value',
                  style: AppTheme.numeric(38, colour: AppTheme.primaryGreen),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              onTap: value < max ? () => onChanged(value + 1) : null,
              semantic: 'Increase $label',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < quickValues.length; index++) ...[
              if (index > 0) const SizedBox(width: 7),
              Expanded(
                child: _QuickChip(
                  text: lastQuickIsPlus && index == quickValues.length - 1
                      ? '${quickValues[index]}+'
                      : '${quickValues[index]}',
                  selected: value == quickValues[index],
                  onTap: () => onChanged(quickValues[index].clamp(min, max)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.semantic,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      label: semantic,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Material(
          color: enabled ? AppTheme.cardSecondary : AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Icon(
              icon,
              size: 26,
              color: enabled ? AppTheme.primaryGreen : AppTheme.textFaint,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: SizedBox(
        height: 48,
        child: Material(
          color: selected ? AppTheme.primaryGreen : AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? Colors.transparent : AppTheme.line,
                ),
              ),
              child: Text(
                text,
                style: AppTheme.numeric(
                  16,
                  colour: selected
                      ? const Color(0xFF19201D)
                      : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreenBg,
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.display(22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.body(13.5, colour: AppTheme.textMuted),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class LoadFailure extends StatelessWidget {
  const LoadFailure({required this.what, required this.error, super.key});

  final String what;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Could not load $what',
      message: '$error',
    );
  }
}
