/// What the current user is allowed to do. Today everybody gets the free
/// plan. When subscriptions exist, only this file needs to change.
class Entitlements {
  const Entitlements({this.maxProjects = 5, this.canSeeSteps = true});

  final int maxProjects;

  /// Step by step of the solution (subscribers only). Kept ON while there
  /// are no subscriptions yet, so the screen can be tested.
  final bool canSeeSteps;

  /// [currentCount] is how many projects are already saved.
  bool canCreateProject(int currentCount) => currentCount < maxProjects;
}