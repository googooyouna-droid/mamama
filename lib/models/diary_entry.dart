import 'comment.dart';
import 'photo.dart';

class DiaryEntry {
  final String date;
  final DiarySection child;
  final DiarySection parent;
  final String calendarEmoji;
  final List<Comment> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryEntry({
    required this.date,
    required this.child,
    required this.parent,
    required this.calendarEmoji,
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'child': child.toJson(),
      'parent': parent.toJson(),
      'calendarEmoji': calendarEmoji,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      date: json['date'] as String,
      child: DiarySection.fromJson(json['child'] as Map<String, dynamic>),
      parent: DiarySection.fromJson(json['parent'] as Map<String, dynamic>),
      calendarEmoji: json['calendarEmoji'] as String,
      comments: (json['comments'] as List<dynamic>?)
          ?.map((comment) => Comment.fromJson(comment as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // 복사본 생성 (상태 업데이트용)
  DiaryEntry copyWith({
    String? date,
    DiarySection? child,
    DiarySection? parent,
    String? calendarEmoji,
    List<Comment>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      date: date ?? this.date,
      child: child ?? this.child,
      parent: parent ?? this.parent,
      calendarEmoji: calendarEmoji ?? this.calendarEmoji,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 감정 이모티콘 결정 로직
  String getDisplayEmoji() {
    final childEmotion = child.emotion;
    final parentEmotion = parent.emotion;
    
    if (childEmotion.isNotEmpty && parentEmotion.isNotEmpty) {
      // 둘 다 선택한 경우
      if (childEmotion == parentEmotion) {
        return childEmotion; // 같은 감정
      } else {
        return '😐'; // 다른 감정
      }
    } else if (childEmotion.isNotEmpty) {
      return childEmotion; // 자녀만 선택
    } else if (parentEmotion.isNotEmpty) {
      return parentEmotion; // 부모만 선택
    } else {
      return '🌱'; // 기본값
    }
  }

  // 일기가 비어있는지 확인
  bool get isEmpty => 
      child.text.isEmpty && 
      parent.text.isEmpty && 
      child.photos.isEmpty && 
      parent.photos.isEmpty;

  // 일기가 작성되었는지 확인
  bool get hasContent => 
      child.text.isNotEmpty || 
      parent.text.isNotEmpty || 
      child.photos.isNotEmpty || 
      parent.photos.isNotEmpty;
}

class DiarySection {
  final String text;
  final String emotion;
  final List<Photo> photos;
  final DateTime? lastModified;

  const DiarySection({
    this.text = '',
    this.emotion = '',
    this.photos = const [],
    this.lastModified,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'emotion': emotion,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory DiarySection.fromJson(Map<String, dynamic> json) {
    return DiarySection(
      text: json['text'] as String? ?? '',
      emotion: json['emotion'] as String? ?? '',
      photos: (json['photos'] as List<dynamic>?)
          ?.map((photo) => Photo.fromJson(photo as Map<String, dynamic>))
          .toList() ?? [],
      lastModified: json['lastModified'] != null 
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  // 복사본 생성
  DiarySection copyWith({
    String? text,
    String? emotion,
    List<Photo>? photos,
    DateTime? lastModified,
  }) {
    return DiarySection(
      text: text ?? this.text,
      emotion: emotion ?? this.emotion,
      photos: photos ?? this.photos,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  // 섹션이 비어있는지 확인
  bool get isEmpty => text.isEmpty && photos.isEmpty;

  // 섹션에 내용이 있는지 확인
  bool get hasContent => text.isNotEmpty || photos.isNotEmpty;
}

class Photo {
  final String id;
  final String url;
  final String fileName;
  final int fileSize;
  final DateTime uploadedAt;

  const Photo({
    required this.id,
    required this.url,
    required this.fileName,
    required this.fileSize,
    required this.uploadedAt,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  // 파일 크기를 읽기 쉬운 형태로 변환
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}
