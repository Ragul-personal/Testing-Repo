import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/daily_task_providers.dart';

/// A lightweight bar chart showing daily completion percentages.
///
/// Uses [CustomPainter] — no third-party chart library required. Matches the
/// existing analytics page, which also uses custom-painted widgets.
class DailyTaskChart extends StatelessWidget {
  final List<DailyTaskDayRecord> data;
  final int maxDays;
  final void Function(DateTime)? onDayTap;

  const DailyTaskChart({
    super.key,
    required this.data,
    this.maxDays = 7,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final direction = Directionality.of(context);
    final visible =
        data.length > maxDays ? data.sublist(data.length - maxDays) : data;

    if (visible.isEmpty) {
      return const SizedBox(height: 120);
    }

    return SizedBox(
      height: 140,
      child: GestureDetector(
        onTapUp: (details) {
          if (onDayTap == null || visible.isEmpty) return;
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final size = renderBox.size;
          final barWidth = math.min(
            32.0,
            (size.width - 8.0 * (visible.length - 1)) / visible.length,
          );
          final totalWidth =
              barWidth * visible.length + 8.0 * (visible.length - 1);
          final startX = (size.width - totalWidth) / 2;

          final dx = details.localPosition.dx;
          for (int i = 0; i < visible.length; i++) {
            final x = startX + i * (barWidth + 8.0);
            if (dx >= x - 4.0 && dx <= x + barWidth + 4.0) {
              onDayTap!(visible[i].date);
              break;
            }
          }
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: _ChartPainter(
            records: visible,
            barColor: cs.primary,
            barBackground: cs.surfaceContainerHighest,
            labelColor: cs.onSurfaceVariant,
            valueColor: cs.onSurface,
            textDirection: direction,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<DailyTaskDayRecord> records;
  final Color barColor;
  final Color barBackground;
  final Color labelColor;
  final Color valueColor;
  final ui.TextDirection textDirection;

  _ChartPainter({
    required this.records,
    required this.barColor,
    required this.barBackground,
    required this.labelColor,
    required this.valueColor,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    const labelHeight = 20.0;
    const valueHeight = 16.0;
    const barRadius = 6.0;
    const barGap = 8.0;
    final chartHeight = size.height - labelHeight - valueHeight - 4;
    final barWidth = math.min(
      32.0,
      (size.width - barGap * (records.length - 1)) / records.length,
    );
    final totalWidth =
        barWidth * records.length + barGap * (records.length - 1);
    final startX = (size.width - totalWidth) / 2;

    final bgPaint = Paint()
      ..color = barBackground
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final dayFmt = DateFormat.E();

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final x = startX + i * (barWidth + barGap);
      final pct = r.percentage / 100;

      // Background bar
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, valueHeight, barWidth, chartHeight),
        const Radius.circular(barRadius),
      );
      canvas.drawRRect(bgRect, bgPaint);

      // Filled bar (from bottom)
      if (pct > 0) {
        final fillH = chartHeight * pct;
        final fillRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            valueHeight + chartHeight - fillH,
            barWidth,
            fillH,
          ),
          const Radius.circular(barRadius),
        );
        canvas.drawRRect(fillRect, fillPaint);
      }

      // Percentage label above bar
      final valueTp = TextPainter(
        text: TextSpan(
          text: '${r.percentage.round()}',
          style: TextStyle(
            color: valueColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: textDirection,
      )..layout();
      valueTp.paint(
        canvas,
        Offset(x + (barWidth - valueTp.width) / 2, 0),
      );

      // Day label below bar
      final label = dayFmt.format(r.date).substring(0, 2);
      final labelTp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: labelColor, fontSize: 11),
        ),
        textDirection: textDirection,
      )..layout();
      labelTp.paint(
        canvas,
        Offset(
          x + (barWidth - labelTp.width) / 2,
          valueHeight + chartHeight + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      records != old.records ||
      barColor != old.barColor ||
      barBackground != old.barBackground;
}
