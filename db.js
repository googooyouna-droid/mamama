/**
 * 데이터베이스 관리 (localStorage 기반)
 */

class Database {
    constructor() {
        this.STORAGE_KEY_PREFIX = 'mind_diary_';
        this.STATE_KEY = this.STORAGE_KEY_PREFIX + 'app_state';
        this.checkLocalStorage();
    }

    // localStorage 사용 가능 여부 확인
    checkLocalStorage() {
        if (!isLocalStorageAvailable()) {
            console.error('localStorage를 사용할 수 없습니다.');
            showSnackbar('브라우저가 로컬 저장소를 지원하지 않습니다.', true);
        }
    }

    // 가족별 키 생성
    getFamilyKey(familyPin) {
        return this.STORAGE_KEY_PREFIX + 'family_' + familyPin;
    }

    // 앱 상태 저장
    saveAppState(appState) {
        try {
            localStorage.setItem(this.STATE_KEY, JSON.stringify(appState.toJSON()));
            return true;
        } catch (e) {
            console.error('앱 상태 저장 실패:', e);
            return false;
        }
    }

    // 앱 상태 불러오기
    loadAppState() {
        try {
            const data = localStorage.getItem(this.STATE_KEY);
            if (data) {
                return AppState.fromJSON(JSON.parse(data));
            }
        } catch (e) {
            console.error('앱 상태 로드 실패:', e);
        }
        return new AppState();
    }

    // 가족 데이터 전체 가져오기
    getFamilyData(familyPin) {
        try {
            const key = this.getFamilyKey(familyPin);
            const data = localStorage.getItem(key);
            if (data) {
                return JSON.parse(data);
            }
        } catch (e) {
            console.error('가족 데이터 로드 실패:', e);
        }
        return {};
    }

    // 가족 데이터 전체 저장
    saveFamilyData(familyPin, data) {
        try {
            const key = this.getFamilyKey(familyPin);
            localStorage.setItem(key, JSON.stringify(data));
            return true;
        } catch (e) {
            console.error('가족 데이터 저장 실패:', e);
            showSnackbar('저장 용량이 부족합니다. 오래된 사진을 삭제해주세요.', true);
            return false;
        }
    }

    // 일기 엔트리 저장
    saveDiaryEntry(familyPin, diaryEntry) {
        try {
            const familyData = this.getFamilyData(familyPin);
            if (!familyData.entries) {
                familyData.entries = {};
            }
            familyData.entries[diaryEntry.date] = diaryEntry.toJSON();
            return this.saveFamilyData(familyPin, familyData);
        } catch (e) {
            console.error('일기 저장 실패:', e);
            return false;
        }
    }

    // 일기 엔트리 불러오기
    loadDiaryEntry(familyPin, date) {
        try {
            const familyData = this.getFamilyData(familyPin);
            if (familyData.entries && familyData.entries[date]) {
                return DiaryEntry.fromJSON(familyData.entries[date]);
            }
        } catch (e) {
            console.error('일기 로드 실패:', e);
        }
        return new DiaryEntry({ date });
    }

    // 이번 달 일기 엔트리들 가져오기
    getThisMonthEntries(familyPin) {
        try {
            const now = new Date();
            const year = now.getFullYear();
            const month = now.getMonth() + 1;
            
            return this.getMonthEntries(familyPin, year, month);
        } catch (e) {
            console.error('이번 달 일기 로드 실패:', e);
            return {};
        }
    }

    // 특정 달의 일기 엔트리들 가져오기
    getMonthEntries(familyPin, year, month) {
        try {
            const familyData = this.getFamilyData(familyPin);
            if (!familyData.entries) {
                return {};
            }

            const monthStr = String(month).padLeft(2, '0');
            const prefix = `${year}-${monthStr}-`;
            
            const monthEntries = {};
            for (const [date, entryData] of Object.entries(familyData.entries)) {
                if (date.startsWith(prefix)) {
                    monthEntries[date] = DiaryEntry.fromJSON(entryData);
                }
            }
            
            return monthEntries;
        } catch (e) {
            console.error('월별 일기 로드 실패:', e);
            return {};
        }
    }

    // 모든 일기 엔트리 가져오기
    getAllEntries(familyPin) {
        try {
            const familyData = this.getFamilyData(familyPin);
            if (!familyData.entries) {
                return {};
            }

            const allEntries = {};
            for (const [date, entryData] of Object.entries(familyData.entries)) {
                allEntries[date] = DiaryEntry.fromJSON(entryData);
            }
            
            return allEntries;
        } catch (e) {
            console.error('전체 일기 로드 실패:', e);
            return {};
        }
    }

    // 일기 엔트리 삭제
    deleteDiaryEntry(familyPin, date) {
        try {
            const familyData = this.getFamilyData(familyPin);
            if (familyData.entries && familyData.entries[date]) {
                delete familyData.entries[date];
                return this.saveFamilyData(familyPin, familyData);
            }
            return true;
        } catch (e) {
            console.error('일기 삭제 실패:', e);
            return false;
        }
    }

    // 댓글 저장 (일기 엔트리 업데이트)
    saveComment(familyPin, date, comment) {
        try {
            const entry = this.loadDiaryEntry(familyPin, date);
            
            // 기존 댓글 찾기
            const existingComment = entry.findComment(comment.id);
            if (existingComment) {
                // 기존 댓글 업데이트
                Object.assign(existingComment, comment);
            } else {
                // 새 댓글 추가
                entry.addComment(comment);
            }
            
            entry.updatedAt = new Date();
            return this.saveDiaryEntry(familyPin, entry);
        } catch (e) {
            console.error('댓글 저장 실패:', e);
            return false;
        }
    }

    // 댓글 삭제
    deleteComment(familyPin, date, commentId) {
        try {
            const entry = this.loadDiaryEntry(familyPin, date);
            entry.removeComment(commentId);
            entry.updatedAt = new Date();
            return this.saveDiaryEntry(familyPin, entry);
        } catch (e) {
            console.error('댓글 삭제 실패:', e);
            return false;
        }
    }

    // 스티커 토글
    toggleSticker(familyPin, date, commentId, sticker) {
        try {
            const entry = this.loadDiaryEntry(familyPin, date);
            const comment = entry.findComment(commentId);
            if (comment) {
                comment.toggleSticker(sticker);
                return this.saveDiaryEntry(familyPin, entry);
            }
            return false;
        } catch (e) {
            console.error('스티커 토글 실패:', e);
            return false;
        }
    }

    // 데이터 내보내기 (백업)
    exportData(familyPin) {
        try {
            const familyData = this.getFamilyData(familyPin);
            const dataStr = JSON.stringify(familyData, null, 2);
            const blob = new Blob([dataStr], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = `mind_diary_backup_${formatDate(new Date())}.json`;
            a.click();
            
            URL.revokeObjectURL(url);
            showSnackbar('데이터를 내보냈습니다.');
            return true;
        } catch (e) {
            console.error('데이터 내보내기 실패:', e);
            showSnackbar('데이터 내보내기에 실패했습니다.', true);
            return false;
        }
    }

    // 데이터 가져오기 (복원)
    importData(familyPin, jsonData) {
        try {
            const data = JSON.parse(jsonData);
            if (this.saveFamilyData(familyPin, data)) {
                showSnackbar('데이터를 가져왔습니다.');
                return true;
            }
            return false;
        } catch (e) {
            console.error('데이터 가져오기 실패:', e);
            showSnackbar('데이터 가져오기에 실패했습니다. 파일 형식을 확인해주세요.', true);
            return false;
        }
    }

    // 전체 데이터 삭제 (초기화)
    clearAllData() {
        try {
            const keys = Object.keys(localStorage);
            keys.forEach(key => {
                if (key.startsWith(this.STORAGE_KEY_PREFIX)) {
                    localStorage.removeItem(key);
                }
            });
            showSnackbar('모든 데이터를 삭제했습니다.');
            return true;
        } catch (e) {
            console.error('데이터 삭제 실패:', e);
            showSnackbar('데이터 삭제에 실패했습니다.', true);
            return false;
        }
    }

    // 저장소 사용량 확인 (대략적)
    getStorageUsage() {
        try {
            let totalSize = 0;
            for (let key in localStorage) {
                if (localStorage.hasOwnProperty(key)) {
                    totalSize += localStorage[key].length + key.length;
                }
            }
            return formatFileSize(totalSize * 2); // UTF-16이므로 2배
        } catch (e) {
            return '알 수 없음';
        }
    }
}

// 전역 데이터베이스 인스턴스
const db = new Database();

