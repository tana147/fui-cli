// Thay thế toàn bộ file SCRIPT
function initPage() {
    console.log('[LOG 1 - SCRIPT] initPage() bắt đầu. AssignToClassID =', vueData.assignToClassId);
    const assignId = parseInt(vueData.assignToClassId);
    if (assignId && assignId > 0) {
        console.log('[LOG 2 - SCRIPT] ID hợp lệ, đang thực hiện CALL("getLessonData")...');
        CALL('getLessonData');
    } else {
        console.log('[LOG 2b - SCRIPT] ID không hợp lệ. Hiển thị giao diện lỗi.');
        vueData.lesson = null;
        vueData.dataReady = true;
    }
    console.log('[LOG 3 - SCRIPT] initPage() kết thúc.');
}
function processInitialData(apiResponse) {
    console.log('[LOG B - SCRIPT] processInitialData() được gọi với dữ liệu thô:', apiResponse);
    if (apiResponse && Array.isArray(apiResponse) && apiResponse.length >= 2 && apiResponse[0] && apiResponse[0][0]) {
        // Dữ liệu hợp lệ, tiếp tục xử lý
        let lessonHeader = apiResponse[0][0];
        console.log('[LOG C - SCRIPT] Đã bóc tách được lessonHeader:', lessonHeader);
        const elementsRaw = apiResponse[1];
        let statusCompletion = apiResponse[2]?.[0] || {}
        console.log('statusCompletion', statusCompletion)
        lessonHeader.elements = (elementsRaw || []).map(el => {
            try {
                el.ElementData = typeof el.ElementData === 'string' ? JSON.parse(el.ElementData) : (el.ElementData || {});
            } catch (e) {
                el.ElementData = {};
            }
            el.IsRequired = el.IsRequired === undefined || el.IsRequired === null
                ? 1
                : ([true, 1, '1'].includes(el.IsRequired) ? 1 : 0);
            el.RequiredDurationSeconds = Number(el.RequiredDurationSeconds) > 0
                ? Number(el.RequiredDurationSeconds)
                : null;
            el.ElementTimeSpentSeconds = Number(el.ElementTimeSpentSeconds) || 0;
            el.ElementProgressStatus = el.ElementProgressStatus || 'NOT_STARTED';
            return el;
        });
        console.log('[LOG D - SCRIPT] Đã xử lý xong. Dữ liệu lesson sạch:', lessonHeader);
        lessonHeader = { ...lessonHeader, ...statusCompletion }
        // Bài cũ không có policy trong DB nên tiếp tục dùng timer tổng hiện tại.
        lessonHeader.CompletionPolicy = lessonHeader.CompletionPolicy === 'ALL_REQUIRED' ? 'ALL_REQUIRED' : 'LEGACY_DURATION';
        lessonHeader.RequireSequential = [true, 1, '1'].includes(lessonHeader.RequireSequential) ? 1 : 0;
        vueData.lesson = lessonHeader;
    } else {
        console.error('[LOG D-ERROR - SCRIPT] Dữ liệu API không hợp lệ hoặc rỗng. Kiểm tra lại điều kiện IF.');
        vueData.lesson = null;
    }
    console.log('[LOG E - SCRIPT] Chuẩn bị bật dataReady=true và tăng dataVersion...');
    vueData.dataReady = true;
    vueData.dataVersion++;
    console.log(`[LOG F - SCRIPT] Đã cập nhật: dataReady=${vueData.dataReady}, dataVersion=${vueData.dataVersion}. Giao diện SẼ được render/re-render.`);
}
async function updateProgress(payload) {
    if (!vueData.lesson) return;
    if (payload?.elementID) {
        const dataToSend = {
            AssignToClassID: Number(vueData.assignToClassId),
            LessonID: vueData.lesson.ProgressLessonID || vueData.lesson.LessonID,
            ElementID: payload.elementID,
            TimeSpentSeconds: payload.timeSpent,
            ClientEventID: payload.clientEventID,
            HocSinhID: vueData.HocSinhID
        };
        const elementResponse = await fetch(vueData.v_Set.apiDomain + 'lms/EL_Student_UpdateElementProgress', {
            method: 'POST',
            headers: {
                "Authorization": $awt,
                "Content-type": "application/json;charset=UTF-8"
            },
            body: JSON.stringify(dataToSend)
        });
        const elementResult = await elementResponse.json().catch(() => null);
        if (!elementResponse.ok) {
            throw new Error(elementResult?.Message || elementResult?.message || `EL_Student_UpdateElementProgress HTTP ${elementResponse.status}`);
        }
        return elementResult;
    }
    if(!vueData.HocSinhID){
        Vue.$toast.error('Không tìm thấy HocSinhID! EL_Student_UpdateProgress',{position: 'top'})
        return;
    }
    const dataToSend = {
        HocSinhID: vueData.HocSinhID,
        // Nội dung có thể là bản riêng của lớp, nhưng tiến độ vẫn gắn với bài gốc như trước.
        LessonID: vueData.lesson.ProgressLessonID || vueData.lesson.LessonID,
        IsCompleted: payload.isCompleted,
        TimeSpentSeconds: payload.timeSpent,
    };
    console.log('dataSend', dataToSend)
    console.log('call api....')
    const response = await fetch(vueData.v_Set.apiDomain + "lms/EL_Student_UpdateProgress",
        {
            method: 'POST',
            headers: {
                "Authorization": $awt,
                "Content-type": "application/json;charset=UTF-8"
            },
            body: JSON.stringify(dataToSend)
        }
    );
    const result = await response.json().catch(() => null);
    if (!response.ok) throw new Error(result?.Message || result?.message || `EL_Student_UpdateProgress HTTP ${response.status}`);
    return result;
}
vueData.initPage = initPage;
vueData.processInitialData = processInitialData;
vueData.updateProgress = updateProgress;