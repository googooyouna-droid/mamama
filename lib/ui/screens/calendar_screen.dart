import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/app_state_provider.dart';
import '../../models/diary_entry.dart';
import '../widgets/emotion_rules_demo.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  Map<String, DiaryEntry> _diaries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThisMonthDiaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getMonthTitle()),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showEmotionRules,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadThisMonthDiaries,
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 현재 사용자 정보 표시
                Consumer<AppStateProvider>(
                  builder: (context, appState, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            _getMonthTitle(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${appState.state.roleDisplayName}님, 안녕하세요! ${appState.state.roleEmoji}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF558B2F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // 달력 그리드
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF81C784),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // 요일 헤더
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _WeekdayHeader('일'),
                                  _WeekdayHeader('월'),
                                  _WeekdayHeader('화'),
                                  _WeekdayHeader('수'),
                                  _WeekdayHeader('목'),
                                  _WeekdayHeader('금'),
                                  _WeekdayHeader('토'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // 달력 날짜들
                              Expanded(
                                child: _buildCalendarGrid(),
                              ),
                            ],
                          ),
                        ),
                ),
                
                const SizedBox(height: 20),
                
                // 통계 정보 표시
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '이번 달 감정 통계',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEmotionStats(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 이번 달 일기 데이터 로드
  Future<void> _loadThisMonthDiaries() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      final diaries = await appStateProvider.firebaseService.getThisMonthEntries();

      setState(() {
        _diaries = diaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일기 데이터를 불러오는데 실패했습니다: $e'),
            backgroundColor: const Color(0xFFE57373),
          ),
        );
      }
    }
  }

  // 월 제목 생성
  String _getMonthTitle() {
    return '${_currentMonth.year}년 ${_currentMonth.month}월';
  }

  // 달력 그리드 빌드
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 일요일이 0이 되도록 조정
    
    // 달력에 필요한 총 셀 수 계산
    final totalDays = lastDayOfMonth.day;
    final totalCells = firstWeekday + totalDays;
    final weeks = (totalCells / 7).ceil();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: weeks * 7,
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;
        
        // 이번 달이 아닌 날짜는 빈 칸
        if (day < 1 || day > totalDays) {
          return const SizedBox();
        }

        final date = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final diary = _diaries[date];
        final emotion = diary?.calendarEmoji ?? '🌱';

        return _CalendarDay(
          day: day,
          emotion: emotion,
          hasContent: diary?.hasContent ?? false,
          onTap: () => context.go('/diary/$date'),
        );
      },
    );
  }

  // 감정 통계 빌드
  Widget _buildEmotionStats() {
    final emotionCounts = <String, int>{};
    
    for (final diary in _diaries.values) {
      final emotion = diary.calendarEmoji;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }

    if (emotionCounts.isEmpty) {
      return const Text(
        '아직 작성된 일기가 없습니다.',
        style: TextStyle(
          color: Color(0xFF558B2F),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: emotionCounts.entries.map((entry) {
        final emotion = entry.key;
        final count = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF81C784).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emotion,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                '$count일',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF558B2F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 감정 규칙 안내 표시
  void _showEmotionRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감정 표시 규칙'),
        content: const SingleChildScrollView(
          child: EmotionRulesDemo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String day;
  
  const _WeekdayHeader(this.day);

  @override
  Widget build(BuildContext context) {
    return Text(
      day,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF558B2F),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final int day;
  final String emotion;
  final bool hasContent;
  final VoidCallback onTap;

  const _CalendarDay({
    required this.day,
    required this.emotion,
    required this.hasContent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = today.day == day && 
                   today.month == DateTime.now().month && 
                   today.year == DateTime.now().year;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday 
              ? const Color(0xFF81C784).withOpacity(0.3)
              : hasContent 
                  ? const Color(0xFFE8F5E8)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday 
                ? const Color(0xFF81C784)
                : hasContent
                    ? const Color(0xFF81C784).withOpacity(0.5)
                    : const Color(0xFFE0E0E0),
            width: isToday ? 2 : 1,
          ),
          boxShadow: hasContent ? [
            BoxShadow(
              color: const Color(0xFF81C784).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isToday 
                    ? const Color(0xFF2E7D32)
                    : hasContent
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              emotion,
              style: TextStyle(
                fontSize: hasContent ? 14 : 12,
                color: hasContent 
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF999999),
              ),
            ),
            if (hasContent)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF81C784),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
