import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/diary_entry.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

class AppStateProvider extends ChangeNotifier {
  AppState _state = const AppState();
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService.getInstance();
  final SyncService _syncService = SyncService();

  // Firebase 서비스 접근을 위한 getter
  FirebaseService get firebaseService => _firebaseService;

  AppState get state => _state;

  // 상태 업데이트
  void _updateState(AppState newState) {
    _state = newState;
    notifyListeners();
  }

  // 로그인 (Firebase 익명 로그인 + 로컬 저장)
  Future<void> login(String familyPin, String role) async {
    try {
      setLoading(true);
      
      // Firebase 익명 로그인
      await _firebaseService.signInAnonymously();
      
      // 로컬 상태 업데이트
      _updateState(_state.copyWith(
        familyPin: familyPin,
        role: role,
        error: null,
        isOfflineMode: false,
      ));
      
      // 로컬 저장소에 저장
      await _storageService.saveFamilyPin(familyPin);
      await _storageService.saveUserRole(role);
      
      print('로그인 성공: $role');
    } catch (e) {
      setError('로그인에 실패했습니다: $e');
      print('로그인 실패: $e');
    } finally {
      setLoading(false);
    }
  }

  // 로그아웃 (Firebase + 로컬 저장소 정리)
  Future<void> logout() async {
    try {
      setLoading(true);
      
      // Firebase 로그아웃
      await _firebaseService.signOut();
      
      // 로컬 저장소 정리
      await _storageService.clearAppState();
      
      // 상태 초기화
      _updateState(const AppState());
      
      print('로그아웃 성공');
    } catch (e) {
      setError('로그아웃에 실패했습니다: $e');
      print('로그아웃 실패: $e');
    } finally {
      setLoading(false);
    }
  }

  // 선택된 날짜 변경
  void setSelectedDate(String? date) {
    _updateState(_state.copyWith(selectedDate: date));
  }

  // 로딩 상태 설정
  void setLoading(bool isLoading) {
    _updateState(_state.copyWith(isLoading: isLoading));
  }

  // 에러 설정
  void setError(String? error) {
    _updateState(_state.copyWith(error: error));
  }

  // 오프라인 모드 설정
  void setOfflineMode(bool isOffline) {
    _updateState(_state.copyWith(isOfflineMode: isOffline));
  }

  // 동기화 시간 업데이트
  void updateSyncTime() {
    _updateState(_state.copyWith(lastSyncTime: DateTime.now()));
  }

  // 일기 추가/업데이트
  void setDiaryEntry(DiaryEntry diary) {
    final updatedDiaries = Map<String, DiaryEntry>.from(_state.diaries);
    updatedDiaries[diary.date] = diary;
    
    _updateState(_state.copyWith(
      diaries: updatedDiaries,
      error: null,
    ));
  }

  // 일기 삭제
  void removeDiaryEntry(String date) {
    final updatedDiaries = Map<String, DiaryEntry>.from(_state.diaries);
    updatedDiaries.remove(date);
    
    _updateState(_state.copyWith(diaries: updatedDiaries));
  }

  // 자녀 일기 섹션 업데이트
  void updateChildSection(String date, DiarySection childSection) {
    final diary = _state.diaries[date];
    if (diary == null) {
      // 새 일기 생성
      final newDiary = DiaryEntry(
        date: date,
        child: childSection,
        parent: const DiarySection(),
        calendarEmoji: childSection.emotion.isEmpty ? '🌱' : childSection.emotion,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      setDiaryEntry(newDiary);
    } else {
      // 기존 일기 업데이트
      final updatedDiary = diary.copyWith(
        child: childSection,
        calendarEmoji: _calculateCalendarEmoji(childSection, diary.parent),
        updatedAt: DateTime.now(),
      );
      setDiaryEntry(updatedDiary);
    }
  }

  // 부모 일기 섹션 업데이트
  void updateParentSection(String date, DiarySection parentSection) {
    final diary = _state.diaries[date];
    if (diary == null) {
      // 새 일기 생성
      final newDiary = DiaryEntry(
        date: date,
        child: const DiarySection(),
        parent: parentSection,
        calendarEmoji: parentSection.emotion.isEmpty ? '🌱' : parentSection.emotion,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      setDiaryEntry(newDiary);
    } else {
      // 기존 일기 업데이트
      final updatedDiary = diary.copyWith(
        parent: parentSection,
        calendarEmoji: _calculateCalendarEmoji(diary.child, parentSection),
        updatedAt: DateTime.now(),
      );
      setDiaryEntry(updatedDiary);
    }
  }

  // 댓글 추가
  void addComment(String date, Comment comment) {
    final diary = _state.diaries[date];
    if (diary != null) {
      final updatedComments = List<Comment>.from(diary.comments);
      updatedComments.add(comment);
      
      final updatedDiary = diary.copyWith(
        comments: updatedComments,
        updatedAt: DateTime.now(),
      );
      setDiaryEntry(updatedDiary);
    }
  }

  // 댓글 업데이트
  void updateComment(String date, String commentId, Comment updatedComment) {
    final diary = _state.diaries[date];
    if (diary != null) {
      final updatedComments = diary.comments.map((comment) {
        return comment.id == commentId ? updatedComment : comment;
      }).toList();
      
      final updatedDiary = diary.copyWith(
        comments: updatedComments,
        updatedAt: DateTime.now(),
      );
      setDiaryEntry(updatedDiary);
    }
  }

  // 댓글 삭제
  void removeComment(String date, String commentId) {
    final diary = _state.diaries[date];
    if (diary != null) {
      final updatedComments = diary.comments
          .where((comment) => comment.id != commentId)
          .toList();
      
      final updatedDiary = diary.copyWith(
        comments: updatedComments,
        updatedAt: DateTime.now(),
      );
      setDiaryEntry(updatedDiary);
    }
  }

  // 달력 이모지 계산 (감정 규칙)
  String _calculateCalendarEmoji(DiarySection child, DiarySection parent) {
    final childEmotion = child.emotion;
    final parentEmotion = parent.emotion;
    
    // 1. 둘 다 선택한 경우
    if (childEmotion.isNotEmpty && parentEmotion.isNotEmpty) {
      if (childEmotion == parentEmotion) {
        return childEmotion; // 같은 감정
      } else {
        return '😐'; // 다른 감정 (중립 표시)
      }
    }
    // 2. 한쪽만 선택한 경우
    else if (childEmotion.isNotEmpty) {
      return childEmotion; // 자녀 감정
    } else if (parentEmotion.isNotEmpty) {
      return parentEmotion; // 부모 감정
    }
    // 3. 둘 다 선택하지 않은 경우
    else {
      return '🌱'; // 기본 표시
    }
  }

  // 일기 텍스트 업데이트 (현재 사용자 역할에 따라)
  void updateDiaryText(String date, String text) {
    if (_state.isParent) {
      final currentParent = _state.diaries[date]?.parent ?? const DiarySection();
      final updatedParent = currentParent.copyWith(
        text: text,
        lastModified: DateTime.now(),
      );
      updateParentSection(date, updatedParent);
    } else if (_state.isChild) {
      final currentChild = _state.diaries[date]?.child ?? const DiarySection();
      final updatedChild = currentChild.copyWith(
        text: text,
        lastModified: DateTime.now(),
      );
      updateChildSection(date, updatedChild);
    }
  }

  // 일기 감정 업데이트 (현재 사용자 역할에 따라)
  void updateDiaryEmotion(String date, String emotion) {
    if (_state.isParent) {
      final currentParent = _state.diaries[date]?.parent ?? const DiarySection();
      final updatedParent = currentParent.copyWith(
        emotion: emotion,
        lastModified: DateTime.now(),
      );
      updateParentSection(date, updatedParent);
    } else if (_state.isChild) {
      final currentChild = _state.diaries[date]?.child ?? const DiarySection();
      final updatedChild = currentChild.copyWith(
        emotion: emotion,
        lastModified: DateTime.now(),
      );
      updateChildSection(date, updatedChild);
    }
  }

  // 현재 사용자의 일기 섹션 가져오기
  DiarySection? getCurrentUserSection(String date) {
    if (_state.isParent) {
      return _state.diaries[date]?.parent;
    } else if (_state.isChild) {
      return _state.diaries[date]?.child;
    }
    return null;
  }

  // 현재 사용자의 일기 텍스트 가져오기
  String getCurrentUserText(String date) {
    return getCurrentUserSection(date)?.text ?? '';
  }

  // 현재 사용자의 일기 감정 가져오기
  String getCurrentUserEmotion(String date) {
    return getCurrentUserSection(date)?.emotion ?? '';
  }

  // 일기 섹션에 텍스트 설정
  void setDiaryText(String date, String text) {
    updateDiaryText(date, text);
  }

  // 일기 섹션에 감정 설정
  void setDiaryEmotion(String date, String emotion) {
    updateDiaryEmotion(date, emotion);
  }

  // 오프라인 일기 저장
  Future<void> saveOfflineDiary(String date, DiaryEntry entry) async {
    try {
      await _syncService.saveOfflineEntry(date, entry);
      print('오프라인 일기 저장 완료: $date');
    } catch (e) {
      print('오프라인 일기 저장 실패: $e');
      throw Exception('오프라인 일기 저장에 실패했습니다: $e');
    }
  }

  // 오프라인 사진 저장
  Future<void> saveOfflinePhoto(String date, String section, Photo photo, Uint8List fileBytes) async {
    try {
      await _syncService.saveOfflinePhoto(date, section, photo, fileBytes);
      print('오프라인 사진 저장 완료: $date/$section');
    } catch (e) {
      print('오프라인 사진 저장 실패: $e');
      throw Exception('오프라인 사진 저장에 실패했습니다: $e');
    }
  }

  // 상태 초기화
  void reset() {
    _updateState(const AppState());
  }

  // 디버그용 상태 출력
  void debugPrintState() {
    print('=== AppState Debug ===');
    print('Family PIN: ${_state.familyPin}');
    print('Role: ${_state.role}');
    print('Selected Date: ${_state.selectedDate}');
    print('Diaries Count: ${_state.diaries.length}');
    print('Is Loading: ${_state.isLoading}');
    print('Error: ${_state.error}');
    print('Is Offline: ${_state.isOfflineMode}');
    print('=====================');
  }
}
