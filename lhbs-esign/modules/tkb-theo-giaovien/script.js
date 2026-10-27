function tkbAutoSelectRun() {
    if (!vueData.selectedRunID && vueData.dsRunKhaThi.length > 0) {
        vueData.selectedRunID = vueData.dsRunKhaThi[0].RunID;
    }
}
function tkbAutoSelectGV() {
    if (vueData.dsGV.length > 0 && !vueData.dsGV.some(function (g) { return g.MaGV === vueData.filterGV; })) {
        vueData.filterGV = vueData.dsGV[0].MaGV;
    } else if (vueData.dsGV.length === 0) {
        vueData.filterGV = '';
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