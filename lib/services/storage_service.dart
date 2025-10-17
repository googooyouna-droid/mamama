import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';

class StorageService {
  static const String _familyPinKey = 'family_pin';
  static const String _roleKey = 'user_role';
  static const String _selectedDateKey = 'selected_date';
  static const String _diariesKey = 'diaries_data';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _isOfflineModeKey = 'is_offline_mode';

  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // 가족 PIN 저장
  Future<bool> saveFamilyPin(String pin) async {
    return await _prefs!.setString(_familyPinKey, pin);
  }

  // 가족 PIN 가져오기
  String? getFamilyPin() {
    return _prefs!.getString(_familyPinKey);
  }

  // 가족 PIN 삭제
  Future<bool> removeFamilyPin() async {
    return await _prefs!.remove(_familyPinKey);
  }

  // 사용자 역할 저장
  Future<bool> saveUserRole(String role) async {
    return await _prefs!.setString(_roleKey, role);
  }

  // 사용자 역할 가져오기
  String? getUserRole() {
    return _prefs!.getString(_roleKey);
  }

  // 사용자 역할 삭제
  Future<bool> removeUserRole() async {
    return await _prefs!.remove(_roleKey);
  }

  // 선택된 날짜 저장
  Future<bool> saveSelectedDate(String date) async {
    return await _prefs!.setString(_selectedDateKey, date);
  }

  // 선택된 날짜 가져오기
  String? getSelectedDate() {
    return _prefs!.getString(_selectedDateKey);
  }

  // 선택된 날짜 삭제
  Future<bool> removeSelectedDate() async {
    return await _prefs!.remove(_selectedDateKey);
  }

  // 일기 데이터 저장
  Future<bool> saveDiaries(Map<String, dynamic> diaries) async {
    final jsonString = jsonEncode(diaries);
    return await _prefs!.setString(_diariesKey, jsonString);
  }

  // 일기 데이터 가져오기
  Map<String, dynamic>? getDiaries() {
    final jsonString = _prefs!.getString(_diariesKey);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing diaries data: $e');
        return null;
      }
    }
    return null;
  }

  // 일기 데이터 삭제
  Future<bool> removeDiaries() async {
    return await _prefs!.remove(_diariesKey);
  }

  // 마지막 동기화 시간 저장
  Future<bool> saveLastSyncTime(DateTime time) async {
    return await _prefs!.setString(_lastSyncTimeKey, time.toIso8601String());
  }

  // 마지막 동기화 시간 가져오기
  DateTime? getLastSyncTime() {
    final timeString = _prefs!.getString(_lastSyncTimeKey);
    if (timeString != null) {
      try {
        return DateTime.parse(timeString);
      } catch (e) {
        print('Error parsing last sync time: $e');
        return null;
      }
    }
    return null;
  }

  // 마지막 동기화 시간 삭제
  Future<bool> removeLastSyncTime() async {
    return await _prefs!.remove(_lastSyncTimeKey);
  }

  // 오프라인 모드 상태 저장
  Future<bool> saveOfflineMode(bool isOffline) async {
    return await _prefs!.setBool(_isOfflineModeKey, isOffline);
  }

  // 오프라인 모드 상태 가져오기
  bool getOfflineMode() {
    return _prefs!.getBool(_isOfflineModeKey) ?? false;
  }

  // 오프라인 모드 상태 삭제
  Future<bool> removeOfflineMode() async {
    return await _prefs!.remove(_isOfflineModeKey);
  }

  // 앱 상태 전체 저장
  Future<bool> saveAppState(AppState state) async {
    try {
      final futures = await Future.wait([
        saveFamilyPin(state.familyPin ?? ''),
        saveUserRole(state.role ?? ''),
        saveSelectedDate(state.selectedDate ?? ''),
        saveDiaries(state.toJson()['diaries'] as Map<String, dynamic>),
        saveLastSyncTime(state.lastSyncTime),
        saveOfflineMode(state.isOfflineMode),
      ]);
      
      return futures.every((result) => result);
    } catch (e) {
      print('Error saving app state: $e');
      return false;
    }
  }

  // 앱 상태 전체 로드
  Future<AppState?> loadAppState() async {
    try {
      final familyPin = getFamilyPin();
      final role = getUserRole();
      final selectedDate = getSelectedDate();
      final diaries = getDiaries();
      final lastSyncTime = getLastSyncTime();
      final isOfflineMode = getOfflineMode();

      // 필수 데이터가 없으면 null 반환
      if (familyPin == null || role == null) {
        return null;
      }

      return AppState(
        familyPin: familyPin,
        role: role,
        selectedDate: selectedDate,
        diaries: diaries != null 
            ? Map<String, dynamic>.from(diaries).map(
                (key, value) => MapEntry(key, value),
              )
            : {},
        lastSyncTime: lastSyncTime ?? DateTime.now(),
        isOfflineMode: isOfflineMode,
      );
    } catch (e) {
      print('Error loading app state: $e');
      return null;
    }
  }

  // 앱 상태 전체 삭제 (로그아웃 시)
  Future<bool> clearAppState() async {
    try {
      final futures = await Future.wait([
        removeFamilyPin(),
        removeUserRole(),
        removeSelectedDate(),
        removeDiaries(),
        removeLastSyncTime(),
        removeOfflineMode(),
      ]);
      
      return futures.every((result) => result);
    } catch (e) {
      print('Error clearing app state: $e');
      return false;
    }
  }

  // 저장소 크기 확인
  Future<int> getStorageSize() async {
    final keys = _prefs!.getKeys();
    int totalSize = 0;
    
    for (final key in keys) {
      final value = _prefs!.get(key);
      if (value is String) {
        totalSize += value.length;
      }
    }
    
    return totalSize;
  }

  // 저장소 정리 (오래된 데이터 삭제)
  Future<bool> cleanupStorage() async {
    try {
      // 필요시 특정 키들만 유지하고 나머지 삭제
      final keysToKeep = {
        _familyPinKey,
        _roleKey,
        _selectedDateKey,
        _diariesKey,
        _lastSyncTimeKey,
        _isOfflineModeKey,
      };
      
      final allKeys = _prefs!.getKeys();
      final keysToRemove = allKeys.where((key) => !keysToKeep.contains(key));
      
      for (final key in keysToRemove) {
        await _prefs!.remove(key);
      }
      
      return true;
    } catch (e) {
      print('Error cleaning up storage: $e');
      return false;
    }
  }

  // 백업 데이터 생성 (JSON 문자열)
  Future<String?> createBackup() async {
    try {
      final appState = await loadAppState();
      if (appState != null) {
        return jsonEncode(appState.toJson());
      }
      return null;
    } catch (e) {
      print('Error creating backup: $e');
      return null;
    }
  }

  // 백업 데이터 복원
  Future<bool> restoreBackup(String backupData) async {
    try {
      final jsonData = jsonDecode(backupData) as Map<String, dynamic>;
      final appState = AppState.fromJson(jsonData);
      
      return await saveAppState(appState);
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }
}
