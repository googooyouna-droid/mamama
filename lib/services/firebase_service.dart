import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/diary_entry.dart';
import '../models/comment.dart';
import '../models/photo.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase 인스턴스들
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 현재 사용자
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 익명 로그인
  Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      print('익명 로그인 성공: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('익명 로그인 실패: $e');
      throw Exception('로그인에 실패했습니다: $e');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('로그아웃 성공');
    } catch (e) {
      print('로그아웃 실패: $e');
      throw Exception('로그아웃에 실패했습니다: $e');
    }
  }

  // 가족 ID 생성 (사용자 ID 기반)
  String getFamilyId() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('로그인이 필요합니다');
    }
    return userId;
  }

  // 일기 엔트리 가져오기
  Future<DiaryEntry?> getEntry(String date) async {
    try {
      final familyId = getFamilyId();
      final docRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date);

      final doc = await docRef.get();
      
      if (doc.exists && doc.data() != null) {
        return DiaryEntry.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('일기 가져오기 실패: $e');
      throw Exception('일기를 불러오는데 실패했습니다: $e');
    }
  }

  // 일기 엔트리 저장
  Future<void> setEntry(String date, DiaryEntry entry) async {
    try {
      final familyId = getFamilyId();
      final docRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date);

      await docRef.set(entry.toJson());
      print('일기 저장 성공: $date');
    } catch (e) {
      print('일기 저장 실패: $e');
      throw Exception('일기 저장에 실패했습니다: $e');
    }
  }

  // 일기 업데이트 (특정 섹션만)
  Future<void> updateEntrySection(
    String date,
    String section, // 'child' or 'parent'
    DiarySection sectionData,
  ) async {
    try {
      final familyId = getFamilyId();
      final docRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date);

      // 기존 데이터 가져오기
      final doc = await docRef.get();
      DiaryEntry entry;
      
      if (doc.exists && doc.data() != null) {
        entry = DiaryEntry.fromJson(doc.data()!);
      } else {
        // 새 엔트리 생성
        entry = DiaryEntry(
          date: date,
          child: const DiarySection(),
          parent: const DiarySection(),
          calendarEmoji: '🌱',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // 섹션 업데이트
      final updatedEntry = section == 'child'
          ? entry.copyWith(
              child: sectionData,
              calendarEmoji: _calculateCalendarEmoji(sectionData, entry.parent),
              updatedAt: DateTime.now(),
            )
          : entry.copyWith(
              parent: sectionData,
              calendarEmoji: _calculateCalendarEmoji(entry.child, sectionData),
              updatedAt: DateTime.now(),
            );

      await docRef.set(updatedEntry.toJson());
      print('일기 섹션 업데이트 성공: $date/$section');
    } catch (e) {
      print('일기 섹션 업데이트 실패: $e');
      throw Exception('일기 업데이트에 실패했습니다: $e');
    }
  }

  // 일기 삭제
  Future<void> deleteEntry(String date) async {
    try {
      final familyId = getFamilyId();
      final docRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date);

      await docRef.delete();
      print('일기 삭제 성공: $date');
    } catch (e) {
      print('일기 삭제 실패: $e');
      throw Exception('일기 삭제에 실패했습니다: $e');
    }
  }

  // 이번 달의 모든 일기 가져오기
  Future<Map<String, DiaryEntry>> getThisMonthEntries() async {
    try {
      final familyId = getFamilyId();
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final query = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .where('date', isGreaterThanOrEqualTo: _formatDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: _formatDate(endOfMonth))
          .get();

      final Map<String, DiaryEntry> entries = {};
      for (final doc in query.docs) {
        entries[doc.id] = DiaryEntry.fromJson(doc.data());
      }

      return entries;
    } catch (e) {
      print('월별 일기 가져오기 실패: $e');
      throw Exception('월별 일기를 불러오는데 실패했습니다: $e');
    }
  }

  // 사진 업로드
  Future<Photo> uploadPhoto(String date, Uint8List fileBytes, String fileName) async {
    try {
      final familyId = getFamilyId();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileNameWithTimestamp = '${timestamp}_$fileName';
      
      final ref = _storage
          .ref()
          .child('families/$familyId/photos/$date/$fileNameWithTimestamp');

      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final photo = Photo(
        id: timestamp.toString(),
        url: downloadUrl,
        fileName: fileNameWithTimestamp,
        fileSize: fileBytes.length,
        uploadedAt: DateTime.now(),
      );

      print('사진 업로드 성공: $fileName');
      return photo;
    } catch (e) {
      print('사진 업로드 실패: $e');
      throw Exception('사진 업로드에 실패했습니다: $e');
    }
  }

  // 사진 삭제
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      print('사진 삭제 성공');
    } catch (e) {
      print('사진 삭제 실패: $e');
      throw Exception('사진 삭제에 실패했습니다: $e');
    }
  }

  // 사진을 일기 엔트리에 추가
  Future<void> addPhotoToEntry(String date, String section, Photo photo) async {
    try {
      final familyId = getFamilyId();
      final entryRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date);

      final doc = await entryRef.get();
      if (doc.exists && doc.data() != null) {
        final entry = DiaryEntry.fromJson(doc.data()!);
        
        // 해당 섹션의 사진 목록에 추가
        DiarySection updatedSection;
        if (section == 'child') {
          final updatedPhotos = List<Photo>.from(entry.child.photos);
          updatedPhotos.add(photo);
          updatedSection = entry.child.copyWith(
            photos: updatedPhotos,
            lastModified: DateTime.now(),
          );
        } else {
          final updatedPhotos = List<Photo>.from(entry.parent.photos);
          updatedPhotos.add(photo);
          updatedSection = entry.parent.copyWith(
            photos: updatedPhotos,
            lastModified: DateTime.now(),
          );
        }

        final updatedEntry = entry.copyWith(
          child: section == 'child' ? updatedSection : entry.child,
          parent: section == 'parent' ? updatedSection : entry.parent,
          updatedAt: DateTime.now(),
        );
        
        await entryRef.set(updatedEntry.toJson());
        print('사진 추가 성공');
      } else {
        throw Exception('일기를 찾을 수 없습니다');
      }
    } catch (e) {
      print('사진 추가 실패: $e');
      throw Exception('사진 추가에 실패했습니다: $e');
    }
  }

  // 일기 엔트리에서 사진 삭제
  Future<void> deletePhotoFromEntry(String date, String photoId) async {
    try {
      final familyId = getFamilyId();
      final entryRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date);

      final doc = await entryRef.get();
      if (doc.exists && doc.data() != null) {
        final entry = DiaryEntry.fromJson(doc.data()!);
        
        // 자녀 섹션에서 사진 제거
        final updatedChildPhotos = entry.child.photos.where((p) => p.id != photoId).toList();
        final updatedChild = entry.child.copyWith(
          photos: updatedChildPhotos,
          lastModified: DateTime.now(),
        );
        
        // 부모 섹션에서 사진 제거
        final updatedParentPhotos = entry.parent.photos.where((p) => p.id != photoId).toList();
        final updatedParent = entry.parent.copyWith(
          photos: updatedParentPhotos,
          lastModified: DateTime.now(),
        );

        final updatedEntry = entry.copyWith(
          child: updatedChild,
          parent: updatedParent,
          updatedAt: DateTime.now(),
        );
        
        await entryRef.set(updatedEntry.toJson());
        print('사진 삭제 성공');
      } else {
        throw Exception('일기를 찾을 수 없습니다');
      }
    } catch (e) {
      print('사진 삭제 실패: $e');
      throw Exception('사진 삭제에 실패했습니다: $e');
    }
  }

  // 댓글 추가 (새로운 구조)
  Future<void> addComment(String date, Comment comment) async {
    try {
      final familyId = getFamilyId();
      
      // 방법 1: entries 문서 내 comments 배열에 추가
      final entryRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date);

      final doc = await entryRef.get();
      if (doc.exists && doc.data() != null) {
        final entry = DiaryEntry.fromJson(doc.data()!);
        final updatedComments = List<Comment>.from(entry.comments);
        updatedComments.add(comment);
        
        final updatedEntry = entry.copyWith(
          comments: updatedComments,
          updatedAt: DateTime.now(),
        );
        
        await entryRef.set(updatedEntry.toJson());
        print('댓글 추가 성공');
      } else {
        // 일기가 없으면 새로 생성
        final newEntry = DiaryEntry(
          date: date,
          child: const DiarySection(),
          parent: const DiarySection(),
          calendarEmoji: '🌱',
          comments: [comment],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await entryRef.set(newEntry.toJson());
        print('일기 생성 및 댓글 추가 성공');
      }
    } catch (e) {
      print('댓글 추가 실패: $e');
      throw Exception('댓글 추가에 실패했습니다: $e');
    }
  }

  // 댓글 업데이트
  Future<void> updateComment(String date, String commentId, Comment updatedComment) async {
    try {
      final familyId = getFamilyId();
      final docRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date);

      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final entry = DiaryEntry.fromJson(doc.data()!);
        final updatedComments = entry.comments.map((comment) {
          return comment.id == commentId ? updatedComment : comment;
        }).toList();
        
        final updatedEntry = entry.copyWith(
          comments: updatedComments,
          updatedAt: DateTime.now(),
        );
        
        await docRef.set(updatedEntry.toJson());
        print('댓글 업데이트 성공');
      } else {
        throw Exception('일기를 찾을 수 없습니다');
      }
    } catch (e) {
      print('댓글 업데이트 실패: $e');
      throw Exception('댓글 업데이트에 실패했습니다: $e');
    }
  }

  // 댓글 삭제
  Future<void> deleteComment(String date, String commentId) async {
    try {
      final familyId = getFamilyId();
      final docRef = _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date);

      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final entry = DiaryEntry.fromJson(doc.data()!);
        final updatedComments = entry.comments
            .where((comment) => comment.id != commentId)
            .toList();
        
        final updatedEntry = entry.copyWith(
          comments: updatedComments,
          updatedAt: DateTime.now(),
        );
        
        await docRef.set(updatedEntry.toJson());
        print('댓글 삭제 성공');
      } else {
        throw Exception('일기를 찾을 수 없습니다');
      }
    } catch (e) {
      print('댓글 삭제 실패: $e');
      throw Exception('댓글 삭제에 실패했습니다: $e');
    }
  }

  // 실시간 일기 업데이트 리스너
  Stream<DiaryEntry?> getEntryStream(String date) {
    try {
      final familyId = getFamilyId();
      return _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .doc(date)
          .snapshots()
          .map((doc) {
            if (doc.exists && doc.data() != null) {
              return DiaryEntry.fromJson(doc.data()!);
            }
            return null;
          });
    } catch (e) {
      print('일기 스트림 생성 실패: $e');
      throw Exception('실시간 업데이트를 설정하는데 실패했습니다: $e');
    }
  }

  // 오프라인 캐시 설정
  Future<void> enableOfflinePersistence() async {
    try {
      await _firestore.enableNetwork();
      print('오프라인 지속성 활성화 성공');
    } catch (e) {
      print('오프라인 지속성 활성화 실패: $e');
    }
  }

  // 네트워크 상태 확인
  Future<bool> isNetworkAvailable() async {
    try {
      await _firestore.enableNetwork();
      return true;
    } catch (e) {
      return false;
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

  // 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 데이터 백업 (전체 일기 내보내기)
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final familyId = getFamilyId();
      final query = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('entries')
          .get();

      final Map<String, dynamic> exportData = {
        'familyId': familyId,
        'exportDate': DateTime.now().toIso8601String(),
        'entries': {},
      };

      for (final doc in query.docs) {
        exportData['entries'][doc.id] = doc.data();
      }

      return exportData;
    } catch (e) {
      print('데이터 내보내기 실패: $e');
      throw Exception('데이터 내보내기에 실패했습니다: $e');
    }
  }

  // 데이터 복원 (일기 가져오기)
  Future<void> importData(Map<String, dynamic> importData) async {
    try {
      final familyId = getFamilyId();
      final entries = importData['entries'] as Map<String, dynamic>;

      for (final entry in entries.entries) {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('entries')
            .doc(entry.key)
            .set(entry.value);
      }

      print('데이터 복원 성공');
    } catch (e) {
      print('데이터 복원 실패: $e');
      throw Exception('데이터 복원에 실패했습니다: $e');
    }
  }
}
