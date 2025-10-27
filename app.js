/**
 * 메인 애플리케이션 로직
 */

class MindDiaryApp {
    constructor() {
        try {
            console.log('MindDiaryApp 생성자 시작...');
            this.appState = db.loadAppState();
            this.currentScreen = 'home';
            this.currentDate = null;
            this.currentDiaryEntry = null;
            this.replyingTo = null; // 답글 작성 중인 댓글 ID
            
            console.log('앱 상태:', this.appState);
            this.init();
        } catch (error) {
            console.error('MindDiaryApp 생성자 오류:', error);
            // 기본 상태로 초기화
            this.appState = { isLoggedIn: false, familyPin: '', userRole: '' };
            this.currentScreen = 'home';
            this.currentDate = null;
            this.currentDiaryEntry = null;
            this.replyingTo = null;
            this.init();
        }
    }

    // 앱 초기화
    init() {
        try {
            console.log('앱 초기화 시작...');
            
            // 로딩 화면 숨기기
            setTimeout(() => {
                try {
                    console.log('로딩 화면 숨기기...');
                    document.getElementById('loading-screen').style.display = 'none';
                    document.getElementById('app').style.display = 'block';
                    
                    // 로그인 상태 확인
                    if (this.appState.isLoggedIn) {
                        console.log('로그인된 상태 - 달력 화면 표시');
                        this.showCalendarScreen();
                    } else {
                        console.log('로그인되지 않은 상태 - 홈 화면 표시');
                        this.showHomeScreen();
                    }
                } catch (error) {
                    console.error('로딩 화면 숨기기 오류:', error);
                    // 오류가 발생해도 강제로 로딩 화면 숨기기
                    document.getElementById('loading-screen').style.display = 'none';
                    document.getElementById('app').style.display = 'block';
                    this.showHomeScreen();
                }
            }, 1000);

            // 이벤트 리스너 등록
            this.registerEventListeners();
            console.log('앱 초기화 완료');
        } catch (error) {
            console.error('앱 초기화 오류:', error);
            // 오류가 발생해도 강제로 로딩 화면 숨기기
            setTimeout(() => {
                document.getElementById('loading-screen').style.display = 'none';
                document.getElementById('app').style.display = 'block';
                this.showHomeScreen();
            }, 1000);
        }
    }

    // 이벤트 리스너 등록
    registerEventListeners() {
        // 홈 화면 (로그인)
        document.getElementById('enter-btn').addEventListener('click', () => this.handleLogin());
        document.getElementById('pin-input').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.handleLogin();
        });
        
        // 역할 선택
        document.querySelectorAll('.role-card').forEach(card => {
            card.addEventListener('click', () => this.selectRole(card.dataset.role));
        });

        // 달력 화면
        document.getElementById('home-btn').addEventListener('click', () => this.handleLogout());
        document.getElementById('help-btn').addEventListener('click', () => this.showEmotionRulesModal());
        document.getElementById('refresh-btn').addEventListener('click', () => this.refreshCalendar());

        // 일기 화면
        document.getElementById('back-btn').addEventListener('click', () => this.showCalendarScreen());
        document.getElementById('save-btn').addEventListener('click', () => this.saveDiary());

        // 감정 선택
        document.querySelectorAll('.emotion-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.selectEmotion(e.target));
        });

        // 사진 추가
        document.getElementById('child-photo-btn').addEventListener('click', () => {
            document.getElementById('child-photo-input').click();
        });
        document.getElementById('parent-photo-btn').addEventListener('click', () => {
            document.getElementById('parent-photo-input').click();
        });
        document.getElementById('child-photo-input').addEventListener('change', (e) => {
            this.handlePhotoUpload(e, 'child');
        });
        document.getElementById('parent-photo-input').addEventListener('change', (e) => {
            this.handlePhotoUpload(e, 'parent');
        });

        // 댓글
        document.getElementById('comment-submit-btn').addEventListener('click', () => this.submitComment());
        document.getElementById('comment-input').addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && e.ctrlKey) this.submitComment();
        });

        // 모달 닫기
        document.getElementById('modal-close-btn').addEventListener('click', () => this.hideEmotionRulesModal());
        document.getElementById('emotion-rules-modal').addEventListener('click', (e) => {
            if (e.target.id === 'emotion-rules-modal') this.hideEmotionRulesModal();
        });
    }

    // ====== 화면 전환 ======

    showHomeScreen() {
        this.hideAllScreens();
        document.getElementById('home-screen').style.display = 'block';
        this.currentScreen = 'home';
    }

    showCalendarScreen() {
        this.hideAllScreens();
        document.getElementById('calendar-screen').style.display = 'block';
        this.currentScreen = 'calendar';
        this.updateUserGreeting();
        this.loadCalendar();
    }

    showDiaryScreen(date) {
        this.hideAllScreens();
        document.getElementById('diary-screen').style.display = 'block';
        this.currentScreen = 'diary';
        this.currentDate = date;
        this.loadDiary(date);
    }

    hideAllScreens() {
        document.querySelectorAll('.screen').forEach(screen => {
            screen.style.display = 'none';
        });
    }

    // ====== 로그인/로그아웃 ======

    handleLogin() {
        const pin = document.getElementById('pin-input').value.trim();
        const selectedRole = document.querySelector('.role-card.selected');

        if (!pin) {
            showSnackbar('가족 암호를 입력해주세요', true);
            return;
        }

        if (pin.length < 4) {
            showSnackbar('암호는 4자리 이상이어야 합니다', true);
            return;
        }

        if (!selectedRole) {
            showSnackbar('부모 또는 자녀를 선택해주세요', true);
            return;
        }

        const role = selectedRole.dataset.role;
        this.appState.login(pin, role);
        db.saveAppState(this.appState);

        showSnackbar('마음공간에 오신 것을 환영합니다! 🌱');
        setTimeout(() => {
            this.showCalendarScreen();
        }, 500);
    }

    handleLogout() {
        if (confirm('로그아웃 하시겠습니까?')) {
            this.appState.logout();
            db.saveAppState(this.appState);
            
            // 입력 초기화
            document.getElementById('pin-input').value = '';
            document.querySelectorAll('.role-card').forEach(card => {
                card.classList.remove('selected');
            });
            
            this.showHomeScreen();
            showSnackbar('로그아웃 되었습니다.');
        }
    }

    selectRole(role) {
        document.querySelectorAll('.role-card').forEach(card => {
            card.classList.remove('selected');
        });
        document.querySelector(`.role-card[data-role="${role}"]`).classList.add('selected');
    }

    // ====== 달력 화면 ======

    updateUserGreeting() {
        const greeting = `${this.appState.getRoleDisplayName()}님, 안녕하세요! ${this.appState.getRoleEmoji()}`;
        document.getElementById('user-greeting').textContent = greeting;
    }

    loadCalendar() {
        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth() + 1;
        
        // 월 제목 업데이트
        document.getElementById('month-title').textContent = formatMonthKorean(year, month);
        
        // 이번 달 일기 데이터 로드
        const entries = db.getMonthEntries(this.appState.familyPin, year, month);
        
        // 달력 그리드 생성
        this.renderCalendar(year, month, entries);
        
        // 감정 통계 표시
        this.renderEmotionStats(entries);
    }

    renderCalendar(year, month, entries) {
        const calendarGrid = document.getElementById('calendar-grid');
        calendarGrid.innerHTML = '';
        
        const firstDay = getFirstDayOfMonth(year, month);
        const lastDay = getLastDayOfMonth(year, month);
        const firstWeekday = firstDay.getDay(); // 0 (일요일) ~ 6 (토요일)
        const totalDays = lastDay.getDate();
        
        // 빈 칸 추가 (월 시작 전)
        for (let i = 0; i < firstWeekday; i++) {
            const emptyCell = document.createElement('div');
            calendarGrid.appendChild(emptyCell);
        }
        
        // 날짜 셀 추가
        for (let day = 1; day <= totalDays; day++) {
            const date = `${year}-${String(month).padLeft(2, '0')}-${String(day).padLeft(2, '0')}`;
            const entry = entries[date];
            const emotion = entry ? entry.calendarEmoji : '🌱';
            const hasContent = entry ? entry.hasContent() : false;
            
            const dayCell = this.createCalendarDayCell(day, date, emotion, hasContent);
            calendarGrid.appendChild(dayCell);
        }
    }

    createCalendarDayCell(day, date, emotion, hasContent) {
        const cell = document.createElement('div');
        cell.className = 'calendar-day';
        
        if (isToday(date)) {
            cell.classList.add('today');
        }
        if (hasContent) {
            cell.classList.add('has-content');
        }
        
        const dayNumber = document.createElement('div');
        dayNumber.className = 'day-number';
        dayNumber.textContent = day;
        
        const dayEmotion = document.createElement('div');
        dayEmotion.className = 'day-emotion';
        dayEmotion.textContent = emotion;
        
        cell.appendChild(dayNumber);
        cell.appendChild(dayEmotion);
        
        if (hasContent) {
            const dot = document.createElement('div');
            dot.className = 'day-dot';
            cell.appendChild(dot);
        }
        
        cell.addEventListener('click', () => this.showDiaryScreen(date));
        
        return cell;
    }

    renderEmotionStats(entries) {
        const statsContent = document.getElementById('emotion-stats-content');
        const emotionCounts = {};
        
        for (const entry of Object.values(entries)) {
            const emotion = entry.calendarEmoji;
            emotionCounts[emotion] = (emotionCounts[emotion] || 0) + 1;
        }
        
        if (Object.keys(emotionCounts).length === 0) {
            statsContent.innerHTML = '아직 작성된 일기가 없습니다.';
            statsContent.style.fontStyle = 'italic';
            statsContent.style.color = '#558B2F';
            return;
        }
        
        statsContent.innerHTML = '';
        statsContent.style.fontStyle = 'normal';
        statsContent.style.color = 'inherit';
        
        for (const [emotion, count] of Object.entries(emotionCounts)) {
            const item = document.createElement('div');
            item.className = 'stats-item';
            
            const emoji = document.createElement('span');
            emoji.className = 'stats-emoji';
            emoji.textContent = emotion;
            
            const countText = document.createElement('span');
            countText.className = 'stats-count';
            countText.textContent = `${count}일`;
            
            item.appendChild(emoji);
            item.appendChild(countText);
            statsContent.appendChild(item);
        }
    }

    refreshCalendar() {
        showSnackbar('달력을 새로고침합니다.');
        this.loadCalendar();
    }

    // ====== 일기 화면 ======

    loadDiary(date) {
        // 날짜 제목 업데이트
        document.getElementById('diary-date-title').textContent = formatDateKorean(date);
        
        // 일기 엔트리 로드
        this.currentDiaryEntry = db.loadDiaryEntry(this.appState.familyPin, date);
        
        // 권한에 따라 편집 가능 여부 설정
        this.setupDiaryPermissions();
        
        // 일기 내용 표시
        this.renderDiary();
        
        // 댓글 표시
        this.renderComments();
    }

    setupDiaryPermissions() {
        const isParent = this.appState.currentRole === 'parent';
        const isChild = this.appState.currentRole === 'child';
        
        // 자녀 일기 영역
        const childTextarea = document.getElementById('child-diary-text');
        const childPhotoBtn = document.getElementById('child-photo-btn');
        const childEmotionBtns = document.querySelectorAll('#child-emotion-selector .emotion-btn');
        
        if (isChild) {
            childTextarea.disabled = false;
            childPhotoBtn.disabled = false;
            childEmotionBtns.forEach(btn => btn.disabled = false);
        } else {
            childTextarea.disabled = true;
            childPhotoBtn.disabled = true;
            childEmotionBtns.forEach(btn => btn.disabled = true);
        }
        
        // 부모 일기 영역
        const parentTextarea = document.getElementById('parent-diary-text');
        const parentPhotoBtn = document.getElementById('parent-photo-btn');
        const parentEmotionBtns = document.querySelectorAll('#parent-emotion-selector .emotion-btn');
        
        if (isParent) {
            parentTextarea.disabled = false;
            parentPhotoBtn.disabled = false;
            parentEmotionBtns.forEach(btn => btn.disabled = false);
        } else {
            parentTextarea.disabled = true;
            parentPhotoBtn.disabled = true;
            parentEmotionBtns.forEach(btn => btn.disabled = true);
        }
    }

    renderDiary() {
        // 자녀 일기
        document.getElementById('child-diary-text').value = this.currentDiaryEntry.child.text;
        this.updateEmotionSelector('child', this.currentDiaryEntry.child.emotion);
        this.renderPhotos('child', this.currentDiaryEntry.child.photos);
        
        // 부모 일기
        document.getElementById('parent-diary-text').value = this.currentDiaryEntry.parent.text;
        this.updateEmotionSelector('parent', this.currentDiaryEntry.parent.emotion);
        this.renderPhotos('parent', this.currentDiaryEntry.parent.photos);
    }

    updateEmotionSelector(section, emotion) {
        const selector = document.getElementById(`${section}-emotion-selector`);
        selector.querySelectorAll('.emotion-btn').forEach(btn => {
            btn.classList.remove('selected');
            if (btn.dataset.emotion === emotion) {
                btn.classList.add('selected');
            }
        });
    }

    renderPhotos(section, photos) {
        const photoGrid = document.getElementById(`${section}-photos`);
        photoGrid.innerHTML = '';
        
        photos.forEach(photo => {
            const photoItem = this.createPhotoItem(photo, section);
            photoGrid.appendChild(photoItem);
        });
    }

    createPhotoItem(photo, section) {
        const item = document.createElement('div');
        item.className = 'photo-item';
        
        const img = document.createElement('img');
        img.src = photo.url;
        img.alt = photo.fileName;
        
        // 내 영역인 경우에만 삭제 버튼 표시
        const canDelete = (section === 'child' && this.appState.currentRole === 'child') ||
                         (section === 'parent' && this.appState.currentRole === 'parent');
        
        if (canDelete) {
            const removeBtn = document.createElement('button');
            removeBtn.className = 'photo-remove-btn';
            removeBtn.textContent = '✕';
            removeBtn.onclick = () => this.removePhoto(section, photo.id);
            item.appendChild(removeBtn);
        }
        
        item.appendChild(img);
        return item;
    }

    selectEmotion(btn) {
        if (btn.disabled) return;
        
        const selector = btn.closest('.emotion-selector');
        selector.querySelectorAll('.emotion-btn').forEach(b => {
            b.classList.remove('selected');
        });
        btn.classList.add('selected');
    }

    async handlePhotoUpload(event, section) {
        const files = Array.from(event.target.files);
        if (files.length === 0) return;
        
        // 최대 5장 제한
        const currentPhotos = this.currentDiaryEntry[section].photos;
        if (currentPhotos.length + files.length > 5) {
            showSnackbar('사진은 최대 5장까지 첨부할 수 있습니다.', true);
            return;
        }
        
        showSnackbar('사진을 업로드 중입니다...');
        
        try {
            for (const file of files) {
                // 파일 크기 제한 (5MB)
                if (file.size > 5 * 1024 * 1024) {
                    showSnackbar(`${file.name}은(는) 너무 큽니다. (최대 5MB)`, true);
                    continue;
                }
                
                // 이미지 리사이즈
                const resizedFile = await resizeImage(file);
                const base64 = await imageToBase64(resizedFile);
                
                const photo = new Photo({
                    url: base64,
                    fileName: file.name,
                    fileSize: resizedFile.size
                });
                
                currentPhotos.push(photo);
            }
            
            this.renderPhotos(section, currentPhotos);
            showSnackbar('사진이 추가되었습니다.');
        } catch (error) {
            console.error('사진 업로드 실패:', error);
            showSnackbar('사진 업로드에 실패했습니다.', true);
        }
        
        // 파일 입력 초기화
        event.target.value = '';
    }

    removePhoto(section, photoId) {
        if (!confirm('사진을 삭제하시겠습니까?')) return;
        
        const photos = this.currentDiaryEntry[section].photos;
        const index = photos.findIndex(p => p.id === photoId);
        if (index > -1) {
            photos.splice(index, 1);
            this.renderPhotos(section, photos);
            showSnackbar('사진이 삭제되었습니다.');
        }
    }

    saveDiary() {
        // 현재 역할에 해당하는 영역만 업데이트
        const section = this.appState.currentRole === 'parent' ? 'parent' : 'child';
        
        // 텍스트 업데이트
        const textarea = document.getElementById(`${section}-diary-text`);
        this.currentDiaryEntry[section].text = filterProfanity(textarea.value);
        
        // 감정 업데이트
        const selectedEmotionBtn = document.querySelector(`#${section}-emotion-selector .emotion-btn.selected`);
        this.currentDiaryEntry[section].emotion = selectedEmotionBtn ? selectedEmotionBtn.dataset.emotion : '';
        
        // 마지막 수정 시간 업데이트
        this.currentDiaryEntry[section].lastModified = new Date();
        
        // 달력 이모지 업데이트
        this.currentDiaryEntry.updateCalendarEmoji();
        
        // 저장
        if (db.saveDiaryEntry(this.appState.familyPin, this.currentDiaryEntry)) {
            showSnackbar('일기가 저장되었습니다. 💾');
        } else {
            showSnackbar('일기 저장에 실패했습니다.', true);
        }
    }

    // ====== 댓글 ======

    renderComments() {
        const commentsList = document.getElementById('comments-list');
        commentsList.innerHTML = '';
        
        if (this.currentDiaryEntry.comments.length === 0) {
            commentsList.innerHTML = '<div style="text-align: center; color: #757575; padding: 20px;">아직 댓글이 없습니다.</div>';
            return;
        }
        
        // 최상위 댓글만 먼저 렌더링
        const topLevelComments = this.currentDiaryEntry.getTopLevelComments();
        topLevelComments.forEach(comment => {
            const commentElement = this.createCommentElement(comment);
            commentsList.appendChild(commentElement);
            
            // 답글들 렌더링
            const replies = this.currentDiaryEntry.getReplies(comment.id);
            replies.forEach(reply => {
                const replyElement = this.createCommentElement(reply, true);
                commentsList.appendChild(replyElement);
            });
        });
    }

    createCommentElement(comment, isReply = false) {
        const item = document.createElement('div');
        item.className = 'comment-item' + (isReply ? ' reply' : '');
        
        // 헤더
        const header = document.createElement('div');
        header.className = 'comment-header';
        
        const author = document.createElement('div');
        author.className = 'comment-author';
        author.innerHTML = `${comment.getAuthorEmoji()} ${comment.getAuthorDisplayName()} <span class="comment-target">→ ${comment.getTargetDisplayName()}</span>`;
        
        const date = document.createElement('div');
        date.className = 'comment-date';
        date.textContent = formatRelativeTime(comment.createdAt);
        
        header.appendChild(author);
        header.appendChild(date);
        
        // 댓글 내용
        const text = document.createElement('div');
        text.className = 'comment-text';
        text.textContent = comment.text;
        
        // 액션 (스티커, 답글)
        const actions = document.createElement('div');
        actions.className = 'comment-actions';
        
        // 감정 스티커
        const stickers = ['❤️', '👍', '🌸', '😊', '🎉'];
        stickers.forEach(sticker => {
            const stickerBtn = document.createElement('button');
            stickerBtn.className = 'sticker-btn';
            stickerBtn.textContent = sticker;
            if (comment.stickers.includes(sticker)) {
                stickerBtn.classList.add('active');
            }
            stickerBtn.onclick = () => this.toggleCommentSticker(comment.id, sticker);
            actions.appendChild(stickerBtn);
        });
        
        // 답글 버튼 (최상위 댓글에만)
        if (!isReply) {
            const replyBtn = document.createElement('button');
            replyBtn.className = 'reply-btn';
            replyBtn.textContent = '답글';
            replyBtn.onclick = () => this.startReply(comment.id);
            actions.appendChild(replyBtn);
        }
        
        item.appendChild(header);
        item.appendChild(text);
        item.appendChild(actions);
        
        return item;
    }

    submitComment() {
        const textarea = document.getElementById('comment-input');
        const text = textarea.value.trim();
        
        if (!text) {
            showSnackbar('댓글 내용을 입력해주세요.', true);
            return;
        }
        
        const target = document.getElementById('comment-target').value;
        
        const comment = new Comment({
            target: target,
            authorRole: this.appState.currentRole,
            parentId: this.replyingTo,
            text: filterProfanity(text)
        });
        
        this.currentDiaryEntry.addComment(comment);
        
        if (db.saveDiaryEntry(this.appState.familyPin, this.currentDiaryEntry)) {
            textarea.value = '';
            this.replyingTo = null;
            this.renderComments();
            showSnackbar('댓글이 작성되었습니다.');
        } else {
            showSnackbar('댓글 작성에 실패했습니다.', true);
        }
    }

    startReply(commentId) {
        this.replyingTo = commentId;
        const comment = this.currentDiaryEntry.findComment(commentId);
        document.getElementById('comment-input').placeholder = `${comment.getAuthorDisplayName()}님에게 답글...`;
        document.getElementById('comment-input').focus();
        showSnackbar(`${comment.getAuthorDisplayName()}님에게 답글을 작성합니다.`);
    }

    toggleCommentSticker(commentId, sticker) {
        if (db.toggleSticker(this.appState.familyPin, this.currentDate, commentId, sticker)) {
            this.currentDiaryEntry = db.loadDiaryEntry(this.appState.familyPin, this.currentDate);
            this.renderComments();
        } else {
            showSnackbar('스티커 반응에 실패했습니다.', true);
        }
    }

    // ====== 모달 ======

    showEmotionRulesModal() {
        document.getElementById('emotion-rules-modal').classList.add('show');
    }

    hideEmotionRulesModal() {
        document.getElementById('emotion-rules-modal').classList.remove('show');
    }
}

// 앱 시작
let app;
document.addEventListener('DOMContentLoaded', () => {
    try {
        console.log('DOM 로드 완료 - 앱 시작...');
        app = new MindDiaryApp();
        console.log('앱 시작 완료');
    } catch (error) {
        console.error('앱 시작 오류:', error);
        // 오류가 발생해도 강제로 로딩 화면 숨기기
        setTimeout(() => {
            const loadingScreen = document.getElementById('loading-screen');
            const appContainer = document.getElementById('app');
            if (loadingScreen) loadingScreen.style.display = 'none';
            if (appContainer) appContainer.style.display = 'block';
        }, 1000);
    }
});

