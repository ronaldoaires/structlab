/// What the current user is allowed to do. Today everybody gets the free
/// plan. When subscriptions exist, only this file needs to change.
class Entitlements {
  const Entitlements({this.maxProjects = 5});

  final int maxProjects;

  /// [currentCount] is how many projects are already saved.
  bool canCreateProject(int currentCount) => currentCount < maxProjects;
}