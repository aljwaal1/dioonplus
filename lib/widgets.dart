import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'sound_service.dart';

/// A premium gold gradient button used for primary calls to action
/// (save, confirm). Includes a soft shadow and a pressed-state shade.
class GoldButton extends StatefulWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : (_pressed ? AppGradients.goldPressed : AppGradients.gold),
        color: disabled ? AppColors.textFaint.withValues(alpha: 0.3) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: disabled || _pressed ? [] : AppShadows.gold,
      ),
      transform: _pressed ? (Matrix4.identity()..scale(0.98)) : Matrix4.identity(),
      transformAlignment: Alignment.center,
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: AppColors.navyDark, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.navyDark,
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTap: disabled
          ? null
          : () {
              SoundService.instance.tap();
              widget.onPressed!();
            },
      child: child,
    );
  }
}

/// A dark, navy/teal gradient panel used for hero balance summaries.
class GradientPanel extends StatelessWidget {
  const GradientPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.header,
      ),
      child: child,
    );
  }
}

/// Circular avatar with a gradient fill, used for person initials.
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({super.key, required this.letter, this.size = 46});

  final String letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.header,
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: AppColors.goldLight,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

/// Small colored status badge, e.g. "مسدد" / "لي عنده" / "علي له".
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11.5),
      ),
    );
  }
}

/// Premium elevated card wrapper with soft shadow + rounded corners,
/// replacing the flat bordered Card used previously.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.margin,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            if (accentColor != null) Container(width: 4, color: accentColor),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap == null
                      ? null
                      : () {
                          SoundService.instance.tap();
                          onTap!();
                        },
                  child: Padding(padding: padding, child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return card;
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inventory_2_outlined,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.teal),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Simple fade + rise entrance animation for list items, giving the
/// list a polished staggered appearance without extra dependencies.
class FadeInUp extends StatelessWidget {
  const FadeInUp({super.key, required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Pill-shaped search field with a soft fill and rounded edges.
class PillSearchField extends StatelessWidget {
  const PillSearchField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
          ),
        ),
      ),
    );
  }
}
