import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/app_state_provider.dart';
import '../../models/diary_entry.dart';
import '../../models/comment.dart';

class DiaryScreen extends StatefulWidget {
  final String date;

  const DiaryScreen({
    super.key,
    required this.date,
  });

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late TextEditingController _childTextController;
  late TextEditingController _parentTextController;
  String _childEmotion = '';
  String _parentEmotion = '';
  bool _isLoading = false;
  bool _isSaving = false;
  DiaryEntry? _currentEntry;

  final List<String> _emotions = ['😊', '😢', '😡', '😴', '😍', '😐'];

  @override
  void initState() {
    super.initState();
    _childTextController = TextEditingController();
    _parentTextController = TextEditingController();
    _loadDiaryEntry();
  }

  @override
  void dispose() {
    _childTextController.dispose();
    _parentTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(widget.date)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/calendar'),
        ),
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, appState, child) {
              final canEdit = _canEditCurrentSection(appState.state.role);
              return IconButton(
                icon: _isSaving 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                onPressed: canEdit && !_isSaving ? _saveDiary : null,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E8), // 연한 초록색
              Color(0xFFF3E5F5), // 연한 보라색
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF81C784),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 현재 사용자 정보 표시
                      Consumer<AppStateProvider>(
                        builder: (context, appState, child) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  appState.state.roleEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${appState.state.roleDisplayName}님의 일기',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                      Text(
                                        _canEditCurrentSection(appState.state.role)
                                            ? '수정 가능'
                                            : '읽기 전용',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _canEditCurrentSection(appState.state.role)
                                              ? const Color(0xFF558B2F)
                                              : const Color(0xFF999999),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 일기 작성 영역 (2프레임 구조)
                      Expanded(
                        child: Column(
                          children: [
                            // 자녀 영역 (상단)
                            Expanded(
                              child: _DiaryFrame(
                                title: '자녀의 마음',
                                backgroundColor: const Color(0xFFE3F2FD),
                                borderColor: const Color(0xFF2196F3),
                                icon: Icons.child_care,
                                textController: _childTextController,
                                emotion: _childEmotion,
                                onEmotionChanged: (emotion) => setState(() => _childEmotion = emotion),
                                canEdit: _canEditSection('child'),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 부모 영역 (하단)
                            Expanded(
                              child: _DiaryFrame(
                                title: '부모의 마음',
                                backgroundColor: const Color(0xFFFFF3E0),
                                borderColor: const Color(0xFFFF9800),
                                icon: Icons.person,
                                textController: _parentTextController,
                                emotion: _parentEmotion,
                                onEmotionChanged: (emotion) => setState(() => _parentEmotion = emotion),
                                canEdit: _canEditSection('parent'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 저장 버튼
                      Consumer<AppStateProvider>(
                        builder: (context, appState, child) {
                          final canEdit = _canEditCurrentSection(appState.state.role);
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: canEdit && !_isSaving ? _saveDiary : null,
                              icon: _isSaving 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_isSaving ? '저장 중...' : '일기 저장'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF81C784),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // 일기 엔트리 로드
  Future<void> _loadDiaryEntry() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      final entry = await appStateProvider.firebaseService.getEntry(widget.date);

      setState(() {
        _currentEntry = entry;
        if (entry != null) {
          _childTextController.text = entry.child.text;
          _parentTextController.text = entry.parent.text;
          _childEmotion = entry.child.emotion;
          _parentEmotion = entry.parent.emotion;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일기를 불러오는데 실패했습니다: $e'),
            backgroundColor: const Color(0xFFE57373),
          ),
        );
      }
    }
  }

  // 특정 섹션 수정 가능 여부
  bool _canEditSection(String section) {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    return appStateProvider.state.role == section;
  }

  // 현재 사용자의 섹션 수정 가능 여부
  bool _canEditCurrentSection(String? role) {
    return role != null && (role == 'child' || role == 'parent');
  }

  // 일기 저장
  Future<void> _saveDiary() async {
    try {
      setState(() {
        _isSaving = true;
      });

      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      final role = appStateProvider.state.role;

      if (role == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 현재 사용자의 섹션만 업데이트
      String? emotion;
      String? text;
      
      if (role == 'child') {
        emotion = _childEmotion;
        text = _childTextController.text;
      } else if (role == 'parent') {
        emotion = _parentEmotion;
        text = _parentTextController.text;
      }

      if (emotion != null && text != null) {
        final sectionData = DiarySection(
          text: text,
          emotion: emotion,
          lastModified: DateTime.now(),
        );

        await appStateProvider.firebaseService.updateEntrySection(
          widget.date,
          role,
          sectionData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('일기가 저장되었습니다! 💚'),
              backgroundColor: Color(0xFF81C784),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장에 실패했습니다: $e'),
            backgroundColor: const Color(0xFFE57373),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _formatDate(String date) {
    // 2025-01-16 -> 2025년 1월 16일
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[0]}년 ${int.parse(parts[1])}월 ${int.parse(parts[2])}일';
    }
    return date;
  }
}

class _DiaryFrame extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final TextEditingController textController;
  final String emotion;
  final Function(String) onEmotionChanged;
  final bool canEdit;

  const _DiaryFrame({
    required this.title,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.textController,
    required this.emotion,
    required this.onEmotionChanged,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> emotions = ['😊', '😢', '😡', '😴', '😍', '😐'];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withOpacity(canEdit ? 0.5 : 0.2), 
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(
                icon,
                color: borderColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
              const Spacer(),
              if (!canEdit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '읽기 전용',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 감정 선택
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  '감정: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: emotions.map((emot) => GestureDetector(
                      onTap: canEdit ? () => onEmotionChanged(emot) : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: emotion == emot 
                              ? borderColor.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: emotion == emot 
                              ? Border.all(color: borderColor, width: 2)
                              : null,
                        ),
                        child: Text(
                          emot,
                          style: TextStyle(
                            fontSize: 20,
                            color: canEdit 
                                ? (emotion == emot ? borderColor : Colors.black54)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 텍스트 입력 영역
          Expanded(
            child: TextField(
              controller: textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              enabled: canEdit,
              decoration: InputDecoration(
                hintText: canEdit 
                    ? '오늘의 마음을 적어보세요...'
                    : '아직 작성되지 않았습니다.',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: canEdit ? Colors.white : Colors.grey.withOpacity(0.1),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: TextStyle(
                color: canEdit ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
