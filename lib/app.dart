import 'package:flutter/material.dart';
import 'package:structlab/core/theme/app_theme.dart';
import 'package:structlab/editor/editor_screen.dart';
import 'package:structlab/l10n/strings_pt.dart';

class StructLabApp extends StatelessWidget {
  const StructLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const EditorScreen(),
    );
  }
}