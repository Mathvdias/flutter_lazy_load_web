import 'package:flutter/material.dart';

// This file is imported with `deferred as` in router.dart.
// Everything in this file (and its transitive imports) is compiled into a
// separate JS chunk — it is NOT part of the initial download.

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 20,
        itemBuilder: (context, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text('Metric ${i + 1}'),
            subtitle: Text('Value: ${(i + 1) * 42}'),
          ),
        ),
      ),
    );
  }
}
