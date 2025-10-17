import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/app_state_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  String? _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD), // 연한 하늘색
              Color(0xFFF3E5F5), // 연한 보라색
              Color(0xFFE8F5E8), // 연한 초록색
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // 상단 로고 영역
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 로고 아이콘
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Text(
                          '🌱',
                          style: TextStyle(fontSize: 60),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 앱 이름
                      const Text(
                        '마음일기장',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // 부제목
                      const Text(
                        '정서 교류형 부모·자녀 일기 앱',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF558B2F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 중앙 PIN 입력 영역
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 350),
                        child: Column(
                          children: [
                            // PIN 입력창
                            Container(
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
                              child: TextField(
                                controller: _pinController,
                                decoration: const InputDecoration(
                                  labelText: '가족 암호를 입력하세요 🔒',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(16)),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                                obscureText: true,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // 마음공간으로 들어가기 버튼
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _handleEnterMindSpace,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF81C784),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  '마음공간으로 들어가기',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 하단 역할 선택 영역
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '누구로 들어가시나요?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 부모/자녀 선택 카드
                      Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              title: '부모',
                              icon: Icons.person,
                              subtitle: '엄마/아빠',
                              isSelected: _selectedRole == 'parent',
                              onTap: () => _selectRole('parent'),
                              backgroundColor: const Color(0xFFFFF3E0),
                              borderColor: const Color(0xFFFF9800),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _RoleCard(
                              title: '자녀',
                              icon: Icons.child_care,
                              subtitle: '아이',
                              isSelected: _selectedRole == 'child',
                              onTap: () => _selectRole('child'),
                              backgroundColor: const Color(0xFFE3F2FD),
                              borderColor: const Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 랜덤 문구
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF81C784).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '오늘의 마음을 씨앗처럼 심어볼까요?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF558B2F),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
    
    // 애니메이션 실행
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // 햅틱 피드백
    // HapticFeedback.lightImpact();
  }

  void _handleEnterMindSpace() {
    final pin = _pinController.text.trim();
    
    if (pin.isEmpty) {
      _showSnackBar('가족 암호를 입력해주세요', isError: true);
      return;
    }
    
    if (pin.length < 4) {
      _showSnackBar('암호는 4자리 이상이어야 합니다', isError: true);
      return;
    }
    
    if (_selectedRole == null) {
      _showSnackBar('부모 또는 자녀를 선택해주세요', isError: true);
      return;
    }
    
    // PIN과 역할 저장 (실제로는 SharedPreferences나 상태관리 사용)
    _saveFamilyPinAndRole(pin, _selectedRole!);
    
    // 성공 메시지
    _showSnackBar('마음공간에 오신 것을 환영합니다! 🌱');
    
    // 달력으로 이동
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.go('/calendar');
      }
    });
  }

  void _saveFamilyPinAndRole(String pin, String role) async {
    // Provider를 통해 Firebase 로그인 및 상태 저장
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    await appStateProvider.login(pin, role);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? const Color(0xFFE57373) 
          : const Color(0xFF81C784),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(isSelected ? 0.9 : 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? borderColor : borderColor.withOpacity(0.3),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                  ? borderColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
                blurRadius: isSelected ? 15 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isSelected ? 50 : 40,
                color: isSelected ? borderColor : borderColor.withOpacity(0.7),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSelected ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? borderColor : borderColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? borderColor : borderColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
