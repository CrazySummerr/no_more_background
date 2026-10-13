import 'package:flutter/material.dart';
import 'package:no_more_background/compute/adb.dart';
import 'package:no_more_background/data/adb_app.dart';
import 'package:no_more_background/data/adb_device.dart';
import 'package:no_more_background/data/profile.dart';
import 'package:no_more_background/data/stows.dart';
import 'package:no_more_background/state/use_app_permissions.dart';

/// A minimal dialog for saving the current per-app background settings as a
/// named profile, and applying/deleting previously saved profiles.
class ProfilesDialog extends StatefulWidget {
  const ProfilesDialog({
    super.key,
    required this.deviceSerial,
    required this.permissionMap,
  });

  final AdbDeviceSerial deviceSerial;
  final PermissionMap permissionMap;

  static Future<void> show(
    BuildContext context, {
    required AdbDeviceSerial deviceSerial,
    required PermissionMap permissionMap,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ProfilesDialog(
        deviceSerial: deviceSerial,
        permissionMap: permissionMap,
      ),
    );
  }

  @override
  State<ProfilesDialog> createState() => _ProfilesDialogState();
}

class _ProfilesDialogState extends State<ProfilesDialog> {
  bool _applying = false;

  Future<void> _saveCurrentAsProfile() async {
    final name = await _promptForName();
    if (name == null || name.isEmpty) return;

    final profile = Profile(
      name: name,
      apps: {
        for (final entry in widget.permissionMap.entries)
          entry.key.packageName: entry.value.backgroundActivity,
      },
    );
    stows.profiles.value = [...stows.profiles.value, profile];
    setState(() {});
  }

  Future<String?> _promptForName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyProfile(Profile profile) async {
    setState(() => _applying = true);
    try {
      await Adb.applyProfile(
        widget.deviceSerial,
        profile,
        widget.permissionMap.keys.toList(),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _deleteProfile(Profile profile) {
    stows.profiles.value = stows.profiles.value
        .where((p) => p != profile)
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profiles = stows.profiles.value;
    return AlertDialog(
      title: const Text('Profiles'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            if (profiles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No saved profiles yet.'),
              ),
            for (final profile in profiles)
              ListTile(
                title: Text(profile.name),
                subtitle: Text('${profile.apps.length} app(s)'),
                trailing: Row(
                  mainAxisSize: .min,
                  children: [
                    IconButton(
                      tooltip: 'Apply',
                      icon: const Icon(Icons.play_arrow),
                      onPressed: _applying
                          ? null
                          : () => _applyProfile(profile),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteProfile(profile),
                    ),
                  ],
                ),
              ),
            const Divider(),
            TextButton.icon(
              onPressed: _saveCurrentAsProfile,
              icon: const Icon(Icons.add),
              label: const Text('Save current settings as new profile'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
