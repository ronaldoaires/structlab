# StructLab

A mobile-first 2D structural modeling app for engineering students,
educators and enthusiasts. Draw a structure, apply loads, validate the model
and (soon) get reactions and internal-force diagrams with a step-by-step
solution.

The interface is currently in Portuguese (pt-BR).

## Highlights
- Interactive canvas built with Flutter `CustomPainter` and raw pointer events
- Drag or tap-tap beam drawing with grid snap and orthogonal lock
- Supports (roller, pin, fixed) in any orientation
- Concentrated loads, applied moments, and uniform, triangular and
  trapezoidal distributed loads at any direction
- Model validation: detects loose nodes, disconnected parts, crossing members
  and unstable supports, classifies the structure as hypostatic, isostatic or
  hyperstatic, and highlights problems on the canvas
- Undo history, node placement along members, drag to move nodes, precise
  numeric editing
- Pinch to zoom, two-finger pan and a one-tap "fit structure" view
- Dimension lines and load labels that follow member inclination
- Local projects with autosave (open, rename, delete)

## Architecture
Layered and UI-independent where it matters:
- `domain/`: pure Dart models, rules, catalogs and validation
  (JSON-serializable, no UI)
- `editor/`: controller (`ChangeNotifier`), tools as pluggable classes,
  painters, dialogs and widgets
- `services/`: local project storage and entitlements (free plan limits)
- `l10n/`: all user-facing strings, ready for translation
- Planned: `analysis/` (swappable solvers: beam, frame, truss), `results/`,
  and remote services (auth, subscription)

## Status
Prototype. Modeling, validation and local storage are working. Next
milestone: the analysis engine, starting with statically determinate beams
(reactions and V, M, N diagrams with a step-by-step solution).
