import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../state/app_state_provider.dart';
import '../../models/diary_entry.dart';
import '../../services/firebase_service.dart';

class PhotoAttachment extends StatefulWidget {
  final String date;
  final String section; // 'child' or 'parent'
  final bool canEdit;

  const PhotoAttachment({
    super.key,
    required this.date,
    required this.section,
    required this.canEdit,
  });

  @override
  State<PhotoAttachment> createState() => _PhotoAttachmentState();
}

class _PhotoAttachmentState extends State<PhotoAttachment> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Photo> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              const Icon(
                Icons.attach_file,
                size: 16,
                color: Color(0xFF558B2F),
              ),
              const SizedBox(width: 8),
              Text(
                '첨부 사진 (${_photos.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF558B2F),
                ),
              ),
              const Spacer(),
              if (widget.canEdit)
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate, size: 20),
                  onPressed: _pickAndUploadImage,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 사진 목록
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF81C784),
                ),
              ),
            )
          else if (_photos.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  '첨부된 사진이 없습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return _buildPhotoItem(photo);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(Photo photo) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // 썸네일
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildThumbnail(photo),
            ),
          ),
          
          // 상태 표시 및 재시도 버튼
          Positioned(
            top: 4,
            right: 4,
            child: photo.status == PhotoStatus.failed
                ? _buildRetryButton(photo)
                : _buildStatusIndicator(photo),
          ),
          
          // 삭제 버튼 (수정 가능한 경우)
          if (widget.canEdit)
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => _deletePhoto(photo),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(Photo photo) {
    if (photo.status == PhotoStatus.uploading || photo.status == PhotoStatus.pending) {
      return Container(
        color: Colors.grey.withOpacity(0.2),
        child: const Center(
          child: Icon(
            Icons.image,
            color: Colors.grey,
            size: 32,
          ),
        ),
      );
    }
    
    // 실제 이미지 로드 (웹에서는 네트워크 이미지)
    return Image.network(
      photo.url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 32,
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.withOpacity(0.2),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF81C784),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(Photo photo) {
    Widget icon;
    Color backgroundColor;
    
    switch (photo.status) {
      case PhotoStatus.pending:
        icon = const Text('⌛', style: TextStyle(fontSize: 12));
        backgroundColor = Colors.orange;
        break;
      case PhotoStatus.uploading:
        icon = const Text('🔄', style: TextStyle(fontSize: 12));
        backgroundColor = Colors.blue;
        break;
      case PhotoStatus.uploaded:
        icon = const Text('✅', style: TextStyle(fontSize: 12));
        backgroundColor = Colors.green;
        break;
      case PhotoStatus.failed:
        icon = const Text('⚠', style: TextStyle(fontSize: 12));
        backgroundColor = Colors.red;
        break;
    }
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Center(child: icon),
    );
  }

  // 재시도 버튼
  Widget _buildRetryButton(Photo photo) {
    return GestureDetector(
      onTap: () => _retryUpload(photo),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: const Icon(
          Icons.refresh,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }

  // 이미지 선택 및 업로드
  Future<void> _pickAndUploadImage() async {
    try {
      // file_picker를 사용한 파일 선택
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileBytes = file.bytes;
        final fileName = file.name;
        
        if (fileBytes != null) {
          // 새 사진 객체 생성
          final photo = Photo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            fileName: fileName,
            url: '', // 업로드 후 설정
            uploadedAt: null,
            status: PhotoStatus.pending,
          );
          
          // UI에 즉시 추가
          setState(() {
            _photos.add(photo);
          });
          
          // 업로드 시작
          _uploadPhoto(photo, fileBytes);
        } else {
          _showSnackBar('파일을 읽을 수 없습니다', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('이미지 선택에 실패했습니다: $e', isError: true);
    }
  }


  // 사진 업로드 (온라인/오프라인 처리)
  Future<void> _uploadPhoto(Photo photo, Uint8List fileBytes) async {
    try {
      // 상태를 업로드 중으로 변경
      setState(() {
        photo.status = PhotoStatus.uploading;
      });
      
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      
      // 네트워크 상태 확인
      if (await _isOnline()) {
        // 온라인: Firebase에 직접 업로드
        await _uploadToFirebase(photo, fileBytes);
      } else {
        // 오프라인: 로컬에 저장
        await _saveOfflinePhoto(photo, fileBytes);
      }
    } catch (e) {
      // 상태를 실패로 변경
      setState(() {
        photo.status = PhotoStatus.failed;
      });
      
      _showSnackBar('사진 업로드에 실패했습니다: $e', isError: true);
    }
  }

  // Firebase에 직접 업로드
  Future<void> _uploadToFirebase(Photo photo, Uint8List fileBytes) async {
    try {
      // Firebase Storage에 업로드
      final uploadedPhoto = await _firebaseService.uploadPhoto(
        widget.date,
        fileBytes,
        photo.fileName,
      );
      
      // Firestore에 URL 저장
      await _savePhotoToFirestore(uploadedPhoto);
      
      // 상태를 완료로 변경
      setState(() {
        photo.status = PhotoStatus.uploaded;
        photo.url = uploadedPhoto.url;
        photo.uploadedAt = uploadedPhoto.uploadedAt;
      });
      
      _showSnackBar('사진이 업로드되었습니다');
    } catch (e) {
      throw Exception('Firebase 업로드 실패: $e');
    }
  }

  // 오프라인 사진 저장
  Future<void> _saveOfflinePhoto(Photo photo, Uint8List fileBytes) async {
    try {
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      
      // 오프라인 저장
      await appStateProvider.saveOfflinePhoto(
        widget.date,
        widget.section,
        photo,
        fileBytes,
      );
      
      // 상태를 대기 중으로 변경 (오프라인 상태)
      setState(() {
        photo.status = PhotoStatus.pending;
      });
      
      _showSnackBar('오프라인에 저장되었습니다. 연결 시 자동 업로드됩니다.');
    } catch (e) {
      throw Exception('오프라인 저장 실패: $e');
    }
  }

  // 네트워크 상태 확인
  Future<bool> _isOnline() async {
    // SyncService를 통해 온라인 상태 확인
    return SyncService().isOnline;
  }

  // Firestore에 사진 정보 저장
  Future<void> _savePhotoToFirestore(Photo photo) async {
    try {
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      await appStateProvider.firebaseService.addPhotoToEntry(
        widget.date,
        widget.section,
        photo,
      );
    } catch (e) {
      throw Exception('사진 정보 저장에 실패했습니다: $e');
    }
  }

  // 사진 삭제
  Future<void> _deletePhoto(Photo photo) async {
    try {
      // Firestore에서 삭제
      await _firebaseService.deletePhotoFromEntry(widget.date, photo.id);
      
      // Storage에서 삭제
      if (photo.url.isNotEmpty) {
        await _firebaseService.deletePhoto(photo.url);
      }
      
      // UI에서 제거
      setState(() {
        _photos.removeWhere((p) => p.id == photo.id);
      });
      
      _showSnackBar('사진이 삭제되었습니다');
    } catch (e) {
      _showSnackBar('사진 삭제에 실패했습니다: $e', isError: true);
    }
  }

  // 업로드 재시도
  Future<void> _retryUpload(Photo photo) async {
    try {
      // 새로운 파일 선택
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileBytes = file.bytes;
        
        if (fileBytes != null) {
          // 사진 정보 업데이트
          final updatedPhoto = photo.copyWith(
            fileName: file.name,
            status: PhotoStatus.pending,
          );
          
          // UI 업데이트
          setState(() {
            final index = _photos.indexWhere((p) => p.id == photo.id);
            if (index != -1) {
              _photos[index] = updatedPhoto;
            }
          });
          
          // 업로드 시작
          _uploadPhoto(updatedPhoto, fileBytes);
        }
      }
    } catch (e) {
      _showSnackBar('재시도에 실패했습니다: $e', isError: true);
    }
  }

  // 사진 목록 로드
  Future<void> _loadPhotos() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final entry = await _firebaseService.getEntry(widget.date);
      final sectionPhotos = entry?.getSection(widget.section).photos ?? [];
      
      setState(() {
        _photos = sectionPhotos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('사진을 불러오는데 실패했습니다: $e', isError: true);
    }
  }

  // 스낵바 표시
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? const Color(0xFFE57373) 
            : const Color(0xFF81C784),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}
