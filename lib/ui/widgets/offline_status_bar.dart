import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sync_service.dart';
import '../../state/app_state_provider.dart';

class OfflineStatusBar extends StatelessWidget {
  const OfflineStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncService().syncStatusStream,
      initialData: const SyncStatus(
        isOnline: true,
        isSyncing: false,
        hasOfflineData: false,
      ),
      builder: (context, snapshot) {
        final syncStatus = snapshot.data ?? const SyncStatus(
          isOnline: true,
          isSyncing: false,
          hasOfflineData: false,
        );

        // 온라인이고 오프라인 데이터가 없으면 숨김
        if (syncStatus.isOnline && !syncStatus.hasOfflineData) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(syncStatus),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 상태 아이콘
              Icon(
                _getStatusIcon(syncStatus),
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              
              // 상태 메시지
              Expanded(
                child: Text(
                  _getStatusMessage(syncStatus),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // 동기화 버튼 (오프라인 데이터가 있고 온라인일 때)
              if (syncStatus.hasOfflineData && syncStatus.isOnline && !syncStatus.isSyncing)
                TextButton(
                  onPressed: () => SyncService().manualSync(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '동기화',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              // 동기화 중 인디케이터
              if (syncStatus.isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(SyncStatus status) {
    if (status.isSyncing) {
      return const Color(0xFF2196F3); // 파란색 (동기화 중)
    } else if (!status.isOnline) {
      return const Color(0xFFFF9800); // 주황색 (오프라인)
    } else if (status.hasOfflineData) {
      return const Color(0xFF4CAF50); // 초록색 (동기화 대기)
    } else {
      return const Color(0xFF81C784); // 기본 초록색
    }
  }

  IconData _getStatusIcon(SyncStatus status) {
    if (status.isSyncing) {
      return Icons.sync;
    } else if (!status.isOnline) {
      return Icons.cloud_off;
    } else if (status.hasOfflineData) {
      return Icons.cloud_queue;
    } else {
      return Icons.cloud_done;
    }
  }

  String _getStatusMessage(SyncStatus status) {
    if (status.isSyncing) {
      return '동기화 중...';
    } else if (!status.isOnline) {
      return '오프라인 작성 저장됨 · 연결 시 자동 업로드';
    } else if (status.hasOfflineData) {
      return '오프라인 작성 저장됨 · 자동 업로드';
    } else {
      return '동기화 완료';
    }
  }
}

// 앱 전체에 오프라인 상태바를 표시하는 래퍼
class OfflineStatusWrapper extends StatelessWidget {
  final Widget child;

  const OfflineStatusWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OfflineStatusBar(),
        Expanded(child: child),
      ],
    );
  }
}
