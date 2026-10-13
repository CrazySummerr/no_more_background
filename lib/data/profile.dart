import 'package:no_more_background/data/adb_permissions.dart';

/// A named, saved set of per-app [BackgroundActivity] settings that can be
/// applied in one action, instead of toggling each app individually.
class Profile {
  Profile({required this.name, required this.apps});

  String name;

  /// Package name -> desired background activity.
  Map<String, BackgroundActivity> apps;

  factory Profile.fromJson(Map<String, dynamic> json) {
    final appsJson = json['apps'] as Map<String, dynamic>;
    return Profile(
      name: json['name'] as String,
      apps: appsJson.map(
        (packageName, index) =>
            MapEntry(packageName, BackgroundActivity.values[index as int]),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'apps': apps.map(
      (packageName, activity) => MapEntry(packageName, activity.index),
    ),
  };
}
