var tkbPollTimer = null;
function tkbStartPoll() {
    clearTimeout(tkbPollTimer);
    tkbPollTimer = setTimeout(function () {
        CALL(vueData.checkTrangThai);
    }, 3000);
}
function tkbFinishRun(row) {
    vueData.dangChay = false;
    vueData.ketQua = row;
    vueData.dsKhongXepDuoc = [];
    if (row.KhaThi && row.SoNhomKhongXepDuoc > 0) {
        CALL(vueData.fetchKhongXepDuoc);
    }
    CALL(vueData.fetchLichSu);
}
function tkbHandleChayAutoResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    vueData.runID = row.RunID || 0;
    vueData.ketQua = row;
    if (row.TrangThai === 'DangChay') {
        vueData.dangChay = true;
        tkbStartPoll();
    } else {
        tkbFinishRun(row);
    }
}
function tkbHandleTrangThaiResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.TrangThai === 'DangChay') {
        tkbStartPoll();
    } else {
        tkbFinishRun(row);
    }
}