import 'package:flutter/material.dart';

class EmotionRulesDemo extends StatelessWidget {
  const EmotionRulesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF81C784).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '감정 규칙 안내',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          
          // 규칙 1: 같은 감정
          _buildRuleItem(
            title: '같은 감정',
            description: '부모와 자녀가 같은 감정을 선택한 경우',
            example: '부모: 😊, 자녀: 😊 → 달력: 😊',
            colors: [Colors.green.shade100, Colors.green.shade50],
          ),
          
          const SizedBox(height: 8),
          
          // 규칙 2: 다른 감정
          _buildRuleItem(
            title: '다른 감정',
            description: '부모와 자녀가 다른 감정을 선택한 경우',
            example: '부모: 😊, 자녀: 😢 → 달력: 😐',
            colors: [Colors.orange.shade100, Colors.orange.shade50],
          ),
          
          const SizedBox(height: 8),
          
          // 규칙 3: 한쪽만 선택
          _buildRuleItem(
            title: '한쪽만 선택',
            description: '부모 또는 자녀 중 한쪽만 감정을 선택한 경우',
            example: '부모: (없음), 자녀: 😊 → 달력: 😊',
            colors: [Colors.blue.shade100, Colors.blue.shade50],
          ),
          
          const SizedBox(height: 8),
          
          // 규칙 4: 둘 다 없음
          _buildRuleItem(
            title: '둘 다 없음',
            description: '부모와 자녀 모두 감정을 선택하지 않은 경우',
            example: '부모: (없음), 자녀: (없음) → 달력: 🌱',
            colors: [Colors.grey.shade100, Colors.grey.shade50],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required String title,
    required String description,
    required String example,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.first.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF558B2F),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              example,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
