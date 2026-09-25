import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user});

  final User user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService();
  late final Future<AppUser> _profile = _auth.loadProfile(widget.user.uid);

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: FutureBuilder<AppUser>(
        future: _profile,
        builder: (context, snap) {
          final name = snap.data?.name ?? widget.user.displayName ?? '';
          final email = snap.data?.email ?? widget.user.email ?? '';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 40,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: text.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              Text(name, textAlign: TextAlign.center, style: text.titleLarge),
              Text(email, textAlign: TextAlign.center, style: text.bodyMedium),
              const SizedBox(height: 32),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('User ID'),
                  subtitle: SelectableText(widget.user.uid),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
