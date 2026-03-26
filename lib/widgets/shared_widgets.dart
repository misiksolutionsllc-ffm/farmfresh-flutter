import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

// ============ Formatters ============
String formatCurrency(double? amount) {
  if (amount == null) return '\$0.00';
  return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
}

String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final d = DateTime.parse(dateStr);
    return DateFormat('MMM d, h:mm a').format(d);
  } catch (_) {
    return 'N/A';
  }
}

String formatRelativeTime(String dateStr) {
  try {
    final d = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dateStr);
  } catch (_) {
    return formatDate(dateStr);
  }
}

// ============ Status Badge ============
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ============ Animated Stat Card ============
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool trendUp;
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color, this.trend, this.trendUp = true});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (_, val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface800.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (trendUp ? AppColors.emerald : AppColors.error).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${trendUp ? '↑' : '↓'} $trend',
                      style: TextStyle(color: trendUp ? AppColors.emerald : AppColors.error, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ============ Glass Card ============
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  const GlassCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}

// ============ Empty State ============
class EmptyState extends StatelessWidget {
  final String emoji;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.emoji, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, val, child) => Transform.scale(scale: val, child: child),
              child: Text(emoji, style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

// ============ Animated Progress Bar ============
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final double max;
  final Color color;
  final double height;
  final String? label;
  final bool showPercent;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.max = 100,
    this.color = AppColors.emerald,
    this.height = 6,
    this.label,
    this.showPercent = false,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercent)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null) Text(label!, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                if (showPercent) Text('${(percent * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            color: Colors.white.withOpacity(0.05),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => FractionallySizedBox(
                widthFactor: val,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============ Mini Bar Chart ============
class MiniBarChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final List<String>? labels;

  const MiniBarChart({
    super.key,
    required this.data,
    this.color = AppColors.emerald,
    this.height = 100,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 1.0 : data.reduce(max).clamp(1.0, double.infinity);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (i) {
          final barHeight = (data[i] / maxVal) * (height - 20);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: barHeight),
                    duration: Duration(milliseconds: 400 + i * 80),
                    curve: Curves.easeOutBack,
                    builder: (_, val, __) => Container(
                      height: val,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.7),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (labels != null && i < labels!.length)
                    Text(labels![i], style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============ Donut Chart ============
class DonutChartWidget extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const DonutChartWidget({
    super.key,
    required this.segments,
    this.size = 120,
    this.strokeWidth = 14,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => CustomPaint(
              size: Size(size, size),
              painter: _DonutPainter(segments, strokeWidth, val),
            ),
          ),
          if (center != null) Center(child: center!),
        ],
      ),
    );
  }
}

class DonutSegment {
  final double value;
  final Color color;
  final String? label;
  const DonutSegment({required this.value, required this.color, this.label});
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final double progress;
  _DonutPainter(this.segments, this.strokeWidth, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final total = segments.fold(0.0, (s, seg) => s + seg.value);
    if (total == 0) return;

    // Background
    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withOpacity(0.05));

    double startAngle = -pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = seg.color,
      );
      startAngle += (seg.value / total) * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress;
}

// ============ Animated List Item ============
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  const AnimatedListItem({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child),
      ),
      child: child,
    );
  }
}
