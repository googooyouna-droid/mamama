class Comment {
  final String id;
  final String target; // 'child' or 'parent'
  final String authorRole; // 'parent' or 'child'
  final String? parentId; // 대댓글인 경우 부모 댓글 ID
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> stickers; // 감정 스티커들 (❤️, 👍, 🌸 등)

  const Comment({
    required this.id,
    required this.target,
    required this.authorRole,
    this.parentId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.stickers = const [],
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target': target,
      'authorRole': authorRole,
      'parentId': parentId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'stickers': stickers,
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      target: json['target'] as String,
      authorRole: json['authorRole'] as String,
      parentId: json['parentId'] as String?,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      stickers: List<String>.from(json['stickers'] as List<dynamic>? ?? []),
    );
  }

  // 복사본 생성
  Comment copyWith({
    String? id,
    String? target,
    String? authorRole,
    String? parentId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? stickers,
  }) {
    return Comment(
      id: id ?? this.id,
      target: target ?? this.target,
      authorRole: authorRole ?? this.authorRole,
      parentId: parentId ?? this.parentId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stickers: stickers ?? this.stickers,
    );
  }

  // 대댓글인지 확인
  bool get isReply => parentId != null;

  // 댓글 깊이 (1단: 댓글, 2단: 답글, 3단: 재답글)
  int get depth {
    if (parentId == null) return 1;
    // 실제로는 부모 댓글의 깊이를 확인해야 하지만, 
    // 현재 구조에서는 단순히 2단으로 처리
    return 2;
  }

  // 댓글 작성자 표시명
  String get authorDisplayName {
    return authorRole == 'parent' ? '부모' : '자녀';
  }

  // 댓글 작성자 이모지
  String get authorEmoji {
    return authorRole == 'parent' ? '👨‍👩‍👧‍👦' : '👶';
  }

  // 스티커가 있는지 확인
  bool get hasStickers => stickers.isNotEmpty;

  // 댓글 타겟 표시명
  String get targetDisplayName {
    return target == 'parent' ? '부모' : '자녀';
  }

  // 댓글 생성 (팩토리 메서드)
  static Comment create({
    required String target,
    required String authorRole,
    String? parentId,
    required String text,
    List<String> stickers = const [],
  }) {
    final now = DateTime.now();
    return Comment(
      id: _generateId(),
      target: target,
      authorRole: authorRole,
      parentId: parentId,
      text: text,
      createdAt: now,
      updatedAt: now,
      stickers: stickers,
    );
  }

  // ID 생성 (실제로는 UUID 사용 권장)
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
           (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }

  // 감정 스티커 추가
  Comment addSticker(String sticker) {
    if (stickers.contains(sticker)) return this;
    
    return copyWith(
      stickers: [...stickers, sticker],
      updatedAt: DateTime.now(),
    );
  }

  // 감정 스티커 제거
  Comment removeSticker(String sticker) {
    if (!stickers.contains(sticker)) return this;
    
    return copyWith(
      stickers: stickers.where((s) => s != sticker).toList(),
      updatedAt: DateTime.now(),
    );
  }

  // 댓글 수정
  Comment updateText(String newText) {
    return copyWith(
      text: newText,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Comment(id: $id, target: $target, authorRole: $authorRole, text: $text)';
  }
}
