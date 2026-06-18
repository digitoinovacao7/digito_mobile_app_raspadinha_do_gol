import 'package:flutter/material.dart';
import '../core/theme.dart';

class LegalTextScreen extends StatelessWidget {
  final String title;
  final String markdownContent;

  const LegalTextScreen({
    Key? key,
    required this.title,
    required this.markdownContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          markdownContent,
          style: const TextStyle(fontSize: 16, height: 1.5, color: AppTheme.textDark),
        ),
      ),
    );
  }
}
