import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:total_athlete/models/user.dart';

/// Service for playing audio cues during workouts
/// Provides non-intrusive haptic/sound alerts without interrupting music playback
class AudioCueService {
  static final AudioCueService _instance = AudioCueService._internal();
  factory AudioCueService() => _instance;
  AudioCueService._internal();

  /// Initialize audio cue service
  Future<void> initialize() async {
    debugPrint('✅ Audio cue service initialized (using system haptics)');
  }

  /// Play workout start cue (double haptic + notification sound)
  Future<void> playWorkoutStart(User? user) async {
    if (user?.audioWorkoutStart ?? true) {
      await _playHapticPattern([
        HapticFeedback.mediumImpact,
        Future.delayed(const Duration(milliseconds: 150)),
        HapticFeedback.mediumImpact,
      ]);
      debugPrint('🔊 Playing workout start cue');
    }
  }

  /// Play workout complete cue (triple haptic for success)
  Future<void> playWorkoutComplete(User? user) async {
    if (user?.audioWorkoutComplete ?? true) {
      await _playHapticPattern([
        HapticFeedback.mediumImpact,
        Future.delayed(const Duration(milliseconds: 100)),
        HapticFeedback.mediumImpact,
        Future.delayed(const Duration(milliseconds: 100)),
        HapticFeedback.heavyImpact,
      ]);
      debugPrint('🔊 Playing workout complete cue');
    }
  }

  /// Play set start cue (light haptic)
  Future<void> playSetStart(User? user) async {
    if (user?.audioSetStart ?? false) {
      await HapticFeedback.lightImpact();
      debugPrint('🔊 Playing set start cue');
    }
  }

  /// Play set completion cue (medium haptic)
  Future<void> playSetComplete(User? user) async {
    if (user?.audioSetComplete ?? true) {
      await HapticFeedback.mediumImpact();
      debugPrint('🔊 Playing set complete cue');
    }
  }

  /// Play rest timer start cue (light haptic)
  Future<void> playRestStart(User? user) async {
    if (user?.audioRestStart ?? false) {
      await HapticFeedback.lightImpact();
      debugPrint('🔊 Playing rest start cue');
    }
  }

  /// Play rest timer completion cue (double haptic)
  Future<void> playRestComplete(User? user) async {
    if (user?.audioRestComplete ?? true) {
      await _playHapticPattern([
        HapticFeedback.mediumImpact,
        Future.delayed(const Duration(milliseconds: 100)),
        HapticFeedback.mediumImpact,
      ]);
      debugPrint('🔊 Playing rest complete cue');
    }
  }

  /// Play a pattern of haptic feedback with delays
  Future<void> _playHapticPattern(List<dynamic> pattern) async {
    try {
      for (final item in pattern) {
        if (item is Function) {
          await item();
        } else if (item is Future) {
          await item;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to play haptic pattern: $e');
      // Silently fail - don't disrupt workout flow
    }
  }

  /// Dispose of resources (no-op for haptic-only implementation)
  void dispose() {
    // No resources to dispose
  }
}
