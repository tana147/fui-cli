function tkbHandleTaoTuanMoiResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.RunID) {
        vueData.runIDMoi = row.RunID;
        vueData.soTietGiuNguyen = row.SoTietGiuNguyen;
        vueData.dangChayPhanConLai = true;
        CALL(vueData.phanConLaiChuyenTuan);
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