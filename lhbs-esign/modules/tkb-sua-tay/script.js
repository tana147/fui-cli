function tkbAutoSelectRun() {
    if (!vueData.selectedRunID && vueData.dsRunKhaThi.length > 0) {
        vueData.selectedRunID = vueData.dsRunKhaThi[0].RunID;
    }
}
function tkbAutoSelectLop() {
    if (vueData.dsLop.length > 0 && !vueData.dsLop.some(function (l) { return l.MaLop === vueData.filterLop; })) {
        vueData.filterLop = vueData.dsLop[0].MaLop;
    } else if (vueData.dsLop.length === 0) {
        vueData.filterLop = '';
        vueData.dsLich = [];
    } else {
        CALL(vueData.fetchLich);
        CALL(vueData.fetchChecklist);
        CALL(vueData.fetchGroupSlots);
    }
}
function tkbSyncNgayApDung() {
    var run = vueData.dsRunKhaThi.find(function (r) { return r.RunID === vueData.selectedRunID; });
    vueData.formNgayApDung = run ? run.NgayApDungTu : null;
}
function tkbHandleSuaTietResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.Success) {
        vueData.dlSua = false;
        CALL(vueData.fetchLich);
        CALL(vueData.fetchChecklist);
    }
}
function tkbHandleDoiTietResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    vueData.doiTietID1 = null;
    if (row.Success) {
        CALL(vueData.fetchLich);
        CALL(vueData.fetchChecklist);
    }
}
function tkbHandleChuyenTietResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.Success) {
        CALL(vueData.fetchLich);
        CALL(vueData.fetchChecklist);
    }
}
function tkbHandleGoiYAIResp(resp) {
    vueData.goiYAILoading = false;
    var row = (resp && resp[0]) ? resp[0] : {};
    vueData.goiYAI = row.GoiY || row.Message || 'Không lấy được gợi ý, thử lại sau.';
}
function tkbHandleGoiYChuaXepResp(resp) {
    vueData.goiYChuaXepLoading = false;
    var row = (resp && resp[0]) ? resp[0] : {};
    vueData.goiYChuaXepText = row.GoiY || row.Message || 'Không lấy được gợi ý, thử lại sau.';
}
function tkbHandleGoiYChuoiResp(resp) {
    vueData.goiYChuaXepLoading = false;
    var buoiVN = { Sang: 'Sáng', Chieu: 'Chiều' };
    if (!resp || resp.length === 0) {
        vueData.goiYChuaXepText = 'Không tìm được phương án trực tiếp hoặc chuỗi 1 bước trong khung giờ hiện có.\nThử "Gợi ý AI" để phân tích sâu hơn, hoặc cân nhắc gỡ bớt 1 tiết khác của lớp/GV liên quan.';
        return;
    }
    var lines = resp.map(function (r, i) {
        if (r.LoaiGoiY === 'TRUC_TIEP') {
            return (i + 1) + '. Xếp thẳng vào Thứ ' + r.Thu + ' - ' + buoiVN[r.Buoi] + ' - Tiết ' + r.Tiet + ' (cả lớp và giáo viên đều đang rảnh).';
        }
        return (i + 1) + '. Thứ ' + r.Thu + ' - ' + buoiVN[r.Buoi] + ' - Tiết ' + r.Tiet + ' đang bị lớp ' + r.OccupantLop + ' (' + r.OccupantMon + ') chiếm.\n   Bước 1: Chuyển lớp ' + r.OccupantLop + ' sang Thứ ' + r.Thu2 + ' - ' + buoiVN[r.Buoi2] + ' - Tiết ' + r.Tiet2 + '.\n   Bước 2: Xếp vào chỗ vừa trống ra.';
    });
    vueData.goiYChuaXepText = lines.join('\n');
}
function tkbHandleApDungGoiYResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.Success) {
        vueData.dlThemTuDo = false;
        CALL(vueData.fetchLich);
        CALL(vueData.fetchChecklist);
        CALL(vueData.fetchChuaXepDuoc);
    }
}
function tkbHandleThemTuDoResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.Success) {
        vueData.dlThemTuDo = false;
        CALL(vueData.fetchLich);
        CALL(vueData.fetchChecklist);
        CALL(vueData.fetchChuaXepDuoc);
    }
}
function tkbHandleGoTietResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.Success) {
        vueData.dlSua = false;
        CALL(vueData.fetchLich);
        CALL(vueData.fetchChecklist);
        CALL(vueData.fetchChuaXepDuoc);
    }
}
function tkbHandleToggleKhoaResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.Success) {
        CALL(vueData.fetchLich);
    }
}
var tkbPhanConLaiPollTimer = null;
function tkbStartPollPhanConLai() {
    clearTimeout(tkbPhanConLaiPollTimer);
    tkbPhanConLaiPollTimer = setTimeout(function () {
        CALL(vueData.checkTrangThaiPhanConLai);
    }, 3000);
}
function tkbFinishPhanConLai(row) {
    vueData.dangChayPhanConLai = false;
    vueData.ketQuaPhanConLai = row;
    CALL(vueData.fetchLich);
    CALL(vueData.fetchChecklist);
    CALL(vueData.fetchChuaXepDuoc);
}
function tkbHandleChayAutoPhanConLaiResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.TrangThai === 'DangChay') {
        vueData.dangChayPhanConLai = true;
        tkbStartPollPhanConLai();
    } else {
        tkbFinishPhanConLai(row);
    }
}
function tkbHandleTrangThaiPhanConLaiResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.TrangThai === 'DangChay') {
        tkbStartPollPhanConLai();
    } else {
        tkbFinishPhanConLai(row);
    }
}
// Hang doi xep lai nhieu RunID lien tiep (2026-09-04) — GV bao ban / Ngay nghi gio ap dung theo
// TUAN, co the anh huong nhieu RunID (moi khoi 1 RunID rieng). ApDung SP chi ghi du lieu va tra ve
// danh sach RunID that su can xep lai; FE tu xep hang doi, goi lai spAPI_TkbChayAutoPhanConLai (da
// co san, khong doi) tuan tu tung RunID mot, tai dung dlPhanConLai/dangChayPhanConLai/ketQuaPhanConLai
// da co de khong phai lam UI moi.
var tkbQueuePollTimer = null;
function tkbStartRunQueue(resp) {
    var list = resp || [];
    vueData.runQueue = list;
    vueData.runQueueDone = [];
    if (list.length === 0) {
        vueData.dangChayPhanConLai = false;
        vueData.ketQuaPhanConLai = { TrangThai: 'Không có tiết nào cần xếp lại', KhaThi: true, SoNhomKhongXepDuoc: 0 };
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
        vueData.ketQuaPhanConLai = {
            TrangThai: 'Đã xếp lại khối ' + dsKhoi + (coLoi ? ' — có khối không khả thi' : ''),
            KhaThi: !coLoi,
            SoNhomKhongXepDuoc: tongThieu
        };
        CALL(vueData.fetchLich);
        CALL(vueData.fetchChecklist);
        CALL(vueData.fetchChuaXepDuoc);
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
function tkbHandleDoiGVHangLoatResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.Success) {
        vueData.dlSua = false;
        CALL(vueData.fetchLich);
        CALL(vueData.fetchChecklist);
    }
}