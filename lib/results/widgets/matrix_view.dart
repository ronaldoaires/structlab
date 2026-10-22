import 'package:flutter/material.dart';
import 'package:structlab/analysis/internal_forces/linear_load_fit.dart';
import 'package:structlab/core/format_number.dart';
import 'package:structlab/core/theme/colors.dart';

/// A 3x3 matrix with side brackets. The unknowns x and y are highlighted.
class MatrixView extends StatelessWidget {
  const MatrixView({super.key, required this.rows});

  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    const bracket = BorderSide(color: ink, width: 1.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(left: bracket, right: bracket),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final cell in row)
                  SizedBox(
                    width: 46,
                    height: 26,
                    child: Center(
                      child: Text(
                        cell,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: (cell == 'x' || cell == 'y')
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: (cell == 'x' || cell == 'y') ? brandBlue : ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// "[xa ya 1; xb yb 1; x y 1] = [numbers]" of one load. Scales down when it
/// does not fit the width.
class LoadMatrixView extends StatelessWidget {
  const LoadMatrixView({super.key, required this.fit});

  final LinearLoadFit fit;

  @override
  Widget build(BuildContext context) {
    String n(double v) => formatNumber(v);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MatrixView(
            rows: [
              ['xa', 'ya', '1'],
              ['xb', 'yb', '1'],
              ['x', 'y', '1'],
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('=', style: TextStyle(fontSize: 20, color: ink)),
          ),
          MatrixView(
            rows: [
              [n(fit.xa), n(fit.ya), '1'],
              [n(fit.xb), n(fit.yb), '1'],
              ['x', 'y', '1'],
            ],
          ),
        ],
      ),
    );
  }
}