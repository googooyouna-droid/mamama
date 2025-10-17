/**
 * 데이터 모델 클래스들
 */

// 사진 모델
class Photo {
    constructor(data = {}) {
        this.id = data.id || generateId();
        this.url = data.url || ''; // base64 데이터
        this.fileName = data.fileName || '';
        this.fileSize = data.fileSize || 0;
        this.uploadedAt = data.uploadedAt ? new Date(data.uploadedAt) : new Date();
    }

    toJSON() {
        return {
            id: this.id,
            url: this.url,
            fileName: this.fileName,
            fileSize: this.fileSize,
            uploadedAt: this.uploadedAt.toISOString()
        };
    }

    getFormattedFileSize() {
        return formatFileSize(this.fileSize);
    }

    static fromJSON(json) {
        return new Photo(json);
    }
}

// 일기 섹션 모델 (자녀/부모)
class DiarySection {
    constructor(data = {}) {
        this.text = data.text || '';
        this.emotion = data.emotion || '';
        this.photos = (data.photos || []).map(p => p instanceof Photo ? p : new Photo(p));
        this.lastModified = data.lastModified ? new Date(data.lastModified) : null;
    }

    toJSON() {
        return {
            text: this.text,
            emotion: this.emotion,
            photos: this.photos.map(p => p.toJSON()),
            lastModified: this.lastModified ? this.lastModified.toISOString() : null
        };
    }

    isEmpty() {
        return !this.text && this.photos.length === 0;
    }

    hasContent() {
        return this.text.length > 0 || this.photos.length > 0;
    }

    static fromJSON(json) {
        return new DiarySection(json);
    }
}

// 댓글 모델
class Comment {
    constructor(data = {}) {
        this.id = data.id || generateId();
        this.target = data.target || 'child'; // 'child' or 'parent'
        this.authorRole = data.authorRole || 'parent'; // 'parent' or 'child'
        this.parentId = data.parentId || null; // 대댓글인 경우 부모 댓글 ID
        this.text = data.text || '';
        this.createdAt = data.createdAt ? new Date(data.createdAt) : new Date();
        this.updatedAt = data.updatedAt ? new Date(data.updatedAt) : new Date();
        this.stickers = data.stickers || []; // 감정 스티커들
    }

    toJSON() {
        return {
            id: this.id,
            target: this.target,
            authorRole: this.authorRole,
            parentId: this.parentId,
            text: this.text,
            createdAt: this.createdAt.toISOString(),
            updatedAt: this.updatedAt.toISOString(),
            stickers: this.stickers
        };
    }

    isReply() {
        return this.parentId !== null;
    }

    getAuthorDisplayName() {
        return this.authorRole === 'parent' ? '부모' : '자녀';
    }

    getAuthorEmoji() {
        return this.authorRole === 'parent' ? '👨‍👩‍👧‍👦' : '👶';
    }

    getTargetDisplayName() {
        return this.target === 'parent' ? '부모' : '자녀';
    }

    hasStickers() {
        return this.stickers.length > 0;
    }

    addSticker(sticker) {
        if (!this.stickers.includes(sticker)) {
            this.stickers.push(sticker);
            this.updatedAt = new Date();
        }
    }

    removeSticker(sticker) {
        const index = this.stickers.indexOf(sticker);
        if (index > -1) {
            this.stickers.splice(index, 1);
            this.updatedAt = new Date();
        }
    }

    toggleSticker(sticker) {
        if (this.stickers.includes(sticker)) {
            this.removeSticker(sticker);
        } else {
            this.addSticker(sticker);
        }
    }

    static fromJSON(json) {
        return new Comment(json);
    }
}

// 일기 엔트리 모델
class DiaryEntry {
    constructor(data = {}) {
        this.date = data.date || getToday();
        this.child = data.child instanceof DiarySection ? data.child : new DiarySection(data.child);
        this.parent = data.parent instanceof DiarySection ? data.parent : new DiarySection(data.parent);
        this.calendarEmoji = data.calendarEmoji || '🌱';
        this.comments = (data.comments || []).map(c => c instanceof Comment ? c : new Comment(c));
        this.createdAt = data.createdAt ? new Date(data.createdAt) : new Date();
        this.updatedAt = data.updatedAt ? new Date(data.updatedAt) : new Date();
    }

    toJSON() {
        return {
            date: this.date,
            child: this.child.toJSON(),
            parent: this.parent.toJSON(),
            calendarEmoji: this.calendarEmoji,
            comments: this.comments.map(c => c.toJSON()),
            createdAt: this.createdAt.toISOString(),
            updatedAt: this.updatedAt.toISOString()
        };
    }

    // 감정 이모티콘 결정
    getDisplayEmoji() {
        return getDisplayEmoji(this.child.emotion, this.parent.emotion);
    }

    // 달력용 이모지 업데이트
    updateCalendarEmoji() {
        this.calendarEmoji = this.getDisplayEmoji();
        this.updatedAt = new Date();
    }

    isEmpty() {
        return this.child.isEmpty() && this.parent.isEmpty() && this.comments.length === 0;
    }

    hasContent() {
        return this.child.hasContent() || this.parent.hasContent() || this.comments.length > 0;
    }

    // 댓글 추가
    addComment(comment) {
        this.comments.push(comment);
        this.updatedAt = new Date();
    }

    // 댓글 삭제
    removeComment(commentId) {
        const index = this.comments.findIndex(c => c.id === commentId);
        if (index > -1) {
            this.comments.splice(index, 1);
            this.updatedAt = new Date();
        }
    }

    // 댓글 찾기
    findComment(commentId) {
        return this.comments.find(c => c.id === commentId);
    }

    // 특정 댓글의 답글들 찾기
    getReplies(commentId) {
        return this.comments.filter(c => c.parentId === commentId);
    }

    // 최상위 댓글들만 가져오기
    getTopLevelComments() {
        return this.comments.filter(c => !c.isReply());
    }

    static fromJSON(json) {
        return new DiaryEntry(json);
    }
}

// 앱 상태 모델
class AppState {
    constructor(data = {}) {
        this.familyPin = data.familyPin || '';
        this.currentRole = data.currentRole || ''; // 'parent' or 'child'
        this.isLoggedIn = data.isLoggedIn || false;
    }

    toJSON() {
        return {
            familyPin: this.familyPin,
            currentRole: this.currentRole,
            isLoggedIn: this.isLoggedIn
        };
    }

    getRoleDisplayName() {
        return this.currentRole === 'parent' ? '부모' : '자녀';
    }

    getRoleEmoji() {
        return this.currentRole === 'parent' ? '👨‍👩‍👧‍👦' : '👶';
    }

    login(familyPin, role) {
        this.familyPin = familyPin;
        this.currentRole = role;
        this.isLoggedIn = true;
    }

    logout() {
        this.familyPin = '';
        this.currentRole = '';
        this.isLoggedIn = false;
    }

    static fromJSON(json) {
        return new AppState(json);
    }
}

