function tkbHandleChatBotHieuResp(userText, resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    vueData.dangHieu = false;
    vueData.inputText = '';
    vueData.chatLog.push({ role: 'user', text: userText });
    vueData.chatLog.push({ role: 'bot', text: row.TomTat || 'Không hiểu được, bạn thử diễn đạt lại giúp', loai: row.Loai });
    vueData.ketQuaHieu = row;
    vueData.dsAnhHuong = [];
    vueData.daXemAnhHuong = false;
    if (row.Loai === 'GV_BAO_BAN') CALL(vueData.fetchAnhHuongGVBaoBan);
    else if (row.Loai === 'NGAY_NGHI') CALL(vueData.fetchAnhHuongNgayNghi);
    else if (row.Loai === 'DOI_GV') CALL(vueData.fetchAnhHuongDoiGV);
}
// Hang doi xep lai nhieu RunID lien tiep (2026-09-04) — 1 GV/1 lop co the day/thuoc nhieu khoi (moi
// khoi 1 RunID rieng cho cung 1 tuan). ApDung SP chi ghi du lieu va tra ve danh sach RunID that su
// can xep lai; o day tu xep hang doi, goi lai spAPI_TkbChayAutoPhanConLai (co san, khong doi) tuan
// tu tung RunID mot.
var tkbQueuePollTimer = null;
function tkbStartRunQueue(resp) {
    var list = resp || [];
    vueData.runQueue = list;
    vueData.runQueueDone = [];
    if (list.length === 0) {
        vueData.dangChayPhanConLai = false;
        vueData.chatLog.push({ role: 'bot', text: 'Không có tiết nào cần xếp lại (chỉ vừa cấm slot trống cho lần chạy sau).' });
        vueData.ketQuaHieu = null;
        vueData.dsAnhHuong = [];
        vueData.daXemAnhHuong = false;
        return;
    }
    vueData.dangChayPhanConLai = true;
    vueData.queueRunID = list[0].RunID;
    vueData.queueKhoi = list[0].Khoi;
    CALL(vueData.chayAutoPhanConLaiQueue);
}
function tkbStartPollQueue() {
    clearTimeout(tkbQueuePollTimer);
    tkbQueuePollTimer = setTimeout(function () {
        CALL(vueData.checkTrangThaiQueue);
    }, 3000);
}
function tkbAdvanceQueue(row) {
    vueData.runQueueDone.push({
        RunID: vueData.queueRunID,
        Khoi: vueData.queueKhoi,
        TrangThai: row.TrangThai,
        KhaThi: row.KhaThi,
        SoNhomKhongXepDuoc: row.SoNhomKhongXepDuoc
    });
    var doneIds = vueData.runQueueDone.map(function (d) { return d.RunID; });
    var next = vueData.runQueue.filter(function (r) { return doneIds.indexOf(r.RunID) === -1; });
    if (next.length === 0) {
        vueData.dangChayPhanConLai = false;
        var tongThieu = vueData.runQueueDone.reduce(function (s, d) { return s + (d.SoNhomKhongXepDuoc || 0); }, 0);
        var coLoi = vueData.runQueueDone.some(function (d) { return !d.KhaThi; });
        var dsKhoi = vueData.runQueueDone.map(function (d) { return d.Khoi; }).join(', ');
        vueData.chatLog.push({
            role: 'bot',
            text: 'Đã xếp lại khối ' + dsKhoi + (coLoi ? ' — có khối không khả thi' : '') +
                (tongThieu > 0 ? ' — còn ' + tongThieu + ' nhóm chưa xếp được' : '')
        });
        vueData.ketQuaHieu = null;
        vueData.dsAnhHuong = [];
        vueData.daXemAnhHuong = false;
    } else {
        vueData.queueRunID = next[0].RunID;
        vueData.queueKhoi = next[0].Khoi;
        CALL(vueData.chayAutoPhanConLaiQueue);
    }
}
function tkbHandleQueuePhanConLaiResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.TrangThai === 'DangChay') {
        tkbStartPollQueue();
    } else {
        tkbAdvanceQueue(row);
    }
}
function tkbHandleQueueTrangThaiResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.TrangThai === 'DangChay') {
        tkbStartPollQueue();
    } else {
        tkbAdvanceQueue(row);
    }
}