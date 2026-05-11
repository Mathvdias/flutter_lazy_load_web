import 'package:flutter/material.dart';

// Deferred chunk — only downloaded when the user opens Profile.

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
            const SizedBox(height: 16),
            Text('Matheus Dias',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('mathvdias@github.com'),
          ],
        ),
      ),
    );
  }
}
