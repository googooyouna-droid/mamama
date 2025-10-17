import 'diary_entry.dart';

class AppState {
  final String? familyPin;
  final String? role; // 'parent' or 'child'
  final String? selectedDate;
  final Map<String, DiaryEntry> diaries;
  final bool isLoading;
  final String? error;
  final DateTime lastSyncTime;
  final bool isOfflineMode;

  const AppState({
    this.familyPin,
    this.role,
    this.selectedDate,
    this.diaries = const {},
    this.isLoading = false,
    this.error,
    this.lastSyncTime = const Duration().inDays == 0 ? DateTime.now() : DateTime(2025),
    this.isOfflineMode = false,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'familyPin': familyPin,
      'role': role,
      'selectedDate': selectedDate,
      'diaries': diaries.map((key, value) => MapEntry(key, value.toJson())),
      'isLoading': isLoading,
      'error': error,
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'isOfflineMode': isOfflineMode,
    };
  }

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      familyPin: json['familyPin'] as String?,
      role: json['role'] as String?,
      selectedDate: json['selectedDate'] as String?,
      diaries: (json['diaries'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, DiaryEntry.fromJson(value as Map<String, dynamic>)),
      ) ?? {},
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
      lastSyncTime: json['lastSyncTime'] != null 
          ? DateTime.parse(json['lastSyncTime'] as String)
          : DateTime.now(),
      isOfflineMode: json['isOfflineMode'] as bool? ?? false,
    );
  }

  // 복사본 생성
  AppState copyWith({
    String? familyPin,
    String? role,
    String? selectedDate,
    Map<String, DiaryEntry>? diaries,
    bool? isLoading,
    String? error,
    DateTime? lastSyncTime,
    bool? isOfflineMode,
  }) {
    return AppState(
      familyPin: familyPin ?? this.familyPin,
      role: role ?? this.role,
      selectedDate: selectedDate ?? this.selectedDate,
      diaries: diaries ?? this.diaries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }

  // 로그인 상태 확인
  bool get isLoggedIn => familyPin != null && role != null;

  // 부모인지 확인
  bool get isParent => role == 'parent';

  // 자녀인지 확인
  bool get isChild => role == 'child';

  // 선택된 날짜의 일기 가져오기
  DiaryEntry? getSelectedDiary() {
    if (selectedDate == null) return null;
    return diaries[selectedDate];
  }

  // 특정 날짜의 일기 가져오기
  DiaryEntry? getDiaryByDate(String date) {
    return diaries[date];
  }

  // 오늘 날짜 문자열 (YYYY-MM-DD)
  String get todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // 오늘 일기 가져오기
  DiaryEntry? get todayDiary {
    return getDiaryByDate(todayDate);
  }

  // 이번 달의 모든 일기 가져오기
  Map<String, DiaryEntry> getThisMonthDiaries() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return diaries.where((date, diary) {
      final diaryDate = DateTime.parse(date);
      return diaryDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
             diaryDate.isBefore(endOfMonth.add(const Duration(days: 1)));
    });
  }

  // 동기화가 필요한지 확인 (1시간 이상 지났으면)
  bool get needsSync {
    return DateTime.now().difference(lastSyncTime).inHours >= 1;
  }

  // 오프라인 모드 상태 메시지
  String get offlineStatusMessage {
    if (isOfflineMode) {
      return '오프라인 모드 - 연결 시 자동 동기화됩니다';
    }
    return '온라인 모드';
  }

  // 로딩 상태 메시지
  String get loadingMessage {
    if (isLoading) {
      return '데이터를 불러오는 중...';
    }
    return '';
  }

  // 에러 메시지
  String get errorMessage {
    return error ?? '';
  }

  // 사용자 역할 표시명
  String get roleDisplayName {
    switch (role) {
      case 'parent':
        return '부모';
      case 'child':
        return '자녀';
      default:
        return '사용자';
    }
  }

  // 사용자 역할 이모지
  String get roleEmoji {
    switch (role) {
      case 'parent':
        return '👨‍👩‍👧‍👦';
      case 'child':
        return '👶';
      default:
        return '👤';
    }
  }

  // 일기 작성 권한 확인
  bool canWriteDiary(String date) {
    // 기본적으로 모든 날짜에 작성 가능
    // 필요시 특별한 규칙 추가 가능
    return isLoggedIn;
  }

  // 댓글 작성 권한 확인
  bool canWriteComment(String date) {
    return isLoggedIn && diaries.containsKey(date);
  }

  // 사진 업로드 권한 확인
  bool canUploadPhoto(String date) {
    return isLoggedIn;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState &&
        other.familyPin == familyPin &&
        other.role == role &&
        other.selectedDate == selectedDate &&
        other.diaries.length == diaries.length &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.lastSyncTime == lastSyncTime &&
        other.isOfflineMode == isOfflineMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      familyPin,
      role,
      selectedDate,
      diaries,
      isLoading,
      error,
      lastSyncTime,
      isOfflineMode,
    );
  }

  @override
  String toString() {
    return 'AppState(familyPin: $familyPin, role: $role, selectedDate: $selectedDate, diaries: ${diaries.length}, isLoading: $isLoading, error: $error, isOfflineMode: $isOfflineMode)';
  }
}
