# StructLab

A mobile-first 2D structural modeling app for engineering students,
educators and enthusiasts. Draw a structure, apply loads, and (soon) get
reactions and internal-force diagrams with a step-by-step solution.

## Highlights
- Interactive canvas built with Flutter `CustomPainter` and raw pointer events
- Drag or tap-tap beam drawing with grid snap and orthogonal lock
- Supports (roller, pin, fixed) in any orientation
- Concentrated, uniform, triangular and trapezoidal loads at any direction
- Undo history, node placement along members, precise numeric editing
- Dimension lines and load labels that follow member inclination

## Architecture
Layered and UI-independent where it matters:
- `domain/`: pure Dart models, rules and catalogs (JSON-serializable)
- `editor/`: controller (`ChangeNotifier`), tools as pluggable classes,
  painters and widgets
- `l10n/`: all user-facing strings, ready for translation
- Planned: `analysis/` (swappable solvers: beam, frame, truss),
  `results/`, `services/` (storage, auth, subscription)

## Status
Prototype. The analysis engine is the next milestone.
