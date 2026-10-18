import 'member.dart';
import 'load.dart';
import 'node.dart';
import 'support.dart';

/// The whole structure: nodes, members, supports and loads.
/// Pure data, no UI. Can be copied (undo) and saved/loaded as JSON.
class StructuralModel {
  StructuralModel({
    List<StructuralNode>? nodes,
    List<StructuralMember>? members,
    List<StructuralSupport>? supports,
    List<StructuralLoad>? loads,
    this.nextId = 1,
  })  : nodes = nodes ?? [],
        members = members ?? [],
        supports = supports ?? [],
        loads = loads ?? [];

  /// Bump when the JSON format changes, so old files can be migrated.
  static const int jsonVersion = 1;

  final List<StructuralNode> nodes;
  final List<StructuralMember> members;
  final List<StructuralSupport> supports;
  final List<StructuralLoad> loads;
  int nextId;

  bool get isEmpty =>
      nodes.isEmpty && members.isEmpty && supports.isEmpty && loads.isEmpty;

  /// Returns a new unique id for any element.
  int newId() => nextId++;

  StructuralNode? nodeById(int id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  void clear() {
    nodes.clear();
    members.clear();
    supports.clear();
    loads.clear();
  }

  /// Deep copy (used by undo).
  StructuralModel copy() => StructuralModel(
        nodes: nodes.map((e) => e.copy()).toList(),
        members: members.map((e) => e.copy()).toList(),
        supports: supports.map((e) => e.copy()).toList(),
        loads: loads.map((e) => e.copy()).toList(),
        nextId: nextId,
      );

  /// Replaces this model's content with a copy of [other].
  void restoreFrom(StructuralModel other) {
    final c = other.copy();
    nodes
      ..clear()
      ..addAll(c.nodes);
    members
      ..clear()
      ..addAll(c.members);
    supports
      ..clear()
      ..addAll(c.supports);
    loads
      ..clear()
      ..addAll(c.loads);
    nextId = c.nextId;
  }

  Map<String, dynamic> toJson() => {
        'version': jsonVersion,
        'nextId': nextId,
        'nodes': nodes.map((e) => e.toJson()).toList(),
        'members': members.map((e) => e.toJson()).toList(),
        'supports': supports.map((e) => e.toJson()).toList(),
        'loads': loads.map((e) => e.toJson()).toList(),
      };

  factory StructuralModel.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (json[key] as List)
            .map((e) => parse(e as Map<String, dynamic>))
            .toList();

    return StructuralModel(
      nodes: readList('nodes', StructuralNode.fromJson),
      members: readList('members', StructuralMember.fromJson),
      supports: readList('supports', StructuralSupport.fromJson),
      loads: readList('loads', StructuralLoad.fromJson),
      nextId: json['nextId'] as int,
    );
  }
}