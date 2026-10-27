function tkbAutoSelectRun() {
    if (!vueData.selectedRunID && vueData.dsRunKhaThi.length > 0) {
        vueData.selectedRunID = vueData.dsRunKhaThi[0].RunID;
    }
}
function tkbAutoSelectPhong() {
    if (vueData.dsPhong.length > 0 && !vueData.dsPhong.some(function (p) { return p.MaPhong === vueData.filterPhong; })) {
        vueData.filterPhong = vueData.dsPhong[0].MaPhong;
    } else if (vueData.dsPhong.length === 0) {
        vueData.filterPhong = '';
        vueData.dsLich = [];
    } else {
        CALL(vueData.fetchLich);
    }
}
function tkbHandleSuaTietResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    if (row.Success) {
        vueData.dlSua = false;
        CALL(vueData.fetchLich);
    }
}
function tkbHandleDoiTietResp(resp) {
    var row = (resp && resp[0]) ? resp[0] : {};
    vueData.doiTietID1 = null;
    if (row.Success) CALL(vueData.fetchLich);
}