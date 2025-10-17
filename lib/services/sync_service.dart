import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../models/photo.dart';
import '../state/app_state_provider.dart';
import 'firebase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool _isSyncing = false;

  // 오프라인 데이터 저장 키
  static const String _offlineEntriesKey = 'offline_entries';
  static const String _offlinePhotosKey = 'offline_photos';
  static const String _pendingSyncKey = 'pending_sync';

  // 네트워크 상태 감지
  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);

  // 현재 온라인 상태
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  // 동기화 상태 스트림
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // 네트워크 상태 초기화
  Future<void> initialize() async {
    // 초기 연결 상태 확인
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;

    // 연결 상태 변화 감지
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      // 오프라인에서 온라인으로 복귀 시 동기화
      if (wasOffline && _isOnline) {
        _syncOfflineData();
      }

      _syncStatusController.add(SyncStatus(
        isOnline: _isOnline,
        isSyncing: _isSyncing,
        hasOfflineData: await _hasOfflineData(),
      ));
    });

    // 앱 시작 시 오프라인 데이터 동기화
    if (_isOnline) {
      _syncOfflineData();
    }
  }

  // 오프라인 일기 저장
  Future<void> saveOfflineEntry(String date, DiaryEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineEntries = await _getOfflineEntries();
      
      offlineEntries[date] = entry;
      
      final entriesJson = offlineEntries.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      
      await prefs.setString(_offlineEntriesKey, 
          jsonEncode(entriesJson));
      
      // 동기화 대기 목록에 추가
      await _addToPendingSync(date, 'entry');
      
      _syncStatusController.add(SyncStatus(
        isOnline: _isOnline,
        isSyncing: _isSyncing,
        hasOfflineData: true,
      ));
      
      print('오프라인 일기 저장: $date');
    } catch (e) {
      print('오프라인 일기 저장 실패: $e');
    }
  }

  // 오프라인 사진 저장
  Future<void> saveOfflinePhoto(String date, String section, Photo photo, Uint8List fileBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlinePhotos = await _getOfflinePhotos();
      
      final photoKey = '${date}_${section}_${photo.id}';
      offlinePhotos[photoKey] = {
        'photo': photo.toJson(),
        'fileBytes': fileBytes,
      };
      
      await prefs.setString(_offlinePhotosKey, 
          jsonEncode(offlinePhotos));
      
      // 동기화 대기 목록에 추가
      await _addToPendingSync(photoKey, 'photo');
      
      _syncStatusController.add(SyncStatus(
        isOnline: _isOnline,
        isSyncing: _isSyncing,
        hasOfflineData: true,
      ));
      
      print('오프라인 사진 저장: $photoKey');
    } catch (e) {
      print('오프라인 사진 저장 실패: $e');
    }
  }

  // 오프라인 데이터 동기화
  Future<void> _syncOfflineData() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      _syncStatusController.add(SyncStatus(
        isOnline: _isOnline,
        isSyncing: true,
        hasOfflineData: true,
      ));

      // 일기 데이터 동기화
      await _syncOfflineEntries();
      
      // 사진 데이터 동기화
      await _syncOfflinePhotos();
      
      // 동기화 완료 후 오프라인 데이터 정리
      await _clearOfflineData();
      
      _syncStatusController.add(SyncStatus(
        isOnline: _isOnline,
        isSyncing: false,
        hasOfflineData: false,
      ));
      
      print('오프라인 데이터 동기화 완료');
    } catch (e) {
      print('오프라인 데이터 동기화 실패: $e');
      _syncStatusController.add(SyncStatus(
        isOnline: _isOnline,
        isSyncing: false,
        hasOfflineData: true,
        error: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  // 오프라인 일기 동기화
  Future<void> _syncOfflineEntries() async {
    final offlineEntries = await _getOfflineEntries();
    
    for (final entry in offlineEntries.values) {
      try {
        await _firebaseService.setEntry(entry.date, entry);
        print('일기 동기화 성공: ${entry.date}');
      } catch (e) {
        print('일기 동기화 실패: ${entry.date}, $e');
        throw e;
      }
    }
  }

  // 오프라인 사진 동기화
  Future<void> _syncOfflinePhotos() async {
    final offlinePhotos = await _getOfflinePhotos();
    
    for (final entry in offlinePhotos.entries) {
      try {
        final photoKey = entry.key;
        final photoData = entry.value;
        
        final photo = Photo.fromJson(photoData['photo']);
        final fileBytes = Uint8List.fromList(List<int>.from(photoData['fileBytes']));
        
        // Firebase Storage에 업로드
        final uploadedPhoto = await _firebaseService.uploadPhoto(
          photo.fileName,
          fileBytes,
          photo.fileName,
        );
        
        // Firestore에 URL 저장
        final date = photoKey.split('_')[0];
        final section = photoKey.split('_')[1];
        await _firebaseService.addPhotoToEntry(date, section, uploadedPhoto);
        
        print('사진 동기화 성공: $photoKey');
      } catch (e) {
        print('사진 동기화 실패: ${entry.key}, $e');
        throw e;
      }
    }
  }

  // 오프라인 일기 가져오기
  Future<Map<String, DiaryEntry>> _getOfflineEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_offlineEntriesKey);
      
      if (entriesJson == null) return {};
      
      final Map<String, dynamic> entriesMap = jsonDecode(entriesJson);
      return entriesMap.map(
        (key, value) => MapEntry(key, DiaryEntry.fromJson(value)),
      );
    } catch (e) {
      print('오프라인 일기 로드 실패: $e');
      return {};
    }
  }

  // 오프라인 사진 가져오기
  Future<Map<String, dynamic>> _getOfflinePhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photosJson = prefs.getString(_offlinePhotosKey);
      
      if (photosJson == null) return {};
      
      return Map<String, dynamic>.from(jsonDecode(photosJson));
    } catch (e) {
      print('오프라인 사진 로드 실패: $e');
      return {};
    }
  }

  // 동기화 대기 목록에 추가
  Future<void> _addToPendingSync(String key, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingSync = await _getPendingSync();
      
      pendingSync[key] = {
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_pendingSyncKey, jsonEncode(pendingSync));
    } catch (e) {
      print('동기화 대기 목록 추가 실패: $e');
    }
  }

  // 동기화 대기 목록 가져오기
  Future<Map<String, dynamic>> _getPendingSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingSyncJson = prefs.getString(_pendingSyncKey);
      
      if (pendingSyncJson == null) return {};
      
      return Map<String, dynamic>.from(jsonDecode(pendingSyncJson));
    } catch (e) {
      print('동기화 대기 목록 로드 실패: $e');
      return {};
    }
  }

  // 오프라인 데이터가 있는지 확인
  Future<bool> _hasOfflineData() async {
    final offlineEntries = await _getOfflineEntries();
    final offlinePhotos = await _getOfflinePhotos();
    return offlineEntries.isNotEmpty || offlinePhotos.isNotEmpty;
  }

  // 오프라인 데이터 정리
  Future<void> _clearOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineEntriesKey);
      await prefs.remove(_offlinePhotosKey);
      await prefs.remove(_pendingSyncKey);
      
      print('오프라인 데이터 정리 완료');
    } catch (e) {
      print('오프라인 데이터 정리 실패: $e');
    }
  }

  // 수동 동기화
  Future<void> manualSync() async {
    if (_isOnline) {
      await _syncOfflineData();
    }
  }

  // 리소스 정리
  void dispose() {
    _syncStatusController.close();
  }
}

// 동기화 상태 모델
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final bool hasOfflineData;
  final String? error;

  const SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.hasOfflineData,
    this.error,
  });

  @override
  String toString() {
    return 'SyncStatus(isOnline: $isOnline, isSyncing: $isSyncing, hasOfflineData: $hasOfflineData, error: $error)';
  }
}
