import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for persisting progression screen state
class ProgressionStateService {
  static const String _scrollPositionKey = 'progression_scroll_position';
  static const String _currentViewKey = 'progression_current_view';
  static const String _lastVisitedKey = 'progression_last_visited';
  
  static SharedPreferences? _prefs;
  
  /// Initialize the service
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Save scroll position
  static Future<void> saveScrollPosition(double position) async {
    await initialize();
    await _prefs!.setDouble(_scrollPositionKey, position);
  }
  
  /// Get saved scroll position
  static Future<double> getScrollPosition() async {
    await initialize();
    return _prefs!.getDouble(_scrollPositionKey) ?? 0.0;
  }
  
  /// Save current view state
  static Future<void> saveCurrentView({
    String? selectedAchievementId,
    bool showCelebration = false,
    double qualityScale = 1.0,
  }) async {
    await initialize();
    
    final viewState = {
      'selectedAchievementId': selectedAchievementId,
      'showCelebration': showCelebration,
      'qualityScale': qualityScale,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await _prefs!.setString(_currentViewKey, jsonEncode(viewState));
  }
  
  /// Get saved current view state
  static Future<Map<String, dynamic>?> getCurrentView() async {
    await initialize();
    
    final viewStateJson = _prefs!.getString(_currentViewKey);
    if (viewStateJson == null) return null;
    
    try {
      final viewState = jsonDecode(viewStateJson) as Map<String, dynamic>;
      
      // Check if state is not too old (older than 1 hour)
      final timestamp = viewState['timestamp'] as int?;
      if (timestamp != null) {
        final stateAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (stateAge > 3600000) { // 1 hour in milliseconds
          await clearCurrentView();
          return null;
        }
      }
      
      return viewState;
    } catch (e) {
      // Invalid JSON, clear it
      await clearCurrentView();
      return null;
    }
  }
  
  /// Clear current view state
  static Future<void> clearCurrentView() async {
    await initialize();
    await _prefs!.remove(_currentViewKey);
  }
  
  /// Save last visited timestamp
  static Future<void> saveLastVisited() async {
    await initialize();
    await _prefs!.setInt(_lastVisitedKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Get last visited timestamp
  static Future<DateTime?> getLastVisited() async {
    await initialize();
    final timestamp = _prefs!.getInt(_lastVisitedKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  /// Clear all progression state
  static Future<void> clearAllState() async {
    await initialize();
    await _prefs!.remove(_scrollPositionKey);
    await _prefs!.remove(_currentViewKey);
    await _prefs!.remove(_lastVisitedKey);
  }
  
  /// Check if this is the first visit
  static Future<bool> isFirstVisit() async {
    final lastVisited = await getLastVisited();
    return lastVisited == null;
  }
}