/**
 * 유틸리티 함수들
 */

// 날짜 포맷팅 (YYYY-MM-DD)
function formatDate(date) {
    if (typeof date === 'string') {
        return date;
    }
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padLeft(2, '0');
    const day = String(date.getDate()).padLeft(2, '0');
    return `${year}-${month}-${day}`;
}

// 날짜 문자열을 Date 객체로 변환
function parseDate(dateString) {
    const [year, month, day] = dateString.split('-').map(Number);
    return new Date(year, month - 1, day);
}

// 날짜를 한글 형식으로 표시 (2025년 10월 17일)
function formatDateKorean(dateString) {
    const date = parseDate(dateString);
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${year}년 ${month}월 ${day}일`;
}

// 월/년 한글 형식 (2025년 10월)
function formatMonthKorean(year, month) {
    return `${year}년 ${month}월`;
}

// 시간 포맷팅 (HH:MM)
function formatTime(date) {
    const hours = String(date.getHours()).padLeft(2, '0');
    const minutes = String(date.getMinutes()).padLeft(2, '0');
    return `${hours}:${minutes}`;
}

// 날짜+시간 포맷팅 (MM/DD HH:MM)
function formatDateTime(date) {
    const month = String(date.getMonth() + 1).padLeft(2, '0');
    const day = String(date.getDate()).padLeft(2, '0');
    const hours = String(date.getHours()).padLeft(2, '0');
    const minutes = String(date.getMinutes()).padLeft(2, '0');
    return `${month}/${day} ${hours}:${minutes}`;
}

// 상대 시간 표시 (방금 전, 5분 전, 2시간 전, 어제, 7일 전)
function formatRelativeTime(date) {
    const now = new Date();
    const diff = now - date;
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (seconds < 60) return '방금 전';
    if (minutes < 60) return `${minutes}분 전`;
    if (hours < 24) return `${hours}시간 전`;
    if (days === 1) return '어제';
    if (days < 7) return `${days}일 전`;
    return formatDateTime(date);
}

// 문자열 왼쪽 패딩
String.prototype.padLeft = function(length, char) {
    let str = this;
    while (str.length < length) {
        str = char + str;
    }
    return str;
};

// 고유 ID 생성
function generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2, 9);
}

// 스낵바 표시
function showSnackbar(message, isError = false) {
    const snackbar = document.getElementById('snackbar');
    snackbar.textContent = message;
    snackbar.className = 'snackbar show' + (isError ? ' error' : '');
    
    setTimeout(() => {
        snackbar.classList.remove('show');
    }, 3000);
}

// 욕설 필터링 (간단한 버전)
function filterProfanity(text) {
    const profanityList = [
        '욕설1', '욕설2', '비속어', '나쁜말'
        // 실제 사용시 더 많은 단어 추가
    ];
    
    let filteredText = text;
    profanityList.forEach(word => {
        const regex = new RegExp(word, 'gi');
        filteredText = filteredText.replace(regex, '*'.repeat(word.length));
    });
    
    return filteredText;
}

// 이미지를 base64로 변환
function imageToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = reject;
        reader.readAsDataURL(file);
    });
}

// 이미지 리사이즈 (최대 크기 제한)
function resizeImage(file, maxWidth = 1200, maxHeight = 1200) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = (e) => {
            const img = new Image();
            img.onload = () => {
                let width = img.width;
                let height = img.height;

                // 비율 유지하면서 리사이즈
                if (width > height) {
                    if (width > maxWidth) {
                        height = height * (maxWidth / width);
                        width = maxWidth;
                    }
                } else {
                    if (height > maxHeight) {
                        width = width * (maxHeight / height);
                        height = maxHeight;
                    }
                }

                const canvas = document.createElement('canvas');
                canvas.width = width;
                canvas.height = height;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0, width, height);

                canvas.toBlob((blob) => {
                    resolve(new File([blob], file.name, {
                        type: 'image/jpeg',
                        lastModified: Date.now()
                    }));
                }, 'image/jpeg', 0.8);
            };
            img.onerror = reject;
            img.src = e.target.result;
        };
        reader.onerror = reject;
        reader.readAsDataURL(file);
    });
}

// 파일 크기를 읽기 쉬운 형태로 변환
function formatFileSize(bytes) {
    if (bytes < 1024) return bytes + 'B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + 'KB';
    return (bytes / (1024 * 1024)).toFixed(1) + 'MB';
}

// 현재 달의 첫날
function getFirstDayOfMonth(year, month) {
    return new Date(year, month - 1, 1);
}

// 현재 달의 마지막날
function getLastDayOfMonth(year, month) {
    return new Date(year, month, 0);
}

// 감정 이모지 결정 로직
function getDisplayEmoji(childEmotion, parentEmotion) {
    if (childEmotion && parentEmotion) {
        if (childEmotion === parentEmotion) {
            return childEmotion; // 같은 감정
        } else {
            return '😐'; // 다른 감정
        }
    } else if (childEmotion) {
        return childEmotion; // 자녀만 선택
    } else if (parentEmotion) {
        return parentEmotion; // 부모만 선택
    } else {
        return '🌱'; // 기본값
    }
}

// HTML 이스케이프 (XSS 방지)
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// 디바운스 함수
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// 로컬스토리지 사용 가능 여부 확인
function isLocalStorageAvailable() {
    try {
        const test = '__localStorage_test__';
        localStorage.setItem(test, test);
        localStorage.removeItem(test);
        return true;
    } catch (e) {
        return false;
    }
}

// 깊은 복사
function deepClone(obj) {
    return JSON.parse(JSON.stringify(obj));
}

// 오늘 날짜 가져오기 (YYYY-MM-DD 형식)
function getToday() {
    return formatDate(new Date());
}

// 오늘이 해당 날짜인지 확인
function isToday(dateString) {
    return dateString === getToday();
}

