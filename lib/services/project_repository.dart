import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Light data shown in the projects list.
class ProjectInfo {
  const ProjectInfo({
    required this.id,
    required this.name,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime updatedAt;
}

/// A project read from disk.
class StoredProject {
  const StoredProject({
    required this.id,
    required this.name,
    required this.modelJson,
  });

  final String id;
  final String name;
  final Map<String, dynamic> modelJson;
}

/// Saves projects as JSON files in the app documents folder:
/// `projects/<id>.json`. Writes go to a temp file first, so a crash in the
/// middle of a save never corrupts the previous version.
class ProjectRepository {
  Directory? _dir;

  Future<Directory> _projectsDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/projects');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _dir = dir;
  }

  File _file(Directory dir, String id) => File('${dir.path}/$id.json');

  String newProjectId() => DateTime.now().microsecondsSinceEpoch.toString();

  static String _idOf(File f) {
    final name = f.uri.pathSegments.last;
    return name.substring(0, name.length - '.json'.length);
  }

  /// Number of saved projects (does not open the files).
  Future<int> count() async {
    final dir = await _projectsDir();
    var n = 0;
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.json')) n++;
    }
    return n;
  }

  /// All projects, most recently edited first.
  Future<List<ProjectInfo>> list() async {
    final dir = await _projectsDir();
    final result = <ProjectInfo>[];
    await for (final e in dir.list()) {
      if (e is! File || !e.path.endsWith('.json')) continue;
      try {
        final data =
            jsonDecode(await e.readAsString()) as Map<String, dynamic>;
        result.add(ProjectInfo(
          id: _idOf(e),
          name: data['name'] as String? ?? 'Projeto',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
              data['updatedAt'] as int? ?? 0),
        ));
      } catch (_) {
        // Unreadable file: skip it.
      }
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Future<StoredProject?> load(String id) async {
    try {
      final dir = await _projectsDir();
      final file = _file(dir, id);
      if (!await file.exists()) return null;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return StoredProject(
        id: id,
        name: data['name'] as String? ?? 'Projeto',
        modelJson: data['model'] as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String id,
    required String name,
    required Map<String, dynamic> modelJson,
  }) async {
    final dir = await _projectsDir();
    final data = {
      'name': name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'model': modelJson,
    };
    final tmp = File('${dir.path}/$id.tmp');
    await tmp.writeAsString(jsonEncode(data), flush: true);
    await tmp.rename(_file(dir, id).path);
  }

  Future<void> rename(String id, String name) async {
    final stored = await load(id);
    if (stored == null) return;
    await save(id: id, name: name, modelJson: stored.modelJson);
  }

  Future<void> delete(String id) async {
    final dir = await _projectsDir();
    final file = _file(dir, id);
    if (await file.exists()) await file.delete();
    if (await lastOpenedId() == id) await setLastOpened(null);
  }

  Future<String?> lastOpenedId() async {
    try {
      final dir = await _projectsDir();
      final f = File('${dir.path}/_last.txt');
      if (!await f.exists()) return null;
      final id = (await f.readAsString()).trim();
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  Future<void> setLastOpened(String? id) async {
    final dir = await _projectsDir();
    await File('${dir.path}/_last.txt').writeAsString(id ?? '');
  }
}