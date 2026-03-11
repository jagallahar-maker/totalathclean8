import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:total_athlete/models/user.dart';

/// Service to handle one-time user profile migrations
class UserMigrationService {
  static const String _migrationKey = 'user_migration_tester_profile_v1';

  /// Updates existing user profile to use Tester identity for testing
  /// This is a one-time migration that:
  /// 1. Updates visible name to "Tester"
  /// 2. Updates email to "tester@local.app"
  /// 3. Updates avatar initials to "T"
  /// 4. Preserves all other user settings (unit preferences, weights, etc.)
  static Future<void> migrateToTesterProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if migration already ran
      final migrationCompleted = prefs.getBool(_migrationKey) ?? false;
      if (migrationCompleted) {
        debugPrint('✅ Tester profile migration already completed');
        return;
      }

      // Load current user data
      const userStorageKey = 'current_user';
      final userData = prefs.getString(userStorageKey);
      
      if (userData == null) {
        debugPrint('⏭️ No existing user data - migration not needed');
        await prefs.setBool(_migrationKey, true);
        return;
      }

      // Parse existing user
      final userJson = json.decode(userData) as Map<String, dynamic>;
      final currentUser = User.fromJson(userJson);

      // Update only the visible identity fields, preserve everything else
      final updatedUser = currentUser.copyWith(
        name: 'Tester',
        email: 'tester@local.app',
        avatarInitials: 'T',
        updatedAt: DateTime.now(),
      );

      // Save updated user
      final updatedData = json.encode(updatedUser.toJson());
      await prefs.setString(userStorageKey, updatedData);

      // Mark migration as complete
      await prefs.setBool(_migrationKey, true);

      debugPrint('✅ User profile migrated to Tester identity');
      debugPrint('   Name: ${updatedUser.name}');
      debugPrint('   Email: ${updatedUser.email}');
      debugPrint('   Preserved settings: unit=${updatedUser.preferredUnit}, weight=${updatedUser.currentWeight}kg');
      
    } catch (e, stackTrace) {
      debugPrint('❌ User migration failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Don't throw - app should continue even if migration fails
      // The UserService will fall back to default user if needed
    }
  }
}
