// @ lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notif = true;
  bool email = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final user = auth.currentUser!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.face_retouching_natural,
                      size: 45,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.email ?? 'No email',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user.metadata.creationTime != null)
                    Text(
                      'Story started: ${DateFormat.yMMMMd().format(user.metadata.creationTime!)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Notifications'),
            _buildSettingsCard(
              children: [
                SwitchListTile(
                  value: notif,
                  onChanged: (v) => setState(() => notif = v),
                  title: const Text('In-App Alerts'),
                  subtitle: const Text('For new swap requests and messages'),
                  activeColor: theme.colorScheme.primary,
                ),
                _buildDivider(),
                SwitchListTile(
                  value: email,
                  onChanged: (v) => setState(() => email = v),
                  title: const Text('Email Summaries'),
                  subtitle: const Text('Occasional updates on swaps'),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('About'),
            _buildSettingsCard(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('App Version'),
                  trailing: const Text(
                    '1.0.0',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: TextButton.icon(
                onPressed: () => auth.signOut(),
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, color: Colors.grey[200], indent: 16, endIndent: 16);
}
