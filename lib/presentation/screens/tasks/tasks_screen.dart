import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevler'),
      ),
      body: const Center(
        child: Text('Görevler sayfası - Geliştiriliyor'),
      ),
    );
  }
}