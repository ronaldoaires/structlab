import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';

/// Bordered card used by the step by step blocks.
class StepCard extends StatelessWidget {
  const StepCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.borderColor = lineColor,
  });

  final Widget child;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

/// One line of text (optionally bold or with tabular numbers).
class StepLine extends StatelessWidget {
  const StepLine(
    this.text, {
    super.key,
    this.bold = false,
    this.mono = false,
    this.color = ink,
    this.size = 14,
  });

  final String text;
  final bool bold;
  final bool mono;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          height: 1.35,
          color: color,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
        ),
      ),
    );
  }
}

/// Small uppercase heading of a section.
class StepSectionTitle extends StatelessWidget {
  const StepSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
    );
  }
}

/// Highlighted result of a step.
class StepResultBox extends StatelessWidget {
  const StepResultBox({super.key, required this.text, this.color = brandBlue});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}