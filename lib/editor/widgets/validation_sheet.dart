import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/validation/validation_report.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Bottom sheet with the result of the validation.
Future<void> showValidationSheet(BuildContext context, ValidationReport r) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.78,
    ),
    builder: (context) => SafeArea(child: _SheetContent(report: r)),
  );
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({required this.report});

  final ValidationReport report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final ok = r.canSolve;
    final accent = ok ? success : danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  ok ? Icons.check_circle_outline : Icons.error_outline,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ok ? validationOkTitle : validationFailTitle,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      validationCounts(r.errorCount, r.warningCount),
                      style: const TextStyle(fontSize: 13, color: inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.staticity != Staticity.unknown) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: brandTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staticityTitle(r),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: brandBlue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    staticityBody(r),
                    style: const TextStyle(
                        fontSize: 13, height: 1.35, color: ink),
                  ),
                ],
              ),
            ),
          ],
          if (r.issues.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              validationIssuesHeader,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: inkMuted),
            ),
            const SizedBox(height: 8),
            for (final issue in r.issues) _IssueTile(issue: issue),
          ],
          if (ok) ...[
            const SizedBox(height: 14),
            const Text(
              validationNextStep,
              style: TextStyle(fontSize: 13, color: inkMuted),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(closeLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final ValidationIssue issue;

  @override
  Widget build(BuildContext context) {
    final isError = issue.severity == IssueSeverity.error;
    final color = isError ? danger : warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.cancel_outlined : Icons.warning_amber_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issueTitle(issue),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                ),
                const SizedBox(height: 3),
                Text(
                  issueTip(issue),
                  style: const TextStyle(
                      fontSize: 13, height: 1.35, color: inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}