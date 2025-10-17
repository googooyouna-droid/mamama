import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state_provider.dart';
import '../../models/comment.dart';
import '../../services/firebase_service.dart';

class CommentSection extends StatefulWidget {
  final String date;
  final String targetSection; // 'child' or 'parent'

  const CommentSection({
    super.key,
    required this.date,
    required this.targetSection,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 댓글 헤더
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Color(0xFF558B2F),
              ),
              const SizedBox(width: 8),
              Text(
                '댓글 (${_comments.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF558B2F),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 댓글 목록
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
          else if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '아직 댓글이 없습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._buildCommentList(),
          
          const SizedBox(height: 12),
          
          // 댓글 입력
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              final canComment = _canComment(appState.state.role);
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      enabled: canComment,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: canComment 
                            ? (_replyingToCommentId != null 
                                ? '답글을 입력하세요...'
                                : '댓글을 입력하세요...')
                            : '로그인이 필요합니다',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: canComment ? Colors.white : Colors.grey.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: canComment ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: canComment && _commentController.text.trim().isNotEmpty
                        ? _addComment
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81C784),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '등록',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // 답글 취소 버튼
          if (_replyingToCommentId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    '답글 작성 중...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _cancelReply,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 댓글 목록 빌드
  List<Widget> _buildCommentList() {
    return _comments.map((comment) => _buildCommentItem(comment)).toList();
  }

  // 개별 댓글 아이템 빌드
  Widget _buildCommentItem(Comment comment) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isMyComment = comment.authorRole == appState.state.role;
    final canReply = comment.depth < 3; // 3단까지만 답글 가능

    return Container(
      margin: EdgeInsets.only(
        left: comment.depth > 1 ? 20.0 : 0,
        bottom: 8,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 댓글 헤더
          Row(
            children: [
              Text(
                comment.authorEmoji,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                comment.authorDisplayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(comment.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              
              // 스티커 버튼
              if (!isMyComment)
                IconButton(
                  icon: const Icon(Icons.favorite_border, size: 16),
                  onPressed: () => _addSticker(comment),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              
              // 답글 버튼
              if (canReply && !isMyComment)
                IconButton(
                  icon: const Icon(Icons.reply, size: 16),
                  onPressed: () => _startReply(comment.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              
              // 수정/삭제 버튼
              if (isMyComment)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editComment(comment);
                    } else if (value == 'delete') {
                      _deleteComment(comment.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('수정', style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // 댓글 내용
          Text(
            comment.text,
            style: const TextStyle(fontSize: 12),
          ),
          
          // 스티커 표시
          if (comment.stickers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                children: comment.stickers.map((sticker) => Text(
                  sticker,
                  style: const TextStyle(fontSize: 12),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // 댓글 추가
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final role = appState.state.role;
      
      if (role == null) {
        _showSnackBar('로그인이 필요합니다', isError: true);
        return;
      }

      final comment = Comment.create(
        target: widget.targetSection,
        authorRole: role,
        parentId: _replyingToCommentId,
        text: _commentController.text.trim(),
      );

      await _firebaseService.addComment(widget.date, comment);
      _commentController.clear();
      _replyingToCommentId = null;
      _loadComments();
      
      _showSnackBar('댓글이 등록되었습니다');
    } catch (e) {
      _showSnackBar('댓글 등록에 실패했습니다: $e', isError: true);
    }
  }

  // 답글 시작
  void _startReply(String parentId) {
    setState(() {
      _replyingToCommentId = parentId;
    });
    _commentController.clear();
  }

  // 답글 취소
  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
    });
    _commentController.clear();
  }

  // 댓글 수정
  void _editComment(Comment comment) {
    _commentController.text = comment.text;
    // TODO: 수정 모드 구현
    _showSnackBar('댓글 수정 기능 준비 중입니다');
  }

  // 댓글 삭제
  Future<void> _deleteComment(String commentId) async {
    try {
      await _firebaseService.deleteComment(widget.date, commentId);
      _loadComments();
      _showSnackBar('댓글이 삭제되었습니다');
    } catch (e) {
      _showSnackBar('댓글 삭제에 실패했습니다: $e', isError: true);
    }
  }

  // 스티커 추가
  Future<void> _addSticker(Comment comment) async {
    try {
      final stickers = ['❤️', '👍', '🌸', '😊', '🎉'];
      
      // 간단한 스티커 선택 다이얼로그
      final selectedSticker = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('감정 스티커'),
          content: Wrap(
            spacing: 16,
            children: stickers.map((sticker) => GestureDetector(
              onTap: () => Navigator.of(context).pop(sticker),
              child: Text(
                sticker,
                style: const TextStyle(fontSize: 32),
              ),
            )).toList(),
          ),
        ),
      );

      if (selectedSticker != null) {
        final updatedComment = comment.addSticker(selectedSticker);
        await _firebaseService.updateComment(widget.date, comment.id, updatedComment);
        _loadComments();
        _showSnackBar('스티커가 추가되었습니다');
      }
    } catch (e) {
      _showSnackBar('스티커 추가에 실패했습니다: $e', isError: true);
    }
  }

  // 댓글 목록 로드
  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final entry = await _firebaseService.getEntry(widget.date);
      final comments = entry?.comments ?? [];
      
      // 현재 섹션에 해당하는 댓글만 필터링
      final filteredComments = comments
          .where((comment) => comment.target == widget.targetSection)
          .toList();

      setState(() {
        _comments = filteredComments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('댓글을 불러오는데 실패했습니다: $e', isError: true);
    }
  }

  // 댓글 권한 확인
  bool _canComment(String? role) {
    return role != null && (role == 'child' || role == 'parent');
  }

  // 날짜 시간 포맷
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}/${dateTime.day}';
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
