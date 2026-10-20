const DEFAULT_COMPLETION_DURATION_MINUTES = 3;
function normalizeCompletionDuration(value) {
    const minutes = Number.parseInt(value, 10);
    return Number.isFinite(minutes) && minutes >= 1 ? minutes : DEFAULT_COMPLETION_DURATION_MINUTES;
}
function getApiData(response) {
    return Array.isArray(response?.data) ? response.data : response;
}
function getFirstApiRow(response) {
    const data = getApiData(response);
    const first = Array.isArray(data) ? data[0] : null;
    return Array.isArray(first) ? first[0] : first;
}
function getApiErrorMessage(response) {
    return response?.Message || response?.message || response?.error?.Message || response?.error?.message;
}
function normalizeElementCompletion(element) {
    const requiredValue = element?.IsRequired;
    element.IsRequired = requiredValue === undefined || requiredValue === null
        ? 1
        : ([true, 1, '1'].includes(requiredValue) ? 1 : 0);
    element.CompletionMode = element.CompletionMode || 'TIME_REQUIRED';
    const expected = Number.parseInt(element.ExpectedDurationSeconds, 10);
    const required = Number.parseInt(element.RequiredDurationSeconds, 10);
    element.ExpectedDurationSeconds = Number.isFinite(expected) && expected >= 0 ? expected : null;
    element.RequiredDurationSeconds = Number.isFinite(required) && required >= 1 ? required : null;
    element.ElementProgressStatus = element.ElementProgressStatus || 'NOT_STARTED';
    element.ElementTimeSpentSeconds = Number(element.ElementTimeSpentSeconds) || 0;
    return element;
}
function serializeElementData(value) {
    if (typeof value === 'string') {
        try {
            JSON.parse(value);
            return value;
        } catch (error) {
            // Chuỗi không phải JSON sẽ được bọc lại để backend vẫn nhận được ElementData hợp lệ.
        }
    }
    return JSON.stringify(value || {});
}
function processInitialData(data) {
    if (data && data.length >= 2) {
        const lessonData = data[0][0];
        // Quyền SUBJECT chỉ cho xem; SP trả CanEdit để không mở nhầm thao tác sửa/giao bài.
        const canEditValue = lessonData?.CanEdit;
        vueData.canEdit = canEditValue === undefined || canEditValue === null
            ? true
            : [true, 1, '1'].includes(canEditValue);
        // Bài cũ chưa có thời lượng cấu hình sẽ hiển thị và lưu lại theo mặc định 3 phút.
        lessonData.EstimatedDuration = normalizeCompletionDuration(lessonData.EstimatedDuration);
        // Null/missing policy là dữ liệu lesson cũ; luôn mở theo timer tổng để giữ nguyên tiến độ hiện có.
        lessonData.CompletionPolicy = lessonData.CompletionPolicy === 'ALL_REQUIRED' ? 'ALL_REQUIRED' : 'LEGACY_DURATION';
        lessonData.RequireSequential = [true, 1, '1'].includes(lessonData.RequireSequential) ? 1 : 0;
        const elementsData = data[1];
        lessonData.elements = (elementsData || []).map(el => {
            try {
                el.ElementData = typeof el.ElementData === 'string' ? JSON.parse(el.ElementData) : (el.ElementData || {});
            } catch (e) {
                el.ElementData = {};
            }
            return normalizeElementCompletion(el);
        });
        vueData.lesson = lessonData;
        console.log('vueData.lesson', vueData.lesson)
    } else {
        Vue.$toast.error("Tải dữ liệu bài giảng thất bại.", { position: 'top' });
    }
    console.log('process...')
    vueData.dataReady = true;
}
function initPage() {
    const LessonID = vueData.LessonID;
    if (LessonID && LessonID > 0) {
        vueData.isEditMode = true;
        CALL('getLessonData')
    } else {
        vueData.isEditMode = false;
        vueData.canEdit = true;
        vueData.lesson = {
            Title: '', Description: '', Tuan: '', Chuong: '',
            EstimatedDuration: DEFAULT_COMPLETION_DURATION_MINUTES,
            CompletionPolicy: 'LEGACY_DURATION',
            RequireSequential: 0,
            Status: 1,
            elements: []
        };
        vueData.dataReady = true;
    }
}
async function saveLesson(payload) {
    const dataToSend = { ...payload.lesson };
    dataToSend.Status = payload.isPublishing ? 2 : 1;
    // API lưu theo phút; luôn gửi giá trị hợp lệ để ngưỡng hoàn thành không rơi về 0.
    dataToSend.EstimatedDuration = normalizeCompletionDuration(dataToSend.EstimatedDuration);
    // Bắt buộc chờ lưu phần header trước để lấy LessonID hợp lệ cho toàn bộ element.
    const response = await fetchPromise("lms/EL_Lesson_Save_V2", {
        LessonID: Number(dataToSend.LessonID) || 0,
        TuanHocID: dataToSend.TuanHocID,
        Chuong: dataToSend.Chuong,
        Title: dataToSend.Title,
        Description: dataToSend.Description,
        KhoiID: dataToSend.KhoiID,
        MonHocID: dataToSend.MonHocID,
        NienKhoa: dataToSend.NienKhoa,
        HocKi: dataToSend.HocKi || 1,
        EstimatedDuration: dataToSend.EstimatedDuration,
        ThumbnailURL: dataToSend.ThumbnailURL,
        Status: dataToSend.Status,
        IsPublic: dataToSend.IsPublic ? 1 : 0,
        CompletionPolicy: dataToSend.CompletionPolicy === 'ALL_REQUIRED' ? 'ALL_REQUIRED' : 'LEGACY_DURATION',
        RequireSequential: [true, 1, '1'].includes(dataToSend.RequireSequential) ? 1 : 0,
    }, { cache: false });
    const lessonRow = getFirstApiRow(response);
    const responseError = getApiErrorMessage(response);
    const newLessonID = Number(lessonRow?.LessonID || dataToSend.LessonID || 0);
    if (!newLessonID) {
        throw new Error(responseError || 'Lưu thông tin bài học thất bại.');
    }
    if (!vueData.isEditMode) {
        window.history.pushState({}, '', `?LessonID=${newLessonID}`);
        vueData.isEditMode = true;
    }
    vueData.LessonID = newLessonID;
    vueData.lesson = { ...(vueData.lesson || {}), LessonID: newLessonID };
    // Stored procedure nhận Json_Elements là NVARCHAR và tự OPENJSON chuỗi này.
    // Stringify cả mảng để không bị chuyển thành [object Object] ở lớp request.
    const elements = Array.isArray(dataToSend.elements) ? dataToSend.elements : [];
    const Json_Elements = JSON.stringify(elements.map(x => ({
        ...x,
        LessonID: newLessonID,
        IsRequired: [true, 1, '1'].includes(x.IsRequired) ? 1 : 0,
        CompletionMode: x.CompletionMode || 'TIME_REQUIRED',
        ExpectedDurationSeconds: x.ExpectedDurationSeconds ?? null,
        RequiredDurationSeconds: x.RequiredDurationSeconds ?? null,
        ElementData: serializeElementData(x.ElementData)
    })));
    const elementsResponse = await fetchPromise('lms/EL_Element_Save_Multiple_V2', {
        LessonID: newLessonID,
        Json_Elements
    }, { cache: false });
    const elementsError = getApiErrorMessage(elementsResponse);
    if (elementsError && !Array.isArray(getApiData(elementsResponse))) {
        throw new Error(elementsError);
    }
    Vue.$toast.success('Lưu bài học thành công!', { position: 'top' });
    CALL('getLessonData'); // Tải lại dữ liệu mới nhất sau khi cả header và element đã lưu xong.
    return { LessonID: newLessonID, response: elementsResponse };
}
vueData.initPage = initPage;
vueData.processInitialData = processInitialData;
vueData.saveLesson = saveLesson;