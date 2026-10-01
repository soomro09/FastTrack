import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math' as math;

class UserProfile {
  final String name;
  final String memberSince;
  final String? photoPath;

  const UserProfile({
    required this.name,
    required this.memberSince,
    this.photoPath,
  });

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'AR';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? memberSince,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      memberSince: memberSince ?? this.memberSince,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  static const _nameKey = 'user_profile_name';
  static const _sinceKey = 'user_member_since';
  static const _photoKey = 'user_profile_photo_path';

  @override
  UserProfile build() {
    _loadProfile();
    return const UserProfile(name: 'John Doe.', memberSince: 'Jun 2026');
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey) ?? 'John Doe.';
    final since = prefs.getString(_sinceKey) ?? 'Jun 2026';
    final photoPath = prefs.getString(_photoKey);
    state = UserProfile(name: name, memberSince: since, photoPath: photoPath);
  }

  Future<void> updateName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(name: trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, trimmed);
  }

  Future<void> updateMemberSince(String since) async {
    state = state.copyWith(memberSince: since);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sinceKey, since);
  }

  Future<void> updatePhoto(String path) async {
    state = state.copyWith(photoPath: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoKey, path);
  }

  Future<void> removePhoto() async {
    state = state.copyWith(clearPhoto: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoKey);
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(
  () {
    return UserProfileNotifier();
  },
);
