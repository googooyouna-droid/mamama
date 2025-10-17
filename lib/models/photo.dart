enum PhotoStatus {
  pending,    // ⌛ 대기 중
  uploading,  // 🔄 업로드 중
  uploaded,   // ✅ 업로드 완료
  failed,     // ⚠ 업로드 실패
}

class Photo {
  final String id;
  final String fileName;
  final String url;
  final DateTime? uploadedAt;
  final PhotoStatus status;

  const Photo({
    required this.id,
    required this.fileName,
    required this.url,
    this.uploadedAt,
    required this.status,
  });

  // 복사 생성자
  Photo copyWith({
    String? id,
    String? fileName,
    String? url,
    DateTime? uploadedAt,
    PhotoStatus? status,
  }) {
    return Photo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      url: url ?? this.url,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'url': url,
      'uploadedAt': uploadedAt?.toIso8601String(),
      'status': status.name,
    };
  }

  // JSON에서 생성
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      url: json['url'] ?? '',
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.parse(json['uploadedAt']) 
          : null,
      status: PhotoStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PhotoStatus.pending,
      ),
    );
  }

  @override
  String toString() {
    return 'Photo(id: $id, fileName: $fileName, url: $url, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Photo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
