import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/dialogs/project_dialogs.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/l10n/strings_pt.dart';
import 'package:structlab/services/project_repository.dart';

/// Lists the saved projects: open, rename, delete and create new.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, required this.controller});

  final EditorController controller;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectInfo>? _items;

  EditorController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _c.flush(); // makes sure the current project is up to date
    final items = await _c.repo.list();
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _open(ProjectInfo p) async {
    final ok = await _c.openProject(p.id);
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _new() async {
    final ok = await _c.newModel();
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _rename(ProjectInfo p) async {
    final name = await askProjectName(context, p.name);
    if (name == null) return;
    await _c.renameProject(p.id, name);
    await _load();
  }

  Future<void> _delete(ProjectInfo p) async {
    final ok = await confirmDeleteProject(context, p.name);
    if (!ok) return;
    await _c.deleteProject(p.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: const Text(projectsTitle),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _new,
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(newProjectLabel),
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      projectsCount(items.length, _c.entitlements.maxProjects),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: inkMuted,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              projectsEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: inkMuted),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: lineColor),
                          itemBuilder: (context, i) => _tile(items[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _tile(ProjectInfo p) {
    final isCurrent = p.id == _c.projectId;
    return ListTile(
      selected: isCurrent,
      selectedTileColor: brandTint,
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isCurrent ? Colors.white : brandTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.architecture, color: brandBlue),
      ),
      title: Text(
        p.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: ink),
      ),
      subtitle: Text(
        isCurrent
            ? '$projectOpenLabel · ${projectEditedAt(p.updatedAt)}'
            : projectEditedAt(p.updatedAt),
        style: const TextStyle(fontSize: 13, color: inkMuted),
      ),
      onTap: () => _open(p),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'rename') _rename(p);
          if (v == 'delete') _delete(p);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'rename', child: Text(renameLabel)),
          PopupMenuItem(value: 'delete', child: Text(deleteLabel)),
        ],
      ),
    );
  }
}