// Xem trước dùng snapshot do trang soạn bài truyền qua openWindow; không đọc/ghi API.
function getPreviewSnapshot(value) {
    let source = value;
    if (typeof source === 'string') {
        try {
            source = JSON.parse(source);
        } catch (error) {
            return null;
        }
    }
    if (!source || typeof source !== 'object' || Array.isArray(source)) return null;
    try {
        const lesson = JSON.parse(JSON.stringify(source));
        lesson.elements = (Array.isArray(lesson.elements) ? lesson.elements : []).map(element => {
            let elementData = element?.ElementData;
            if (typeof elementData === 'string') {
                try {
                    elementData = JSON.parse(elementData);
                } catch (error) {
                    // Nội dung text cũ chưa được lưu dạng JSON vẫn cần hiển thị trong canvas xem trước.
                    elementData = element?.ElementType === 'TEXT'
                        ? { content: elementData }
                        : { source: elementData };
                }
            }
            return { ...element, ElementData: elementData && typeof elementData === 'object' ? elementData : {} };
        });
        return lesson;
    } catch (error) {
        return null;
    }
}
function initPreviewLesson() {
    // Lấy snapshot theo token URL vì lớp cửa sổ hiện tại không chuyển thuộc tính data khi mở iframe.
    const token = String(vueData.previewToken || '').trim();
    let rawSnapshot = null;
    if (token) {
        const storageKey = `fui-lesson-preview:${token}`;
        try {
            rawSnapshot = window.sessionStorage.getItem(storageKey);
            // Snapshot chỉ dùng cho lần mở này; xóa ngay để không giữ nội dung bài trong phiên lâu hơn cần thiết.
            window.sessionStorage.removeItem(storageKey);
        } catch (error) {
            rawSnapshot = null;
        }
    }
    // Bản xem trước chỉ đọc snapshot, không chạy action API hoặc ghi tiến độ học.
    vueData.lesson = getPreviewSnapshot(rawSnapshot);
    vueData.dataReady = true;
}
vueData.initPreviewLesson = initPreviewLesson;